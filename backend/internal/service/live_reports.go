package service

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrInvalidLiveReport = errors.New("invalid live report")
var ErrLiveReportNotFound = errors.New("live report not found")
var ErrLiveReportInactive = errors.New("live report is not active")
var ErrCannotVoteOwnLiveReport = errors.New("cannot vote on own live report")

type CreateLiveReportInput struct {
	Lat        float64 `json:"lat"`
	Lng        float64 `json:"lng"`
	ReportType string  `json:"report_type"`
}

type LiveReport struct {
	ID                string    `json:"id"`
	UserID            string    `json:"user_id"`
	Lat               float64   `json:"lat"`
	Lng               float64   `json:"lng"`
	ReportType        string    `json:"report_type"`
	CreatedAt         time.Time `json:"created_at"`
	ExpiresAt         time.Time `json:"expires_at"`
	VerificationState string    `json:"verification_state"`
	WeightedScore     float64   `json:"weighted_score"`
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

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin live report create tx: %w", err)
	}
	defer tx.Rollback(ctx)
	var (
		id        uuid.UUID
		createdAt time.Time
		expiresAt time.Time
		state     string
		score     float64
	)
	err = tx.QueryRow(ctx, `
		INSERT INTO user_reports (
			user_id, lat, lng, report_type, expires_at, verification_state
		)
		VALUES ($1, $2, $3, $4, $5, 'pending')
		RETURNING id, created_at, expires_at, verification_state, weighted_score
	`, userID, in.Lat, in.Lng, reportType, time.Now().UTC().Add(liveReportTTL)).Scan(
		&id, &createdAt, &expiresAt, &state, &score,
	)
	if err != nil {
		return nil, fmt.Errorf("insert user_report: %w", err)
	}
	if err := bumpStat(ctx, tx, userID, "live_reports_submitted", 1); err != nil {
		return nil, err
	}
	if isNightDrive(createdAt) {
		if err := bumpStat(ctx, tx, userID, "night_reports_submitted", 1); err != nil {
			return nil, err
		}
	}
	if _, _, err := applyReputationEvent(
		ctx,
		tx,
		userID,
		reputationEventKeyLiveReportCreate(id),
		reputationReasonReport,
		20,
		0,
	); err != nil {
		return nil, err
	}
	stats, err := ensureUserStats(ctx, tx, userID)
	if err != nil {
		return nil, err
	}
	if err := evaluateAchievements(ctx, tx, userID, stats); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit live report create tx: %w", err)
	}

	return &LiveReport{
		ID:                id.String(),
		UserID:            userID.String(),
		Lat:               in.Lat,
		Lng:               in.Lng,
		ReportType:        reportType,
		CreatedAt:         createdAt,
		ExpiresAt:         expiresAt,
		VerificationState: state,
		WeightedScore:     score,
	}, nil
}

