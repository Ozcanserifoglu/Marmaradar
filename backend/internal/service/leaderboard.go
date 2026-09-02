package service

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	LeaderboardCategoryDistance = "distance"
	LeaderboardCategoryReports  = "reports"
	leaderboardTopLimit         = 100
)

var ErrInvalidLeaderboardCategory = errors.New("invalid leaderboard category")

type LeaderboardEntry struct {
	Rank              int
	UserID            string
	Username          string
	ProfilePictureURL *string
	VehicleType       string
	VehicleColor      string
	Value             float64
}

type LeaderboardMe struct {
	Rank              int
	UserID            string
	Username          string
	ProfilePictureURL *string
	VehicleType       string
	VehicleColor      string
	Value             float64
	InTop             bool
}

type LeaderboardResult struct {
	Category string
	Entries  []LeaderboardEntry
	Me       LeaderboardMe
}

type LeaderboardService struct {
	pool *pgxpool.Pool
}

func NewLeaderboardService(pool *pgxpool.Pool) *LeaderboardService {
	return &LeaderboardService{pool: pool}
}

func (s *LeaderboardService) Get(ctx context.Context, userID uuid.UUID, category string) (*LeaderboardResult, error) {
	metricCol, err := leaderboardMetricColumn(category)
	if err != nil {
		return nil, err
	}

	entries, err := s.topEntries(ctx, metricCol)
	if err != nil {
		return nil, err
	}

	me, err := s.meEntry(ctx, userID, metricCol, entries)
	if err != nil {
		return nil, err
	}

	if entries == nil {
		entries = make([]LeaderboardEntry, 0)
	}

	return &LeaderboardResult{
		Category: category,
		Entries:  entries,
		Me:       me,
	}, nil
}

func leaderboardMetricColumn(category string) (string, error) {
	switch category {
	case LeaderboardCategoryDistance:
		return "total_distance_m", nil
	case LeaderboardCategoryReports:
		return "valid_contributions", nil
	default:
		return "", ErrInvalidLeaderboardCategory
	}
}

func (s *LeaderboardService) topEntries(ctx context.Context, metricCol string) ([]LeaderboardEntry, error) {
	// metricCol is allowlisted via leaderboardMetricColumn.
	q := fmt.Sprintf(`
		SELECT u.id::text,
		       u.username,
		       u.email,
		       u.profile_picture_url,
		       u.vehicle_type,
		       u.vehicle_color,
		       us.%s::float8 AS value
		FROM user_stats us
		JOIN users u ON u.id = us.user_id
		WHERE us.%s > 0
		ORDER BY us.%s DESC, us.user_id ASC
		LIMIT $1
	`, metricCol, metricCol, metricCol)

	rows, err := s.pool.Query(ctx, q, leaderboardTopLimit)
	if err != nil {
		return nil, fmt.Errorf("query leaderboard top: %w", err)
	}
	defer rows.Close()

	entries := make([]LeaderboardEntry, 0, leaderboardTopLimit)
	rank := 0
	for rows.Next() {
		rank++
		var (
			id                string
			username          *string
			email             string
			profilePictureURL *string
			vehicleType       string
			vehicleColor      string
			value             float64
		)
		if err := rows.Scan(
			&id, &username, &email, &profilePictureURL, &vehicleType, &vehicleColor, &value,
		); err != nil {
			return nil, fmt.Errorf("scan leaderboard row: %w", err)
		}
		entries = append(entries, LeaderboardEntry{
			Rank:              rank,
			UserID:            id,
			Username:          DisplayUsername(username, email),
			ProfilePictureURL: profilePictureURL,
			VehicleType:       vehicleType,
			VehicleColor:      vehicleColor,
			Value:             value,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate leaderboard: %w", err)
	}
	return entries, nil
}

func (s *LeaderboardService) meEntry(
	ctx context.Context,
	userID uuid.UUID,
	metricCol string,
	entries []LeaderboardEntry,
) (LeaderboardMe, error) {
	var (
		username          *string
		email             string
		profilePictureURL *string
		vehicleType       string
		vehicleColor      string
		value             float64
	)

	err := s.pool.QueryRow(ctx, fmt.Sprintf(`
		SELECT u.username, u.email, u.profile_picture_url, u.vehicle_type, u.vehicle_color,
		       COALESCE(us.%s, 0)::float8
		FROM users u
		LEFT JOIN user_stats us ON us.user_id = u.id
		WHERE u.id = $1
	`, metricCol), userID).Scan(&username, &email, &profilePictureURL, &vehicleType, &vehicleColor, &value)
	if errors.Is(err, pgx.ErrNoRows) {
		return LeaderboardMe{}, ErrUserNotFound
	}
	if err != nil {
		return LeaderboardMe{}, fmt.Errorf("load leaderboard me profile: %w", err)
	}

	rank, err := s.rankFor(ctx, userID, metricCol, value)
	if err != nil {
		return LeaderboardMe{}, err
	}

	inTop := false
	uid := userID.String()
	for _, e := range entries {
		if e.UserID == uid {
			inTop = true
			rank = e.Rank
			break
		}
	}

	return LeaderboardMe{
		Rank:              rank,
		UserID:            uid,
		Username:          DisplayUsername(username, email),
		ProfilePictureURL: profilePictureURL,
		VehicleType:       vehicleType,
		VehicleColor:      vehicleColor,
		Value:             value,
		InTop:             inTop,
	}, nil
}

func (s *LeaderboardService) rankFor(
	ctx context.Context,
	userID uuid.UUID,
	metricCol string,
	myValue float64,
) (int, error) {
	if myValue <= 0 {
		// Users with no score share the last place after everyone with a score.
		var scored int
		q := fmt.Sprintf(`
			SELECT COUNT(*)::INT
			FROM user_stats
			WHERE %s > 0
		`, metricCol)
		if err := s.pool.QueryRow(ctx, q).Scan(&scored); err != nil {
			return 0, fmt.Errorf("count scored users: %w", err)
		}
		return scored + 1, nil
	}

	var ahead int
	q := fmt.Sprintf(`
		SELECT COUNT(*)::INT
		FROM user_stats
		WHERE %s > $1
		   OR (%s = $1 AND user_id < $2)
	`, metricCol, metricCol)
	if err := s.pool.QueryRow(ctx, q, myValue, userID).Scan(&ahead); err != nil {
		return 0, fmt.Errorf("compute leaderboard rank: %w", err)
	}
	return ahead + 1, nil
}
