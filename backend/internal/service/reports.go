package service

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	reportTTL              = 3 * time.Hour
	reportTTLCap           = 12 * time.Hour
	reportDedupRadiusM     = 80.0
	reportRecentRadiusM    = 200.0
	reportRecentWindow     = 30 * time.Minute
	voteProximityRadiusM   = 250.0
	reportRateLimitCount   = 5
	reportRateLimitWindow  = 15 * time.Minute
	voteRateLimitCount     = 30
	voteRateLimitWindow    = 15 * time.Minute
	fakeReportBanThreshold = 3
	fakeReportBanWindow    = 7 * 24 * time.Hour
	confidenceFloor        = 0.15
	minVotesForCollapse    = 3
)

var (
	ErrInvalidReport     = errors.New("invalid report")
	ErrReportNotFound    = errors.New("report not found")
	ErrReportInactive    = errors.New("report is not active")
	ErrTooFarToVote      = errors.New("too far from report to vote")
	ErrCannotVoteOwn     = errors.New("cannot vote on own report")
	ErrReportRateLimited = errors.New("report rate limit exceeded")
	ErrVoteRateLimited   = errors.New("vote rate limit exceeded")
	ErrReportBanned      = errors.New("temporarily banned from reporting")
	ErrInvalidVoteValue  = errors.New("vote value must be 1 or -1")
)

type ReportService struct {
	pool *pgxpool.Pool
}

func NewReportService(pool *pgxpool.Pool) *ReportService {
	return &ReportService{pool: pool}
}

type CreateReportInput struct {
	Lat        float64  `json:"lat"`
	Lon        float64  `json:"lon"`
	HeadingDeg *float64 `json:"heading_deg,omitempty"`
	Region     string   `json:"region,omitempty"`
}

type ReportResult struct {
	ID              int64     `json:"id"`
	Lat             float64   `json:"lat"`
	Lon             float64   `json:"lon"`
	RegionCode      string    `json:"region_code"`
	Status          string    `json:"status"`
	ConfidenceScore float64   `json:"confidence_score"`
	Upvotes         int       `json:"upvotes"`
	Downvotes       int       `json:"downvotes"`
	ExpiresAt       time.Time `json:"expires_at"`
	Merged          bool      `json:"merged"`
	Source          string    `json:"source"`
}

type VoteInput struct {
	Value int     `json:"value"`
	Lat   float64 `json:"lat"`
	Lon   float64 `json:"lon"`
}

func (s *ReportService) ExpireStale(ctx context.Context) (int64, error) {
	tag, err := s.pool.Exec(ctx, `
		UPDATE mobile_cameras
		SET status = 'expired', updated_at = now()
		WHERE status = 'active' AND expires_at <= now()
	`)
	if err != nil {
		return 0, fmt.Errorf("expire mobile cameras: %w", err)
	}
	return tag.RowsAffected(), nil
}

