package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/backend/internal/auth"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrEmailTaken        = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrInvalidRefresh    = errors.New("invalid or expired refresh token")
)

type AuthService struct {
	pool *pgxpool.Pool
	jwt  *auth.JWTManager
}

func NewAuthService(pool *pgxpool.Pool, jwt *auth.JWTManager) *AuthService {
	return &AuthService{pool: pool, jwt: jwt}
}

type UserInfo struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

type AuthResult struct {
	AccessToken  string   `json:"access_token"`
	RefreshToken string   `json:"refresh_token"`
	ExpiresIn    int      `json:"expires_in"`
	User         UserInfo `json:"user"`
}

func (s *AuthService) Register(ctx context.Context, email, password string) (*AuthResult, error) {
	email = normalizeEmail(email)
	if err := validateCredentials(email, password); err != nil {
		return nil, err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	var userID uuid.UUID
	err = s.pool.QueryRow(ctx,
		`INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id`,
		email, string(hash),
	).Scan(&userID)
	if err != nil {
		if isUniqueViolation(err) {
			return nil, ErrEmailTaken
		}
		return nil, fmt.Errorf("insert user: %w", err)
	}

	return s.issueTokens(ctx, userID, email)
}

func (s *AuthService) Login(ctx context.Context, email, password string) (*AuthResult, error) {
	email = normalizeEmail(email)
	if email == "" || password == "" {
		return nil, ErrInvalidCredentials
	}

	var userID uuid.UUID
	var passwordHash string
	err := s.pool.QueryRow(ctx,
		`SELECT id, password_hash FROM users WHERE email = $1`,
		email,
	).Scan(&userID, &passwordHash)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("lookup user: %w", err)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	return s.issueTokens(ctx, userID, email)
}

func (s *AuthService) Refresh(ctx context.Context, refreshToken string) (*AuthResult, error) {
	refreshToken = strings.TrimSpace(refreshToken)
	if refreshToken == "" {
		return nil, ErrInvalidRefresh
	}

	hash := hashToken(refreshToken)
	var userID uuid.UUID
	var email string
	var tokenID uuid.UUID
	err := s.pool.QueryRow(ctx, `
		SELECT rt.id, rt.user_id, u.email
		FROM refresh_tokens rt
		JOIN users u ON u.id = rt.user_id
		WHERE rt.token_hash = $1 AND rt.expires_at > now()
	`, hash).Scan(&tokenID, &userID, &email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrInvalidRefresh
		}
		return nil, fmt.Errorf("lookup refresh token: %w", err)
	}

	_, _ = s.pool.Exec(ctx, `DELETE FROM refresh_tokens WHERE id = $1`, tokenID)

	return s.issueTokens(ctx, userID, email)
}

func (s *AuthService) issueTokens(ctx context.Context, userID uuid.UUID, email string) (*AuthResult, error) {
	access, expiresIn, err := s.jwt.IssueAccessToken(userID, email)
	if err != nil {
		return nil, err
	}

	refreshPlain, err := auth.NewRefreshToken()
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}

	expiresAt := time.Now().Add(s.jwt.RefreshTTL())
	_, err = s.pool.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, hashToken(refreshPlain), expiresAt)
	if err != nil {
		return nil, fmt.Errorf("store refresh token: %w", err)
	}

	return &AuthResult{
		AccessToken:  access,
		RefreshToken: refreshPlain,
		ExpiresIn:    expiresIn,
		User: UserInfo{
			ID:    userID.String(),
			Email: email,
		},
	}, nil
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func validateCredentials(email, password string) error {
	if email == "" || !strings.Contains(email, "@") {
		return errors.New("valid email is required")
	}
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters")
	}
	return nil
}

func hashToken(plain string) string {
	sum := sha256.Sum256([]byte(plain))
	return hex.EncodeToString(sum[:])
}

func isUniqueViolation(err error) bool {
	return strings.Contains(err.Error(), "23505") ||
		strings.Contains(err.Error(), "unique") ||
		strings.Contains(err.Error(), "duplicate")
}
