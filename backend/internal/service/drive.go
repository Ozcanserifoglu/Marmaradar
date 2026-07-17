package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxDrivePoints = 50000

var (
	ErrTooFewPoints  = errors.New("at least 2 points required")
	ErrTooManyPoints = errors.New("too many points")
	ErrInvalidDrive  = errors.New("invalid drive payload")
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
