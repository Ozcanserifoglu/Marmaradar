package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrInvalidLiveReport = errors.New("invalid live report")

type CreateLiveReportInput struct {
	Lat        float64 `json:"lat"`
	Lng        float64 `json:"lng"`
	ReportType string  `json:"report_type"`
}

type LiveReport struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	Lat        float64   `json:"lat"`
	Lng        float64   `json:"lng"`
	ReportType string    `json:"report_type"`
	CreatedAt  time.Time `json:"created_at"`
}

type LiveReportService struct {
	pool *pgxpool.Pool
}

func NewLiveReportService(pool *pgxpool.Pool) *LiveReportService {
	return &LiveReportService{pool: pool}
}

func (s *LiveReportService) Create(ctx context.Context, userID uuid.UUID, in CreateLiveReportInput) (*LiveReport, error) {
	reportType, err := normalizeLiveReportType(in.ReportType)
	if err != nil {
		return nil, err
	}
	if in.Lat < -90 || in.Lat > 90 || in.Lng < -180 || in.Lng > 180 {
		return nil, ErrInvalidLiveReport
	}

	var (
		id        uuid.UUID
		createdAt time.Time
	)
	err = s.pool.QueryRow(ctx, `
		INSERT INTO user_reports (user_id, lat, lng, report_type)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`, userID, in.Lat, in.Lng, reportType).Scan(&id, &createdAt)
	if err != nil {
		return nil, fmt.Errorf("insert user_report: %w", err)
	}

	return &LiveReport{
		ID:         id.String(),
		UserID:     userID.String(),
		Lat:        in.Lat,
		Lng:        in.Lng,
		ReportType: reportType,
		CreatedAt:  createdAt,
	}, nil
}

func (s *LiveReportService) ListActive(ctx context.Context) ([]LiveReport, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, user_id, lat, lng, report_type, created_at
		FROM user_reports
		WHERE created_at >= NOW() - INTERVAL '2 hours'
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("list active user_reports: %w", err)
	}
	defer rows.Close()

	reports := make([]LiveReport, 0)
	for rows.Next() {
		var (
			id     uuid.UUID
			userID uuid.UUID
			report LiveReport
		)
		if err := rows.Scan(&id, &userID, &report.Lat, &report.Lng, &report.ReportType, &report.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan user_report: %w", err)
		}
		report.ID = id.String()
		report.UserID = userID.String()
		reports = append(reports, report)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate user_reports: %w", err)
	}
	return reports, nil
}

func normalizeLiveReportType(raw string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "police", "accident":
		return strings.ToLower(strings.TrimSpace(raw)), nil
	default:
		return "", ErrInvalidLiveReport
	}
}