func (s *LiveReportService) ListActive(ctx context.Context) ([]LiveReport, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, user_id, lat, lng, report_type, created_at, expires_at,
		       verification_state, weighted_score
		FROM user_reports
		WHERE expires_at > NOW()
		  AND verification_state IN ('pending', 'confirmed')
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
		if err := rows.Scan(
			&id,
			&userID,
			&report.Lat,
			&report.Lng,
			&report.ReportType,
			&report.CreatedAt,
			&report.ExpiresAt,
			&report.VerificationState,
			&report.WeightedScore,
		); err != nil {
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

func (s *LiveReportService) Vote(
	ctx context.Context,
	reportID uuid.UUID,
	userID uuid.UUID,
	isUpvote bool,
) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin live report vote tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var (
		reporterID uuid.UUID
		expiresAt  time.Time
		state      string
		score      float64
	)
	if err := tx.QueryRow(ctx, `
		SELECT user_id, expires_at, verification_state, weighted_score
		FROM user_reports
		WHERE id = $1
		FOR UPDATE
	`, reportID).Scan(&reporterID, &expiresAt, &state, &score); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrLiveReportNotFound
		}
		return fmt.Errorf("load live report: %w", err)
	}
	if reporterID == userID {
		return ErrCannotVoteOwnLiveReport
	}
	if state == "rejected" || state == "expired" || state == "confirmed" || !expiresAt.After(time.Now().UTC()) {
		return ErrLiveReportInactive
	}

	voterRep, err := ensureUserReputation(ctx, tx, userID)
	if err != nil {
		return err
	}
	voteWeight := weightForRankCode(voterRep.RankCode)

	var prevVote struct {
		IsUpvote   bool
		VoteWeight float64
	}
	prevFound := false
	err = tx.QueryRow(ctx, `
		SELECT is_upvote, vote_weight
		FROM report_votes
		WHERE report_id = $1 AND user_id = $2
	`, reportID, userID).Scan(&prevVote.IsUpvote, &prevVote.VoteWeight)
	if err == nil {
		prevFound = true
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("load live report vote: %w", err)
	}
	if prevFound && prevVote.IsUpvote == isUpvote && math.Abs(prevVote.VoteWeight-voteWeight) < 0.001 {
		return nil
	}

	tag, err := tx.Exec(ctx, `
		INSERT INTO report_votes (report_id, user_id, is_upvote, vote_weight, voter_rank_code, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, now(), now())
		ON CONFLICT (report_id, user_id)
		DO UPDATE SET
			is_upvote = EXCLUDED.is_upvote,
			vote_weight = EXCLUDED.vote_weight,
			voter_rank_code = EXCLUDED.voter_rank_code,
			updated_at = now()
	`, reportID, userID, isUpvote, voteWeight, voterRep.RankCode)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23503" {
			return ErrLiveReportNotFound
		}
		return fmt.Errorf("upsert report vote: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrLiveReportNotFound
	}

	var (
		weightedUp   float64
		weightedDown float64
	)
	if err := tx.QueryRow(ctx, `
		SELECT
			COALESCE(SUM(CASE WHEN is_upvote THEN vote_weight ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN NOT is_upvote THEN vote_weight ELSE 0 END), 0)
		FROM report_votes
		WHERE report_id = $1
	`, reportID).Scan(&weightedUp, &weightedDown); err != nil {
		return fmt.Errorf("aggregate live report votes: %w", err)
	}
	score = weightedUp - weightedDown
	if _, err := tx.Exec(ctx, `
		UPDATE user_reports
		SET weighted_up_score = $2,
		    weighted_down_score = $3,
		    weighted_score = $4
		WHERE id = $1
	`, reportID, weightedUp, weightedDown, score); err != nil {
		return fmt.Errorf("update live report score: %w", err)
	}

	nowUp := isUpvote
	wasUp := prevFound && prevVote.IsUpvote
	if nowUp && !wasUp {
		if err := bumpStat(ctx, tx, userID, "live_confirmations_given", 1); err != nil {
			return err
		}
		if err := bumpStat(ctx, tx, reporterID, "live_drivers_saved", 1); err != nil {
			return err
		}
		if _, _, err := applyReputationEvent(
			ctx,
			tx,
			userID,
			reputationEventKeyLiveVote(reportID, userID),
			reputationReasonVote,
			5,
			0,
		); err != nil {
			return err
		}
	}
	if wasUp && !nowUp {
		if err := bumpStat(ctx, tx, reporterID, "live_drivers_saved", -1); err != nil {
			return err
		}
	}

	if _, err := s.settleLiveReportTx(ctx, tx, reportID, false); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit live report vote tx: %w", err)
	}
	return nil
}

