package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

const (
	defaultELORating       = 1000.0
	eloKFactor             = 24.0
	eloBaselineRating      = 1000.0
	driveStreakType        = "drive_days"
	liveReportTTL          = 2 * time.Hour
	liveConfirmThreshold   = 2.5
	liveRejectThreshold    = -2.0
	reputationReasonDrive  = "drive_upload"
	reputationReasonReport = "report_action"
	reputationReasonVote   = "vote_action"
	reputationReasonSettle = "live_report_settlement"
)

type RankDefinition struct {
	Code       string
	Title      string
	MinXP      int64
	Level      int
	VoteWeight float64
}

type UserReputation struct {
	XP        int64
	RankCode  string
	RankTitle string
	Level     int
	ELORating float64
	UpdatedAt time.Time
}

type UserStreak struct {
	Current         int       `json:"current"`
	Best            int       `json:"best"`
	LastActivityDay time.Time `json:"last_activity_day,omitempty"`
}

var rankDefinitions = []RankDefinition{
	{Code: "caylak", Title: "Çaylak", MinXP: 0, Level: 1, VoteWeight: 1},
	{Code: "gozcu", Title: "Gözcü", MinXP: 500, Level: 2, VoteWeight: 1.5},
	{Code: "yolun_hakimi", Title: "Yolun Hakimi", MinXP: 1500, Level: 3, VoteWeight: 2},
	{Code: "radar_avcisi", Title: "Radar Avcısı", MinXP: 4000, Level: 4, VoteWeight: 3},
}

func rankForXP(xp int64) RankDefinition {
	current := rankDefinitions[0]
	for _, def := range rankDefinitions {
		if xp >= def.MinXP {
			current = def
		}
	}
	return current
}

func nextRankForXP(xp int64) *RankDefinition {
	for _, def := range rankDefinitions {
		if xp < def.MinXP {
			copyDef := def
			return &copyDef
		}
	}
	return nil
}

func weightForRankCode(code string) float64 {
	for _, def := range rankDefinitions {
		if def.Code == code {
			return def.VoteWeight
		}
	}
	return rankDefinitions[0].VoteWeight
}

func titleForRankCode(code string) string {
	for _, def := range rankDefinitions {
		if def.Code == code {
			return def.Title
		}
	}
	return rankDefinitions[0].Title
}

func ensureUserReputation(ctx context.Context, tx pgx.Tx, userID uuid.UUID) (UserReputation, error) {
	var rep UserReputation
	err := tx.QueryRow(ctx, `
		SELECT xp, rank_code, level, elo_rating, updated_at
		FROM user_reputation
		WHERE user_id = $1
	`, userID).Scan(&rep.XP, &rep.RankCode, &rep.Level, &rep.ELORating, &rep.UpdatedAt)
	if err == nil {
		rep.RankTitle = titleForRankCode(rep.RankCode)
		return rep, nil
	}
	if err != pgx.ErrNoRows {
		return rep, fmt.Errorf("get user reputation: %w", err)
	}

	def := rankDefinitions[0]
	err = tx.QueryRow(ctx, `
		INSERT INTO user_reputation (user_id, xp, rank_code, level, elo_rating, updated_at)
		VALUES ($1, 0, $2, $3, $4, now())
		ON CONFLICT (user_id) DO UPDATE SET updated_at = now()
		RETURNING xp, rank_code, level, elo_rating, updated_at
	`, userID, def.Code, def.Level, defaultELORating).Scan(
		&rep.XP, &rep.RankCode, &rep.Level, &rep.ELORating, &rep.UpdatedAt,
	)
	if err != nil {
		return rep, fmt.Errorf("upsert user reputation: %w", err)
	}
	rep.RankTitle = titleForRankCode(rep.RankCode)
	if _, err := tx.Exec(ctx, `
		INSERT INTO user_rank_history (user_id, from_rank_code, to_rank_code)
		VALUES ($1, NULL, $2)
	`, userID, rep.RankCode); err != nil {
		return rep, fmt.Errorf("insert initial rank history: %w", err)
	}
	return rep, nil
}

