package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxDrivePoints = 50000

var (
	ErrTooFewPoints  = errors.New("at least 2 points required")
	ErrTooManyPoints = errors.New("too many points")
	ErrInvalidDrive  = errors.New("invalid drive payload")
	ErrDriveNotFound = errors.New("drive not found")
	ErrInvalidName   = errors.New("invalid drive name")
)

type DrivePoint struct {
	Lat        float64   `json:"lat"`
	Lon        float64   `json:"lon"`
	SpeedMps   float64   `json:"speed_mps"`
	RecordedAt time.Time `json:"recorded_at"`
}

type CreateDriveInput struct {
	StartedAt time.Time    `json:"started_at"`
	EndedAt   time.Time    `json:"ended_at"`
	Points    []DrivePoint `json:"points"`
}

type DriveResult struct {
	ID         string  `json:"id"`
	LengthM    float64 `json:"length_m"`
	PointCount int     `json:"point_count"`
}

type DriveSummary struct {
	ID         string    `json:"id"`
	Name       *string   `json:"name"`
	StartedAt  time.Time `json:"started_at"`
	EndedAt    time.Time `json:"ended_at"`
	LengthM    float64   `json:"length_m"`
	PointCount int       `json:"point_count"`
}

type DriveDetail struct {
	DriveSummary
	Points []DrivePoint `json:"points"`
}

type DriveService struct {
	pool *pgxpool.Pool
}

func NewDriveService(pool *pgxpool.Pool) *DriveService {
	return &DriveService{pool: pool}
}

func (s *DriveService) Create(ctx context.Context, userID uuid.UUID, in CreateDriveInput) (*DriveResult, error) {
	if err := validateDrive(in); err != nil {
		return nil, err
	}

	wkt, err := buildLineStringWKT(in.Points)
	if err != nil {
		return nil, err
	}

	pointsJSON, err := json.Marshal(in.Points)
	if err != nil {
		return nil, fmt.Errorf("marshal points: %w", err)
	}

	var (
		id      uuid.UUID
		lengthM float64
	)
	err = s.pool.QueryRow(ctx, `
		INSERT INTO drives (user_id, path, points, started_at, ended_at, length_m, point_count)
		VALUES (
			$1,
			ST_GeogFromText($2),
			$3::jsonb,
			$4,
			$5,
			ST_Length(ST_GeogFromText($2)),
			$6
		)
		RETURNING id, length_m
	`, userID, wkt, string(pointsJSON), in.StartedAt, in.EndedAt, len(in.Points)).Scan(&id, &lengthM)
	if err != nil {
		return nil, fmt.Errorf("insert drive: %w", err)
	}

	return &DriveResult{
		ID:         id.String(),
		LengthM:    lengthM,
		PointCount: len(in.Points),
	}, nil
}

func (s *DriveService) List(ctx context.Context, userID uuid.UUID) ([]DriveSummary, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, name, started_at, ended_at, length_m, point_count
		FROM drives
		WHERE user_id = $1
		ORDER BY started_at DESC
		LIMIT 100
	`, userID)
	if err != nil {
		return nil, fmt.Errorf("list drives: %w", err)
	}
	defer rows.Close()

	drives := make([]DriveSummary, 0)
	for rows.Next() {
		var (
			id      uuid.UUID
			summary DriveSummary
		)
		if err := rows.Scan(&id, &summary.Name, &summary.StartedAt, &summary.EndedAt, &summary.LengthM, &summary.PointCount); err != nil {
			return nil, fmt.Errorf("scan drive: %w", err)
		}
		summary.ID = id.String()
		drives = append(drives, summary)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate drives: %w", err)
	}
	return drives, nil
}

func (s *DriveService) Get(ctx context.Context, userID uuid.UUID, driveID string) (*DriveDetail, error) {
	id, err := uuid.Parse(driveID)
	if err != nil {
		return nil, ErrDriveNotFound
	}

	var (
		detail     DriveDetail
		rowID      uuid.UUID
		pointsJSON []byte
	)
	err = s.pool.QueryRow(ctx, `
		SELECT id, name, started_at, ended_at, length_m, point_count, points
		FROM drives
		WHERE id = $1 AND user_id = $2
	`, id, userID).Scan(
		&rowID,
		&detail.Name,
		&detail.StartedAt,
		&detail.EndedAt,
		&detail.LengthM,
		&detail.PointCount,
		&pointsJSON,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrDriveNotFound
		}
		return nil, fmt.Errorf("get drive: %w", err)
	}
	detail.ID = rowID.String()

	if len(pointsJSON) > 0 {
		if err := json.Unmarshal(pointsJSON, &detail.Points); err != nil {
			return nil, fmt.Errorf("unmarshal points: %w", err)
		}
	}
	if detail.Points == nil {
		detail.Points = make([]DrivePoint, 0)
	}
	return &detail, nil
}

const maxDriveNameLen = 120

// Rename sets (or clears, when blank) the display name of a user's drive.
func (s *DriveService) Rename(ctx context.Context, userID uuid.UUID, driveID, name string) error {
	id, err := uuid.Parse(driveID)
	if err != nil {
		return ErrDriveNotFound
	}

	trimmed := strings.TrimSpace(name)
	if len([]rune(trimmed)) > maxDriveNameLen {
		return ErrInvalidName
	}

	var namePtr *string
	if trimmed != "" {
		namePtr = &trimmed
	}

	tag, err := s.pool.Exec(ctx, `
		UPDATE drives SET name = $1 WHERE id = $2 AND user_id = $3
	`, namePtr, id, userID)
	if err != nil {
		return fmt.Errorf("rename drive: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrDriveNotFound
	}
	return nil
}

func validateDrive(in CreateDriveInput) error {
	if len(in.Points) < 2 {
		return ErrTooFewPoints
	}
	if len(in.Points) > maxDrivePoints {
		return ErrTooManyPoints
	}
	if in.StartedAt.IsZero() || in.EndedAt.IsZero() {
		return ErrInvalidDrive
	}
	if in.EndedAt.Before(in.StartedAt) {
		return errors.New("ended_at must be >= started_at")
	}
	for i, p := range in.Points {
		if p.Lat < -90 || p.Lat > 90 || p.Lon < -180 || p.Lon > 180 {
			return fmt.Errorf("invalid coordinates at point %d", i)
		}
	}
	return nil
}

func buildLineStringWKT(points []DrivePoint) (string, error) {
	var b strings.Builder
	b.WriteString("LINESTRING(")
	for i, p := range points {
		if i > 0 {
			b.WriteByte(',')
		}
		fmt.Fprintf(&b, "%g %g", p.Lon, p.Lat)
	}
	b.WriteByte(')')
	return b.String(), nil
}
