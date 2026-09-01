package service

import (
	"context"
	"errors"
	"fmt"
	"io"
	"path"
	"regexp"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/backend/internal/storage"
)

var (
	ErrInvalidVehicleType  = errors.New("invalid vehicle_type")
	ErrInvalidVehicleColor = errors.New("invalid vehicle_color")
	ErrInvalidImageType    = errors.New("unsupported image type")
	ErrImageTooLarge       = errors.New("image too large")
	ErrUserNotFound        = errors.New("user not found")
)

var allowedVehicleTypes = map[string]struct{}{
	"sedan":         {},
	"hatchback":     {},
	"station_wagon": {},
	"kamyon":        {},
	"tir":           {},
}

var hexColorRe = regexp.MustCompile(`(?i)^#[0-9A-F]{6}$`)

const MaxProfilePictureBytes = 2 << 20 // 2 MiB

type UserProfile struct {
	ID                string  `json:"id"`
	Email             string  `json:"email"`
	ProfilePictureURL *string `json:"profile_picture_url"`
	VehicleType       string  `json:"vehicle_type"`
	VehicleColor      string  `json:"vehicle_color"`
}

type UpdatePreferencesInput struct {
	VehicleType  *string `json:"vehicle_type"`
	VehicleColor *string `json:"vehicle_color"`
}

type UsersService struct {
	pool    *pgxpool.Pool
	storage storage.ObjectStorage
}

func NewUsersService(pool *pgxpool.Pool, store storage.ObjectStorage) *UsersService {
	return &UsersService{pool: pool, storage: store}
}

func (s *UsersService) GetProfile(ctx context.Context, userID uuid.UUID) (*UserProfile, error) {
	var p UserProfile
	err := s.pool.QueryRow(ctx, `
		SELECT id::text, email, profile_picture_url, vehicle_type, vehicle_color
		FROM users
		WHERE id = $1
	`, userID).Scan(&p.ID, &p.Email, &p.ProfilePictureURL, &p.VehicleType, &p.VehicleColor)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (s *UsersService) UpdatePreferences(ctx context.Context, userID uuid.UUID, in UpdatePreferencesInput) (*UserProfile, error) {
	if in.VehicleType == nil && in.VehicleColor == nil {
		return s.GetProfile(ctx, userID)
	}

	vehicleType := ""
	vehicleColor := ""
	if in.VehicleType != nil {
		vehicleType = strings.TrimSpace(*in.VehicleType)
		if _, ok := allowedVehicleTypes[vehicleType]; !ok {
			return nil, ErrInvalidVehicleType
		}
	}
	if in.VehicleColor != nil {
		vehicleColor = strings.ToUpper(strings.TrimSpace(*in.VehicleColor))
		if !hexColorRe.MatchString(vehicleColor) {
			return nil, ErrInvalidVehicleColor
		}
	}

	_, err := s.pool.Exec(ctx, `
		UPDATE users SET
			vehicle_type = COALESCE(NULLIF($2, ''), vehicle_type),
			vehicle_color = COALESCE(NULLIF($3, ''), vehicle_color)
		WHERE id = $1
	`, userID, vehicleType, vehicleColor)
	if err != nil {
		return nil, err
	}
	return s.GetProfile(ctx, userID)
}

func (s *UsersService) SaveProfilePicture(
	ctx context.Context,
	userID uuid.UUID,
	r io.Reader,
	contentType string,
	size int64,
) (*UserProfile, error) {
	if size > MaxProfilePictureBytes {
		return nil, ErrImageTooLarge
	}

	ext, normalizedType, err := normalizeImageType(contentType)
	if err != nil {
		return nil, err
	}

	limited := &io.LimitedReader{R: r, N: MaxProfilePictureBytes + 1}
	key := fmt.Sprintf("avatars/%s.%s", userID.String(), ext)
	if err := s.storage.Put(ctx, key, limited, normalizedType); err != nil {
		return nil, err
	}
	if limited.N == 0 {
		_ = s.storage.Delete(ctx, key)
		return nil, ErrImageTooLarge
	}

	publicURL := "/v1/uploads/" + key
	prev, _ := s.GetProfile(ctx, userID)
	_, err = s.pool.Exec(ctx, `
		UPDATE users SET profile_picture_url = $2 WHERE id = $1
	`, userID, publicURL)
	if err != nil {
		return nil, err
	}

	if prev != nil && prev.ProfilePictureURL != nil {
		oldKey := keyFromPublicURL(*prev.ProfilePictureURL)
		if oldKey != "" && oldKey != key {
			_ = s.storage.Delete(ctx, oldKey)
		}
	}

	return s.GetProfile(ctx, userID)
}

func (s *UsersService) OpenUpload(ctx context.Context, key string) (io.ReadCloser, string, error) {
	return s.storage.Open(ctx, key)
}

func normalizeImageType(contentType string) (ext string, normalized string, err error) {
	ct := strings.ToLower(strings.TrimSpace(contentType))
	if i := strings.Index(ct, ";"); i >= 0 {
		ct = strings.TrimSpace(ct[:i])
	}
	switch ct {
	case "image/jpeg", "image/jpg":
		return "jpg", "image/jpeg", nil
	case "image/png":
		return "png", "image/png", nil
	case "image/webp":
		return "webp", "image/webp", nil
	default:
		return "", "", ErrInvalidImageType
	}
}

func keyFromPublicURL(url string) string {
	url = strings.TrimSpace(url)
	const prefix = "/v1/uploads/"
	if strings.HasPrefix(url, prefix) {
		return path.Clean(strings.TrimPrefix(url, prefix))
	}
	return ""
}
