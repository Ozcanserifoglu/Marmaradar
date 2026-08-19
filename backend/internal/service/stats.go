package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const radarEncounterRadiusM = 150.0

type UserStats struct {
	TotalDistanceM         float64       `json:"total_distance_m"`
	TotalDriveTimeSec      int64         `json:"total_drive_time_sec"`
	TotalDrives            int           `json:"total_drives"`
	RadarsEncountered      int           `json:"radars_encountered"`
	ReportsSubmitted       int           `json:"reports_submitted"`
	ConfirmationsGiven     int           `json:"confirmations_given"`
	DriversSaved           int           `json:"drivers_saved"`
	LiveReportsSubmitted   int           `json:"live_reports_submitted"`
	LiveConfirmationsGiven int           `json:"live_confirmations_given"`
	LiveDriversSaved       int           `json:"live_drivers_saved"`
	NightReportsSubmitted  int           `json:"night_reports_submitted"`
	RankCode               string        `json:"rank_code"`
	RankTitle              string        `json:"rank_title"`
	XP                     int64         `json:"xp"`
	XPToNextRank           int64         `json:"xp_to_next_rank"`
	EloRating              float64       `json:"elo_rating"`
	DriveStreak            UserStreak    `json:"drive_streak"`
	Achievements           []Achievement `json:"achievements"`
	UpdatedAt              time.Time     `json:"updated_at"`
}

type StatsService struct {
	pool *pgxpool.Pool
}

func NewStatsService(pool *pgxpool.Pool) *StatsService {
	return &StatsService{pool: pool}
}

func (s *StatsService) GetMe(ctx context.Context, userID uuid.UUID) (*UserStats, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin stats tx: %w", err)
	}
	defer tx.Rollback(ctx)

	stats, err := ensureUserStats(ctx, tx, userID)
	if err != nil {
		return nil, err
	}
	reputation, err := ensureUserReputation(ctx, tx, userID)
	if err != nil {
		return nil, err
	}
	streak, err := loadUserStreak(ctx, tx, userID, driveStreakType)
	if err != nil {
		return nil, err
	}
	if err := evaluateAchievements(ctx, tx, userID, stats); err != nil {
		return nil, err
	}
	achievements, err := listAchievements(ctx, tx, userID)
	if err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit stats tx: %w", err)
	}
	if achievements == nil {
		achievements = make([]Achievement, 0)
	}

	nextRank := nextRankForXP(reputation.XP)
	var xpToNext int64
	if nextRank != nil {
		xpToNext = nextRank.MinXP - reputation.XP
		if xpToNext < 0 {
			xpToNext = 0
		}
	}

	return &UserStats{
		TotalDistanceM:         stats.TotalDistanceM,
		TotalDriveTimeSec:      stats.TotalDriveTimeSec,
		TotalDrives:            stats.TotalDrives,
		RadarsEncountered:      stats.RadarsEncountered,
		ReportsSubmitted:       stats.ReportsSubmitted,
		ConfirmationsGiven:     stats.ConfirmationsGiven,
		DriversSaved:           stats.DriversSaved,
		LiveReportsSubmitted:   stats.LiveReportsSubmitted,
		LiveConfirmationsGiven: stats.LiveConfirmationsGiven,
		LiveDriversSaved:       stats.LiveDriversSaved,
		NightReportsSubmitted:  stats.NightReportsSubmitted,
		RankCode:               reputation.RankCode,
		RankTitle:              reputation.RankTitle,
		XP:                     reputation.XP,
		XPToNextRank:           xpToNext,
		EloRating:              reputation.ELORating,
		DriveStreak:            streak,
		Achievements:           achievements,
		UpdatedAt:              stats.UpdatedAt,
	}, nil
}