func (s *LiveReportService) SettleExpired(ctx context.Context) (int64, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id
		FROM user_reports
		WHERE settled_at IS NULL
		  AND (
		        expires_at <= now()
		     OR weighted_score >= $1
		     OR weighted_score <= $2
		  )
	`, liveConfirmThreshold, liveRejectThreshold)
	if err != nil {
		return 0, fmt.Errorf("query pending live reports: %w", err)
	}
	defer rows.Close()

	reportIDs := make([]uuid.UUID, 0)
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return 0, fmt.Errorf("scan pending live report id: %w", err)
		}
		reportIDs = append(reportIDs, id)
	}
	if err := rows.Err(); err != nil {
		return 0, fmt.Errorf("iterate pending live reports: %w", err)
	}

	var settled int64
	for _, id := range reportIDs {
		tx, err := s.pool.Begin(ctx)
		if err != nil {
			return settled, fmt.Errorf("begin settle tx: %w", err)
		}
		changed, settleErr := s.settleLiveReportTx(ctx, tx, id, true)
		if settleErr != nil {
			tx.Rollback(ctx)
			return settled, settleErr
		}
		if err := tx.Commit(ctx); err != nil {
			return settled, fmt.Errorf("commit settle tx: %w", err)
		}
		if changed {
			settled++
		}
	}
	return settled, nil
}

func (s *LiveReportService) settleLiveReportTx(
	ctx context.Context,
	tx pgx.Tx,
	reportID uuid.UUID,
	allowExpiry bool,
) (bool, error) {
	var (
		reporterID    uuid.UUID
		reportType    string
		expiresAt     time.Time
		currentState  string
		weightedUp    float64
		weightedDown  float64
		weightedScore float64
		settledAt     *time.Time
	)
	if err := tx.QueryRow(ctx, `
		SELECT user_id, report_type, expires_at, verification_state,
		       weighted_up_score, weighted_down_score, weighted_score, settled_at
		FROM user_reports
		WHERE id = $1
		FOR UPDATE
	`, reportID).Scan(
		&reporterID,
		&reportType,
		&expiresAt,
		&currentState,
		&weightedUp,
		&weightedDown,
		&weightedScore,
		&settledAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, ErrLiveReportNotFound
		}
		return false, fmt.Errorf("load live report settlement row: %w", err)
	}
	if settledAt != nil {
		return false, nil
	}

	newState := currentState
	now := time.Now().UTC()
	resolvedState, shouldSettle := resolveLiveSettlementState(weightedScore, expiresAt, now, allowExpiry)
	if !shouldSettle {
		return false, nil
	}
	newState = resolvedState

	if _, err := tx.Exec(ctx, `
		UPDATE user_reports
		SET verification_state = $2,
		    settled_at = now()
		WHERE id = $1
	`, reportID, newState); err != nil {
		return false, fmt.Errorf("update live report settlement: %w", err)
	}

	reporterWon := newState == "confirmed"
	if reporterWon {
		if err := bumpStat(ctx, tx, reporterID, "valid_contributions", 1); err != nil {
			return false, err
		}
	}
	reporterRep, err := ensureUserReputation(ctx, tx, reporterID)
	if err != nil {
		return false, err
	}
	reporterEloDelta := eloDeltaForOutcome(reporterRep.ELORating, reporterWon)
	if _, _, err := applyReputationEvent(
		ctx,
		tx,
		reporterID,
		reputationEventKeyLiveSettleReporter(reportID),
		reputationReasonSettle,
		liveReporterXPDelta(newState),
		reporterEloDelta,
	); err != nil {
		return false, err
	}
	if newState == "confirmed" && reportType == "accident" {
		if _, err := tx.Exec(ctx, `
			INSERT INTO first_responder_awards (report_type, report_id, user_id, awarded_at)
			VALUES ($1, $2, $3, now())
			ON CONFLICT (report_type) DO NOTHING
		`, reportType, reportID, reporterID); err != nil {
			return false, fmt.Errorf("insert first responder award: %w", err)
		}
		var awardedUser uuid.UUID
		err := tx.QueryRow(ctx, `
			SELECT user_id
			FROM first_responder_awards
			WHERE report_type = $1
		`, reportType).Scan(&awardedUser)
		if err != nil {
			return false, fmt.Errorf("load first responder award: %w", err)
		}
		if awardedUser == reporterID {
			if err := unlockAchievement(ctx, tx, reporterID, AchievementFirstResponder); err != nil {
				return false, err
			}
		}
	}

	rows, err := tx.Query(ctx, `
		SELECT user_id, is_upvote
		FROM report_votes
		WHERE report_id = $1
	`, reportID)
	if err != nil {
		return false, fmt.Errorf("query live report voters: %w", err)
	}
	type liveVoter struct {
		userID   uuid.UUID
		isUpvote bool
	}
	voters := make([]liveVoter, 0)
	for rows.Next() {
		var (
			voterID  uuid.UUID
			isUpvote bool
		)
		if err := rows.Scan(&voterID, &isUpvote); err != nil {
			rows.Close()
			return false, fmt.Errorf("scan live report voter: %w", err)
		}
		voters = append(voters, liveVoter{userID: voterID, isUpvote: isUpvote})
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return false, fmt.Errorf("iterate live report voters: %w", err)
	}
	rows.Close()
	for _, voter := range voters {
		won := (newState == "confirmed" && voter.isUpvote) || (newState == "rejected" && !voter.isUpvote)
		xpDelta := int64(0)
		if won {
			xpDelta = 12
		}
		voterRep, err := ensureUserReputation(ctx, tx, voter.userID)
		if err != nil {
			return false, err
		}
		if _, _, err := applyReputationEvent(
			ctx,
			tx,
			voter.userID,
			reputationEventKeyLiveSettleVoter(reportID, voter.userID),
			reputationReasonSettle,
			xpDelta,
			eloDeltaForOutcome(voterRep.ELORating, won),
		); err != nil {
			return false, err
		}
		voterStats, err := ensureUserStats(ctx, tx, voter.userID)
		if err != nil {
			return false, err
		}
		if err := evaluateAchievements(ctx, tx, voter.userID, voterStats); err != nil {
			return false, err
		}
	}

	reporterStats, err := ensureUserStats(ctx, tx, reporterID)
	if err != nil {
		return false, err
	}
	if err := evaluateAchievements(ctx, tx, reporterID, reporterStats); err != nil {
		return false, err
	}
	return true, nil
}

func liveReporterXPDelta(state string) int64 {
	switch state {
	case "confirmed":
		return 40
	case "rejected":
		return -10
	default:
		return 0
	}
}

func resolveLiveSettlementState(weightedScore float64, expiresAt, now time.Time, allowExpiry bool) (string, bool) {
	switch {
	case weightedScore >= liveConfirmThreshold:
		return "confirmed", true
	case weightedScore <= liveRejectThreshold:
		return "rejected", true
	case allowExpiry && !expiresAt.After(now):
		if weightedScore > 0 {
			return "confirmed", true
		}
		if weightedScore < 0 {
			return "rejected", true
		}
		return "expired", true
	default:
		return "", false
	}
}

func normalizeLiveReportType(raw string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "police", "accident":
		return strings.ToLower(strings.TrimSpace(raw)), nil
	default:
		return "", ErrInvalidLiveReport
	}
}
