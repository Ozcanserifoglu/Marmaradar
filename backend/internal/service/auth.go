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
	"github.com/radar-alert/backend/internal/email"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrInvalidRefresh     = errors.New("invalid or expired refresh token")
	ErrInvalidOAuthToken  = errors.New("invalid oauth identity token")
	ErrOAuthNotConfigured = errors.New("oauth provider is not configured")
	ErrInvalidResetToken  = errors.New("invalid or expired reset token")
)

const (
	ProviderGoogle = "google"
	ProviderApple  = "apple"

	passwordResetTTL      = time.Hour
	passwordResetCooldown = 5 * time.Minute
)

type AuthService struct {
	pool       *pgxpool.Pool
	jwt        *auth.JWTManager
	google     *auth.GoogleIDTokenVerifier
	apple      *auth.AppleIDTokenVerifier
	mailer     *email.Mailer
	appBaseURL string
}

func NewAuthService(
	pool *pgxpool.Pool,
	jwt *auth.JWTManager,
	googleAudiences, appleAudiences []string,
	mailer *email.Mailer,
	appBaseURL string,
) *AuthService {
	return &AuthService{
		pool:       pool,
		jwt:        jwt,
		google:     auth.NewGoogleIDTokenVerifier(googleAudiences),
		apple:      auth.NewAppleIDTokenVerifier(appleAudiences),
		mailer:     mailer,
		appBaseURL: strings.TrimSpace(appBaseURL),
	}
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

	s.enqueueWelcome(email)
	return s.issueTokens(ctx, userID, email)
}

