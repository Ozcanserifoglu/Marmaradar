package service

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

const (
	AchievementFirstDrive      = "first_drive"
	AchievementClub100km       = "club_100km"
	AchievementNightRider      = "night_rider"
	AchievementSafeDriver      = "safe_driver"
	AchievementRadarScout      = "radar_scout"
	AchievementFirstReport     = "first_report"
	AchievementCommunityHelper = "community_helper"
	AchievementRadarReporter   = "radar_reporter"
	AchievementCrowdGuardian   = "crowd_guardian"
	AchievementNightOwl        = "night_owl"
	AchievementFirstResponder  = "first_responder"
)

const safeSpeedMpsMax = 36.111 // 130 km/h

type Achievement struct {
	Code       string    `json:"code"`
	UnlockedAt time.Time `json:"unlocked_at"`
}

type userStatsRow struct {
	TotalDistanceM         float64
	TotalDriveTimeSec      int64
	TotalDrives            int
	RadarsEncountered      int
	NightDrives            int
	SafeDrives             int
	ReportsSubmitted       int
	ConfirmationsGiven     int
	DriversSaved           int
	FakeReports            int
	LiveReportsSubmitted   int
	LiveConfirmationsGiven int
	LiveDriversSaved       int
	NightReportsSubmitted  int
	UpdatedAt              time.Time
}

func isNightDrive(startedAt time.Time) bool {
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		loc = time.FixedZone("TRT", 3*3600)
	}
	h := startedAt.In(loc).Hour()
	return h >= 22 || h < 5
}

func isSafeDrive(points []DrivePoint) bool {
	for _, p := range points {
		if p.SpeedMps > safeSpeedMpsMax {
			return false
		}
	}
	return true
}

func evaluateAchievements(ctx context.Context, tx pgx.Tx, userID uuid.UUID, stats userStatsRow) error {
	candidates := make([]string, 0, 11)
	if stats.TotalDrives >= 1 {
		candidates = append(candidates, AchievementFirstDrive)
	}
	if stats.TotalDistanceM >= 100_000 {
		candidates = append(candidates, AchievementClub100km)
	}
	if stats.NightDrives >= 5 {
		candidates = append(candidates, AchievementNightRider)
	}
	if stats.SafeDrives >= 10 {
		candidates = append(candidates, AchievementSafeDriver)
	}
	if stats.RadarsEncountered >= 25 {
		candidates = append(candidates, AchievementRadarScout)
	}
	if stats.ReportsSubmitted >= 1 {
		candidates = append(candidates, AchievementFirstReport)
	}
	if stats.ConfirmationsGiven >= 10 {
		candidates = append(candidates, AchievementCommunityHelper)
	}
	if stats.ReportsSubmitted >= 10 {
		candidates = append(candidates, AchievementRadarReporter)
	}
	if stats.DriversSaved >= 25 {
		candidates = append(candidates, AchievementCrowdGuardian)
	}
	if stats.NightReportsSubmitted >= 5 {
		candidates = append(candidates, AchievementNightOwl)
	}
	for _, code := range candidates {
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_achievements (user_id, code)
			VALUES ($1, $2)
			ON CONFLICT DO NOTHING
		`, userID, code); err != nil {
			return fmt.Errorf("unlock achievement %s: %w", code, err)
		}
	}
	return nil
}

func unlockAchievement(ctx context.Context, tx pgx.Tx, userID uuid.UUID, code string) error {
	if _, err := tx.Exec(ctx, `
		INSERT INTO user_achievements (user_id, code)
		VALUES ($1, $2)
		ON CONFLICT DO NOTHING
	`, userID, code); err != nil {
		return fmt.Errorf("unlock achievement %s: %w", code, err)
	}
	return nil
}

func listAchievements(ctx context.Context, tx pgx.Tx, userID uuid.UUID) ([]Achievement, error) {
	rows, err := tx.Query(ctx, `
		SELECT code, unlocked_at
		FROM user_achievements
		WHERE user_id = $1
		ORDER BY unlocked_at ASC
	`, userID)
	if err != nil {
		return nil, fmt.Errorf("list achievements: %w", err)
	}
	defer rows.Close()

	out := make([]Achievement, 0)
	for rows.Next() {
		var a Achievement
		if err := rows.Scan(&a.Code, &a.UnlockedAt); err != nil {
			return nil, fmt.Errorf("scan achievement: %w", err)
		}
		out = append(out, a)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate achievements: %w", err)
	}
	return out, nil
}