func ensureUserStats(ctx context.Context, tx pgx.Tx, userID uuid.UUID) (userStatsRow, error) {
	var row userStatsRow
	err := tx.QueryRow(ctx, `
		SELECT total_distance_m, total_drive_time_sec, total_drives,
		       radars_encountered, night_drives, safe_drives,
		       reports_submitted, confirmations_given, drivers_saved, fake_reports,
		       live_reports_submitted, live_confirmations_given, live_drivers_saved,
		       night_reports_submitted,
		       updated_at
		FROM user_stats
		WHERE user_id = $1
	`, userID).Scan(
		&row.TotalDistanceM,
		&row.TotalDriveTimeSec,
		&row.TotalDrives,
		&row.RadarsEncountered,
		&row.NightDrives,
		&row.SafeDrives,
		&row.ReportsSubmitted,
		&row.ConfirmationsGiven,
		&row.DriversSaved,
		&row.FakeReports,
		&row.LiveReportsSubmitted,
		&row.LiveConfirmationsGiven,
		&row.LiveDriversSaved,
		&row.NightReportsSubmitted,
		&row.UpdatedAt,
	)
	if err == nil {
		return row, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return row, fmt.Errorf("get user stats: %w", err)
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO user_stats (user_id)
		VALUES ($1)
		ON CONFLICT DO NOTHING
	`, userID)
	if err != nil {
		return row, fmt.Errorf("insert empty user stats: %w", err)
	}

	err = tx.QueryRow(ctx, `
		SELECT total_distance_m, total_drive_time_sec, total_drives,
		       radars_encountered, night_drives, safe_drives,
		       reports_submitted, confirmations_given, drivers_saved, fake_reports,
		       live_reports_submitted, live_confirmations_given, live_drivers_saved,
		       night_reports_submitted,
		       updated_at
		FROM user_stats
		WHERE user_id = $1
	`, userID).Scan(
		&row.TotalDistanceM,
		&row.TotalDriveTimeSec,
		&row.TotalDrives,
		&row.RadarsEncountered,
		&row.NightDrives,
		&row.SafeDrives,
		&row.ReportsSubmitted,
		&row.ConfirmationsGiven,
		&row.DriversSaved,
		&row.FakeReports,
		&row.LiveReportsSubmitted,
		&row.LiveConfirmationsGiven,
		&row.LiveDriversSaved,
		&row.NightReportsSubmitted,
		&row.UpdatedAt,
	)
	if err != nil {
		return row, fmt.Errorf("reload user stats: %w", err)
	}
	return row, nil
}

func applyDriveToStats(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	driveID uuid.UUID,
	lengthM float64,
	startedAt, endedAt time.Time,
	points []DrivePoint,
) error {
	cameraIDs, err := camerasNearDrive(ctx, tx, driveID)
	if err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE drives SET radars_encountered = $1 WHERE id = $2
	`, len(cameraIDs), driveID); err != nil {
		return fmt.Errorf("update drive radars: %w", err)
	}

	for _, cameraID := range cameraIDs {
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_camera_encounters (user_id, camera_id, first_seen_at)
			VALUES ($1, $2, $3)
			ON CONFLICT DO NOTHING
		`, userID, cameraID, startedAt); err != nil {
			return fmt.Errorf("upsert camera encounter: %w", err)
		}
	}

	var uniqueRadars int
	if err := tx.QueryRow(ctx, `
		SELECT COUNT(*)::INT FROM user_camera_encounters WHERE user_id = $1
	`, userID).Scan(&uniqueRadars); err != nil {
		return fmt.Errorf("count camera encounters: %w", err)
	}

	driveTimeSec := int64(endedAt.Sub(startedAt).Seconds())
	if driveTimeSec < 0 {
		driveTimeSec = 0
	}
	nightInc := 0
	if isNightDrive(startedAt) {
		nightInc = 1
	}
	safeInc := 0
	if isSafeDrive(points) {
		safeInc = 1
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO user_stats (
			user_id, total_distance_m, total_drive_time_sec, total_drives,
			radars_encountered, night_drives, safe_drives, updated_at
		) VALUES ($1, $2, $3, 1, $4, $5, $6, now())
		ON CONFLICT (user_id) DO UPDATE SET
			total_distance_m = user_stats.total_distance_m + EXCLUDED.total_distance_m,
			total_drive_time_sec = user_stats.total_drive_time_sec + EXCLUDED.total_drive_time_sec,
			total_drives = user_stats.total_drives + 1,
			radars_encountered = EXCLUDED.radars_encountered,
			night_drives = user_stats.night_drives + EXCLUDED.night_drives,
			safe_drives = user_stats.safe_drives + EXCLUDED.safe_drives,
			updated_at = now()
	`, userID, lengthM, driveTimeSec, uniqueRadars, nightInc, safeInc)
	if err != nil {
		return fmt.Errorf("upsert user stats: %w", err)
	}

	stats, err := ensureUserStats(ctx, tx, userID)
	if err != nil {
		return err
	}
	if _, _, err := applyReputationEvent(
		ctx,
		tx,
		userID,
		reputationEventKeyDrive(driveID),
		reputationReasonDrive,
		xpForDrive(lengthM),
		0,
	); err != nil {
		return err
	}
	if _, err := updateUserStreak(ctx, tx, userID, driveStreakType, endedAt); err != nil {
		return err
	}
	return evaluateAchievements(ctx, tx, userID, stats)
}

func camerasNearDrive(ctx context.Context, tx pgx.Tx, driveID uuid.UUID) ([]int64, error) {
	rows, err := tx.Query(ctx, `
		SELECT c.id
		FROM fixed_cameras c
		JOIN drives d ON d.id = $1
		WHERE c.active
		  AND ST_DWithin(c.location, d.path, $2)
	`, driveID, radarEncounterRadiusM)
	if err != nil {
		return nil, fmt.Errorf("query cameras near drive: %w", err)
	}
	defer rows.Close()

	ids := make([]int64, 0)
	for rows.Next() {
		var id int64
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("scan camera id: %w", err)
		}
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate cameras: %w", err)
	}
	return ids, nil
}