func (s *AuthService) Login(ctx context.Context, email, password string) (*AuthResult, error) {
	email = normalizeEmail(email)
	if email == "" || password == "" {
		return nil, ErrInvalidCredentials
	}

	var userID uuid.UUID
	var passwordHash *string
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

	if passwordHash == nil || *passwordHash == "" {
		return nil, ErrInvalidCredentials
	}
	if err := bcrypt.CompareHashAndPassword([]byte(*passwordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	return s.issueTokens(ctx, userID, email)
}

// OAuthLogin verifies a Google/Apple ID token and find-or-creates the user.
func (s *AuthService) OAuthLogin(ctx context.Context, provider, idToken, nonce string) (*AuthResult, error) {
	provider = strings.ToLower(strings.TrimSpace(provider))
	var (
		claims *auth.IdentityClaims
		err    error
	)
	switch provider {
	case ProviderGoogle:
		if len(s.googleAudiences()) == 0 {
			return nil, ErrOAuthNotConfigured
		}
		claims, err = s.google.Verify(idToken)
	case ProviderApple:
		if len(s.appleAudiences()) == 0 {
			return nil, ErrOAuthNotConfigured
		}
		claims, err = s.apple.Verify(idToken, nonce)
	default:
		return nil, fmt.Errorf("%w: unsupported provider", ErrInvalidOAuthToken)
	}
	if err != nil {
		if errors.Is(err, auth.ErrInvalidIDToken) {
			return nil, ErrInvalidOAuthToken
		}
		return nil, err
	}
	if claims == nil || claims.Subject == "" {
		return nil, ErrInvalidOAuthToken
	}

	userID, email, created, err := s.findOrCreateOAuthUser(ctx, provider, claims)
	if err != nil {
		return nil, err
	}
	if created {
		s.enqueueWelcome(email)
	}
	return s.issueTokens(ctx, userID, email)
}

func (s *AuthService) googleAudiences() []string {
	if s.google == nil {
		return nil
	}
	return s.google.Audiences()
}

func (s *AuthService) appleAudiences() []string {
	if s.apple == nil {
		return nil
	}
	return s.apple.Audiences()
}

func (s *AuthService) findOrCreateOAuthUser(
	ctx context.Context,
	provider string,
	claims *auth.IdentityClaims,
) (uuid.UUID, string, bool, error) {
	var userID uuid.UUID
	var email string
	err := s.pool.QueryRow(ctx, `
		SELECT u.id, u.email
		FROM auth_identities ai
		JOIN users u ON u.id = ai.user_id
		WHERE ai.provider = $1 AND ai.provider_subject = $2
	`, provider, claims.Subject).Scan(&userID, &email)
	if err == nil {
		return userID, email, false, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, "", false, fmt.Errorf("lookup identity: %w", err)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return uuid.Nil, "", false, fmt.Errorf("begin oauth tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Race-safe re-check inside the transaction.
	err = tx.QueryRow(ctx, `
		SELECT u.id, u.email
		FROM auth_identities ai
		JOIN users u ON u.id = ai.user_id
		WHERE ai.provider = $1 AND ai.provider_subject = $2
	`, provider, claims.Subject).Scan(&userID, &email)
	if err == nil {
		if err := tx.Commit(ctx); err != nil {
			return uuid.Nil, "", false, err
		}
		return userID, email, false, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, "", false, fmt.Errorf("lookup identity tx: %w", err)
	}

	linkEmail := ""
	if claims.EmailVerified && claims.Email != "" {
		linkEmail = normalizeEmail(claims.Email)
		err = tx.QueryRow(ctx, `SELECT id, email FROM users WHERE email = $1`, linkEmail).
			Scan(&userID, &email)
		if err == nil {
			if err := s.insertIdentity(ctx, tx, userID, provider, claims.Subject, linkEmail); err != nil {
				return uuid.Nil, "", false, err
			}
			if err := tx.Commit(ctx); err != nil {
				return uuid.Nil, "", false, err
			}
			return userID, email, false, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return uuid.Nil, "", false, fmt.Errorf("lookup user by email: %w", err)
		}
	}

	email = linkEmail
	if email == "" {
		email = syntheticOAuthEmail(provider, claims.Subject)
	}

	created := true
	err = tx.QueryRow(ctx, `
		INSERT INTO users (email, password_hash) VALUES ($1, NULL) RETURNING id
	`, email).Scan(&userID)
	if err != nil {
		if isUniqueViolation(err) {
			// Email taken between lookup and insert — attach to existing user.
			err = tx.QueryRow(ctx, `SELECT id, email FROM users WHERE email = $1`, email).
				Scan(&userID, &email)
			if err != nil {
				return uuid.Nil, "", false, fmt.Errorf("resolve email race: %w", err)
			}
			created = false
		} else {
			return uuid.Nil, "", false, fmt.Errorf("insert oauth user: %w", err)
		}
	}

	if err := s.insertIdentity(ctx, tx, userID, provider, claims.Subject, claims.Email); err != nil {
		return uuid.Nil, "", false, err
	}
	if err := tx.Commit(ctx); err != nil {
		return uuid.Nil, "", false, err
	}
	return userID, email, created, nil
}

func (s *AuthService) insertIdentity(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	provider, subject, emailAtLink string,
) error {
	emailAtLink = normalizeEmail(emailAtLink)
	var emailArg any
	if emailAtLink != "" {
		emailArg = emailAtLink
	}
	_, err := tx.Exec(ctx, `
		INSERT INTO auth_identities (user_id, provider, provider_subject, email_at_link)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (provider, provider_subject) DO NOTHING
	`, userID, provider, subject, emailArg)
	if err != nil {
		return fmt.Errorf("insert identity: %w", err)
	}
	return nil
}

func syntheticOAuthEmail(provider, subject string) string {
	sum := sha256.Sum256([]byte(provider + ":" + subject))
	return fmt.Sprintf("%s.%s@oauth.local", provider, hex.EncodeToString(sum[:12]))
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

func (s *AuthService) ForgotPassword(ctx context.Context, rawEmail string) error {
	address := normalizeEmail(rawEmail)
	if !email.Deliverable(address) {
		return nil
	}

	var userID uuid.UUID
	err := s.pool.QueryRow(ctx, `SELECT id FROM users WHERE email = $1`, address).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		return fmt.Errorf("lookup user for reset: %w", err)
	}

	var recent time.Time
	err = s.pool.QueryRow(ctx, `
		SELECT created_at FROM password_reset_tokens
		WHERE user_id = $1 AND created_at > $2
		ORDER BY created_at DESC
		LIMIT 1
	`, userID, time.Now().Add(-passwordResetCooldown)).Scan(&recent)
	if err == nil {
		return nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("lookup reset cooldown: %w", err)
	}

	plain, err := auth.NewRefreshToken()
	if err != nil {
		return fmt.Errorf("generate reset token: %w", err)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin reset tx: %w", err)
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		UPDATE password_reset_tokens
		SET used_at = now()
		WHERE user_id = $1 AND used_at IS NULL
	`, userID)
	if err != nil {
		return fmt.Errorf("invalidate prior reset tokens: %w", err)
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, hashToken(plain), time.Now().Add(passwordResetTTL))
	if err != nil {
		return fmt.Errorf("store reset token: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return err
	}

	if s.mailer != nil {
		s.mailer.EnqueuePasswordReset(address, email.ResetPasswordURL(s.appBaseURL, plain))
	}
	return nil
}

func (s *AuthService) ResetPassword(ctx context.Context, token, password string) error {
	token = strings.TrimSpace(token)
	if token == "" {
		return ErrInvalidResetToken
	}
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("hash password: %w", err)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin password reset: %w", err)
	}
	defer tx.Rollback(ctx)

	var tokenID uuid.UUID
	var userID uuid.UUID
	err = tx.QueryRow(ctx, `
		SELECT id, user_id FROM password_reset_tokens
		WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now()
		FOR UPDATE
	`, hashToken(token)).Scan(&tokenID, &userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrInvalidResetToken
		}
		return fmt.Errorf("lookup reset token: %w", err)
	}

	_, err = tx.Exec(ctx, `UPDATE users SET password_hash = $1 WHERE id = $2`, string(hash), userID)
	if err != nil {
		return fmt.Errorf("update password: %w", err)
	}
	_, err = tx.Exec(ctx, `UPDATE password_reset_tokens SET used_at = now() WHERE id = $1`, tokenID)
	if err != nil {
		return fmt.Errorf("consume reset token: %w", err)
	}
	_, err = tx.Exec(ctx, `DELETE FROM refresh_tokens WHERE user_id = $1`, userID)
	if err != nil {
		return fmt.Errorf("revoke refresh tokens: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return err
	}
	return nil
}

func (s *AuthService) enqueueWelcome(address string) {
	if s.mailer == nil {
		return
	}
	s.mailer.EnqueueWelcome(address)
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