func (s *ReportService) Create(ctx context.Context, userID uuid.UUID, in CreateReportInput) (*ReportResult, error) {
	if in.Lat < -90 || in.Lat > 90 || in.Lon < -180 || in.Lon > 180 {
		return nil, ErrInvalidReport
	}
	region := in.Region
	if region == "" {
		region = "bursa"
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin report tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if err := s.ExpireStaleTx(ctx, tx); err != nil {
		return nil, err
	}
	if err := ensureReporterAllowed(ctx, tx, userID); err != nil {
		return nil, err
	}
	if err := checkReportRateLimit(ctx, tx, userID); err != nil {
		return nil, err
	}

	// Reject duplicate personal reports nearby in the last 30 minutes.
	var recentOwn int
	if err := tx.QueryRow(ctx, `
		SELECT COUNT(*)::INT
		FROM mobile_cameras
		WHERE reporter_id = $1
		  AND created_at > now() - ($2 * interval '1 second')
		  AND ST_DWithin(
		        location,
		        ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography,
		        $5
		      )
	`, userID, reportRecentWindow.Seconds(), in.Lon, in.Lat, reportRecentRadiusM).Scan(&recentOwn); err != nil {
		return nil, fmt.Errorf("check recent reports: %w", err)
	}
	if recentOwn > 0 {
		return nil, ErrInvalidReport
	}

	// Merge into nearby active report within 80 m.
	var existingID int64
	err = tx.QueryRow(ctx, `
		SELECT id
		FROM mobile_cameras
		WHERE status = 'active'
		  AND expires_at > now()
		  AND region_code = $1
		  AND ST_DWithin(
		        location,
		        ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography,
		        $4
		      )
		ORDER BY ST_Distance(
		           location,
		           ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography
		         )
		LIMIT 1
	`, region, in.Lon, in.Lat, reportDedupRadiusM).Scan(&existingID)
	if err == nil {
		result, mergeErr := applyVoteTx(ctx, tx, userID, existingID, 1, in.Lat, in.Lon, true)
		if mergeErr != nil {
			if errors.Is(mergeErr, ErrCannotVoteOwn) {
				// Reporter re-tapping their own nearby report: return existing.
				out, loadErr := loadReportResult(ctx, tx, existingID, true)
				if loadErr != nil {
					return nil, loadErr
				}
				if err := tx.Commit(ctx); err != nil {
					return nil, fmt.Errorf("commit report tx: %w", err)
				}
				return out, nil
			}
			return nil, mergeErr
		}
		if err := tx.Commit(ctx); err != nil {
			return nil, fmt.Errorf("commit report tx: %w", err)
		}
		return result, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return nil, fmt.Errorf("find nearby report: %w", err)
	}

	expiresAt := time.Now().UTC().Add(reportTTL)
	var id int64
	var lat, lon, confidence float64
	var upvotes, downvotes int
	var status string
	var expires time.Time
	err = tx.QueryRow(ctx, `
		INSERT INTO mobile_cameras (
			reporter_id, region_code, location, heading_deg,
			status, confidence_score, expires_at, last_confirmed_at
		) VALUES (
			$1, $2,
			ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography,
			$5, 'active', 0.35, $6, now()
		)
		RETURNING id,
		          ST_Y(location::geometry), ST_X(location::geometry),
		          status, confidence_score, upvotes, downvotes, expires_at
	`, userID, region, in.Lon, in.Lat, in.HeadingDeg, expiresAt).Scan(
		&id, &lat, &lon, &status, &confidence, &upvotes, &downvotes, &expires,
	)
	if err != nil {
		return nil, fmt.Errorf("insert mobile camera: %w", err)
	}

	if err := bumpStat(ctx, tx, userID, "reports_submitted", 1); err != nil {
		return nil, err
	}
	if isNightDrive(time.Now().UTC()) {
		if err := bumpStat(ctx, tx, userID, "night_reports_submitted", 1); err != nil {
			return nil, err
		}
	}
	if _, _, err := applyReputationEvent(
		ctx,
		tx,
		userID,
		reputationEventKeyCrowdReportCreate(id),
		reputationReasonReport,
		30,
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
		return nil, fmt.Errorf("commit report tx: %w", err)
	}

	return &ReportResult{
		ID:              id,
		Lat:             lat,
		Lon:             lon,
		RegionCode:      region,
		Status:          status,
		ConfidenceScore: confidence,
		Upvotes:         upvotes,
		Downvotes:       downvotes,
		ExpiresAt:       expires,
		Merged:          false,
		Source:          "crowd",
	}, nil
}

func (s *ReportService) Vote(ctx context.Context, userID uuid.UUID, cameraID int64, in VoteInput) (*ReportResult, error) {
	if in.Value != 1 && in.Value != -1 {
		return nil, ErrInvalidVoteValue
	}
	if in.Lat < -90 || in.Lat > 90 || in.Lon < -180 || in.Lon > 180 {
		return nil, ErrInvalidReport
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin vote tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if err := s.ExpireStaleTx(ctx, tx); err != nil {
		return nil, err
	}
	if err := checkVoteRateLimit(ctx, tx, userID); err != nil {
		return nil, err
	}

	result, err := applyVoteTx(ctx, tx, userID, cameraID, in.Value, in.Lat, in.Lon, false)
	if err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit vote tx: %w", err)
	}
	return result, nil
}

func (s *ReportService) ExpireStaleTx(ctx context.Context, tx pgx.Tx) error {
	_, err := tx.Exec(ctx, `
		UPDATE mobile_cameras
		SET status = 'expired', updated_at = now()
		WHERE status = 'active' AND expires_at <= now()
	`)
	if err != nil {
		return fmt.Errorf("expire mobile cameras: %w", err)
	}
	return nil
}

func applyVoteTx(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	cameraID int64,
	value int,
	lat, lon float64,
	allowMergeOwn bool,
) (*ReportResult, error) {
	var (
		reporterID           uuid.UUID
		status               string
		upvotes, downvotes   int
		confidence           float64
		expiresAt, createdAt time.Time
		withinProximity      bool
	)
	err := tx.QueryRow(ctx, `
		SELECT reporter_id, status, upvotes, downvotes, confidence_score,
		       expires_at, created_at,
		       ST_DWithin(
		         location,
		         ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography,
		         $4
		       )
		FROM mobile_cameras
		WHERE id = $1
		FOR UPDATE
	`, cameraID, lon, lat, voteProximityRadiusM).Scan(
		&reporterID, &status, &upvotes, &downvotes, &confidence,
		&expiresAt, &createdAt, &withinProximity,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrReportNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("load mobile camera: %w", err)
	}
	if status != "active" || expiresAt.Before(time.Now().UTC()) {
		return nil, ErrReportInactive
	}
	if !withinProximity {
		return nil, ErrTooFarToVote
	}
	if reporterID == userID {
		return nil, ErrCannotVoteOwn
	}

	var prev *int16
	var prevVal int16
	err = tx.QueryRow(ctx, `
		SELECT value FROM mobile_camera_votes
		WHERE camera_id = $1 AND user_id = $2
	`, cameraID, userID).Scan(&prevVal)
	if err == nil {
		prev = &prevVal
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, fmt.Errorf("load existing vote: %w", err)
	}

	if prev != nil && int(*prev) == value {
		return loadReportResult(ctx, tx, cameraID, allowMergeOwn)
	}

	upDelta, downDelta := 0, 0
	if prev == nil {
		if value == 1 {
			upDelta = 1
		} else {
			downDelta = 1
		}
	} else {
		// Flip.
		if value == 1 {
			upDelta = 1
			downDelta = -1
		} else {
			upDelta = -1
			downDelta = 1
		}
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO mobile_camera_votes (camera_id, user_id, value, updated_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (camera_id, user_id) DO UPDATE SET
			value = EXCLUDED.value,
			updated_at = now()
	`, cameraID, userID, value)
	if err != nil {
		return nil, fmt.Errorf("upsert vote: %w", err)
	}

	upvotes += upDelta
	downvotes += downDelta
	if upvotes < 0 {
		upvotes = 0
	}
	if downvotes < 0 {
		downvotes = 0
	}
	confidence = clampConfidence(0.35 + 0.12*float64(upvotes) - 0.18*float64(downvotes))

	newStatus := status
	now := time.Now().UTC()
	newExpires := expiresAt
	var lastConfirmed *time.Time

	if value == 1 {
		t := now
		lastConfirmed = &t
		newExpires = now.Add(reportTTL)
		maxExpires := createdAt.Add(reportTTLCap)
		if newExpires.After(maxExpires) {
			newExpires = maxExpires
		}
	}

	becameRemoved := false
	if value == -1 && confidence < confidenceFloor && (upvotes+downvotes) >= minVotesForCollapse {
		newStatus = "removed"
		becameRemoved = true
	}

	_, err = tx.Exec(ctx, `
		UPDATE mobile_cameras SET
			upvotes = $2,
			downvotes = $3,
			confidence_score = $4,
			status = $5,
			expires_at = $6,
			last_confirmed_at = COALESCE($7, last_confirmed_at),
			updated_at = now()
		WHERE id = $1
	`, cameraID, upvotes, downvotes, confidence, newStatus, newExpires, lastConfirmed)
	if err != nil {
		return nil, fmt.Errorf("update mobile camera: %w", err)
	}

	// Stats: voter confirmations / reporter drivers_saved / fake reports.
	wasUp := prev != nil && *prev == 1
	nowUp := value == 1
	if nowUp && !wasUp {
		if err := bumpStat(ctx, tx, userID, "confirmations_given", 1); err != nil {
			return nil, err
		}
		if _, _, err := applyReputationEvent(
			ctx,
			tx,
			userID,
			reputationEventKeyCrowdVoteUp(cameraID, userID),
			reputationReasonVote,
			8,
			0,
		); err != nil {
			return nil, err
		}
		if reporterID != userID {
			if err := bumpStat(ctx, tx, reporterID, "drivers_saved", 1); err != nil {
				return nil, err
			}
			reporterStats, err := ensureUserStats(ctx, tx, reporterID)
			if err != nil {
				return nil, err
			}
			if err := evaluateAchievements(ctx, tx, reporterID, reporterStats); err != nil {
				return nil, err
			}
		}
	}
	if wasUp && !nowUp && reporterID != userID {
		if err := bumpStat(ctx, tx, reporterID, "drivers_saved", -1); err != nil {
			return nil, err
		}
	}

	if becameRemoved {
		if err := bumpStat(ctx, tx, reporterID, "fake_reports", 1); err != nil {
			return nil, err
		}
	}

	voterStats, err := ensureUserStats(ctx, tx, userID)
	if err != nil {
		return nil, err
	}
	if err := evaluateAchievements(ctx, tx, userID, voterStats); err != nil {
		return nil, err
	}

	return loadReportResult(ctx, tx, cameraID, allowMergeOwn)
}

func loadReportResult(ctx context.Context, tx pgx.Tx, id int64, merged bool) (*ReportResult, error) {
	var out ReportResult
	err := tx.QueryRow(ctx, `
		SELECT id, ST_Y(location::geometry), ST_X(location::geometry),
		       region_code, status, confidence_score, upvotes, downvotes, expires_at
		FROM mobile_cameras
		WHERE id = $1
	`, id).Scan(
		&out.ID, &out.Lat, &out.Lon, &out.RegionCode, &out.Status,
		&out.ConfidenceScore, &out.Upvotes, &out.Downvotes, &out.ExpiresAt,
	)
	if err != nil {
		return nil, fmt.Errorf("load report result: %w", err)
	}
	out.Merged = merged
	out.Source = "crowd"
	return &out, nil
}

func clampConfidence(v float64) float64 {
	return math.Max(0, math.Min(1, v))
}

func bumpStat(ctx context.Context, tx pgx.Tx, userID uuid.UUID, column string, delta int) error {
	allowed := map[string]bool{
		"reports_submitted":        true,
		"confirmations_given":      true,
		"drivers_saved":            true,
		"fake_reports":             true,
		"live_reports_submitted":   true,
		"live_confirmations_given": true,
		"live_drivers_saved":       true,
		"night_reports_submitted":  true,
	}
	if !allowed[column] {
		return fmt.Errorf("invalid stats column %s", column)
	}
	q := fmt.Sprintf(`
		INSERT INTO user_stats (user_id, %s, updated_at)
		VALUES ($1, GREATEST($2, 0), now())
		ON CONFLICT (user_id) DO UPDATE SET
			%s = GREATEST(user_stats.%s + $2, 0),
			updated_at = now()
	`, column, column, column)
	if _, err := tx.Exec(ctx, q, userID, delta); err != nil {
		return fmt.Errorf("bump %s: %w", column, err)
	}
	return nil
}

func ensureReporterAllowed(ctx context.Context, tx pgx.Tx, userID uuid.UUID) error {
	var recentFakes int
	err := tx.QueryRow(ctx, `
		SELECT COUNT(*)::INT
		FROM mobile_cameras
		WHERE reporter_id = $1
		  AND status = 'removed'
		  AND updated_at > now() - ($2 * interval '1 second')
	`, userID, fakeReportBanWindow.Seconds()).Scan(&recentFakes)
	if err != nil {
		return fmt.Errorf("check fake reports: %w", err)
	}
	if recentFakes >= fakeReportBanThreshold {
		return ErrReportBanned
	}
	return nil
}

func checkReportRateLimit(ctx context.Context, tx pgx.Tx, userID uuid.UUID) error {
	var n int
	err := tx.QueryRow(ctx, `
		SELECT COUNT(*)::INT
		FROM mobile_cameras
		WHERE reporter_id = $1
		  AND created_at > now() - ($2 * interval '1 second')
	`, userID, reportRateLimitWindow.Seconds()).Scan(&n)
	if err != nil {
		return fmt.Errorf("report rate limit: %w", err)
	}
	if n >= reportRateLimitCount {
		return ErrReportRateLimited
	}
	return nil
}

func checkVoteRateLimit(ctx context.Context, tx pgx.Tx, userID uuid.UUID) error {
	var n int
	err := tx.QueryRow(ctx, `
		SELECT COUNT(*)::INT
		FROM mobile_camera_votes
		WHERE user_id = $1
		  AND updated_at > now() - ($2 * interval '1 second')
	`, userID, voteRateLimitWindow.Seconds()).Scan(&n)
	if err != nil {
		return fmt.Errorf("vote rate limit: %w", err)
	}
	if n >= voteRateLimitCount {
		return ErrVoteRateLimited
	}
	return nil
}