func applyReputationEvent(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	eventKey string,
	reason string,
	xpDelta int64,
	eloDelta float64,
) (bool, UserReputation, error) {
	var rep UserReputation
	tag, err := tx.Exec(ctx, `
		INSERT INTO user_reputation_events (user_id, event_key, reason, xp_delta, elo_delta)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (event_key) DO NOTHING
	`, userID, eventKey, reason, xpDelta, eloDelta)
	if err != nil {
		return false, rep, fmt.Errorf("insert reputation event: %w", err)
	}
	rep, err = ensureUserReputation(ctx, tx, userID)
	if err != nil {
		return false, rep, err
	}
	if tag.RowsAffected() == 0 {
		return false, rep, nil
	}

	newXP := rep.XP + xpDelta
	if newXP < 0 {
		newXP = 0
	}
	newELO := rep.ELORating + eloDelta
	if newELO < 0 {
		newELO = 0
	}
	nextRank := rankForXP(newXP)
	_, err = tx.Exec(ctx, `
		UPDATE user_reputation
		SET xp = $2,
		    rank_code = $3,
		    level = $4,
		    elo_rating = $5,
		    updated_at = now()
		WHERE user_id = $1
	`, userID, newXP, nextRank.Code, nextRank.Level, newELO)
	if err != nil {
		return false, rep, fmt.Errorf("update user reputation: %w", err)
	}
	if rep.RankCode != nextRank.Code {
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_rank_history (user_id, from_rank_code, to_rank_code)
			VALUES ($1, $2, $3)
		`, userID, rep.RankCode, nextRank.Code); err != nil {
			return false, rep, fmt.Errorf("insert rank history: %w", err)
		}
	}

	rep.XP = newXP
	rep.RankCode = nextRank.Code
	rep.RankTitle = nextRank.Title
	rep.Level = nextRank.Level
	rep.ELORating = newELO
	rep.UpdatedAt = time.Now().UTC()
	return true, rep, nil
}

func xpForDrive(lengthM float64) int64 {
	km := math.Round(lengthM / 1000)
	if km < 1 {
		return 1
	}
	return int64(km)
}

func eloDeltaForOutcome(rating float64, won bool) float64 {
	expected := 1.0 / (1.0 + math.Pow(10, (eloBaselineRating-rating)/400.0))
	actual := 0.0
	if won {
		actual = 1.0
	}
	return eloKFactor * (actual - expected)
}

func updateUserStreak(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	streakType string,
	at time.Time,
) (UserStreak, error) {
	var streak UserStreak
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		loc = time.FixedZone("TRT", 3*3600)
	}
	day := at.In(loc)
	dayOnly := time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, loc)

	var (
		current int
		best    int
		lastDay *time.Time
	)
	err = tx.QueryRow(ctx, `
		SELECT current_streak, best_streak, last_activity_day
		FROM user_streaks
		WHERE user_id = $1 AND streak_type = $2
	`, userID, streakType).Scan(&current, &best, &lastDay)
	if err != nil && err != pgx.ErrNoRows {
		return streak, fmt.Errorf("load streak: %w", err)
	}

	switch {
	case err == pgx.ErrNoRows:
		current = 1
		best = 1
	case lastDay == nil:
		current = 1
		if best < 1 {
			best = 1
		}
	default:
		lastLocal := lastDay.In(loc)
		lastDayOnly := time.Date(lastLocal.Year(), lastLocal.Month(), lastLocal.Day(), 0, 0, 0, 0, loc)
		diff := int(dayOnly.Sub(lastDayOnly).Hours() / 24)
		if diff <= 0 {
			// Same day or out-of-order write keeps streak intact.
		} else if diff == 1 {
			current++
		} else {
			current = 1
		}
		if current > best {
			best = current
		}
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO user_streaks (user_id, streak_type, current_streak, best_streak, last_activity_day, updated_at)
		VALUES ($1, $2, $3, $4, $5, now())
		ON CONFLICT (user_id, streak_type) DO UPDATE SET
			current_streak = EXCLUDED.current_streak,
			best_streak = GREATEST(user_streaks.best_streak, EXCLUDED.best_streak),
			last_activity_day = EXCLUDED.last_activity_day,
			updated_at = now()
	`, userID, streakType, current, best, dayOnly)
	if err != nil {
		return streak, fmt.Errorf("upsert streak: %w", err)
	}
	streak.Current = current
	streak.Best = best
	streak.LastActivityDay = dayOnly
	return streak, nil
}

func loadUserStreak(ctx context.Context, tx pgx.Tx, userID uuid.UUID, streakType string) (UserStreak, error) {
	var streak UserStreak
	var lastDay *time.Time
	err := tx.QueryRow(ctx, `
		SELECT current_streak, best_streak, last_activity_day
		FROM user_streaks
		WHERE user_id = $1 AND streak_type = $2
	`, userID, streakType).Scan(&streak.Current, &streak.Best, &lastDay)
	if err == pgx.ErrNoRows {
		return streak, nil
	}
	if err != nil {
		return streak, fmt.Errorf("get user streak: %w", err)
	}
	if lastDay != nil {
		streak.LastActivityDay = *lastDay
	}
	return streak, nil
}

func reputationEventKeyDrive(driveID uuid.UUID) string {
	return fmt.Sprintf("drive:%s", driveID.String())
}

func reputationEventKeyCrowdReportCreate(reportID int64) string {
	return fmt.Sprintf("crowd-report-create:%d", reportID)
}

func reputationEventKeyCrowdVoteUp(reportID int64, userID uuid.UUID) string {
	return fmt.Sprintf("crowd-vote-up:%d:%s", reportID, userID.String())
}

func reputationEventKeyLiveReportCreate(reportID uuid.UUID) string {
	return fmt.Sprintf("live-report-create:%s", reportID.String())
}

func reputationEventKeyLiveVote(reportID, userID uuid.UUID) string {
	return fmt.Sprintf("live-vote:%s:%s", reportID.String(), userID.String())
}

func reputationEventKeyLiveSettleReporter(reportID uuid.UUID) string {
	return fmt.Sprintf("live-settle:reporter:%s", reportID.String())
}

func reputationEventKeyLiveSettleVoter(reportID, userID uuid.UUID) string {
	return fmt.Sprintf("live-settle:voter:%s:%s", reportID.String(), userID.String())
}
