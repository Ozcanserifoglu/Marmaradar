package handler

import (
	"errors"
	"net/http"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type LeaderboardHandler struct {
	leaderboard *service.LeaderboardService
}

func NewLeaderboardHandler(leaderboard *service.LeaderboardService) *LeaderboardHandler {
	return &LeaderboardHandler{leaderboard: leaderboard}
}

// Get godoc
// @Summary      Get distance or community-contribution leaderboard
// @Description  ## What this does
// @Description  Returns the **top 100** users for a lifetime category, plus the **caller's own rank** even when they are outside the top 100.
// @Description
// @Description  ## Categories
// @Description  | `category` | Metric (`value`) |
// @Description  |------------|------------------|
// @Description  | `distance` | Total distance driven in **meters** (`user_stats.total_distance_m`) |
// @Description  | `reports`  | Verified contributions: non-removed mobile radar reports + confirmed live reports |
// @Description
// @Description  ## Enrichment
// @Description  Each entry includes `username` (custom name, or a masked email local-part like `ozc***`), `profile_picture_url`, `vehicle_type`, and `vehicle_color` for rich mobile UI.
// @Description
// @Description  ## Ranking
// @Description  Ordered by metric descending, then `user_id` ascending for stable ties. `me.in_top` is true when the caller appears in `entries`.
// @Tags         Leaderboard
// @Produce      json
// @Security     BearerAuth
// @Param        category  query     string  true  "Leaderboard category"  Enums(distance,reports)
// @Success      200  {object}  LeaderboardResponse  "Top 100 plus caller rank"
// @Failure      400  {object}  ErrorResponse         "Missing or invalid category"
// @Failure      401  {object}  ErrorResponse         "Missing or expired access token"
// @Failure      404  {object}  ErrorResponse         "User record no longer exists"
// @Failure      500  {object}  ErrorResponse         "Unexpected server error"
// @Router       /v1/leaderboard [get]
func (h *LeaderboardHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	category := r.URL.Query().Get("category")
	if category == "" {
		writeBadRequest(w, "category is required (distance or reports)")
		return
	}

	result, err := h.leaderboard.Get(r.Context(), userID, category)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidLeaderboardCategory):
			writeBadRequest(w, "category must be distance or reports")
		case errors.Is(err, service.ErrUserNotFound):
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "user not found"})
		default:
			writeError(w, err)
		}
		return
	}

	entries := make([]LeaderboardEntry, 0, len(result.Entries))
	for _, e := range result.Entries {
		entries = append(entries, LeaderboardEntry{
			Rank:              e.Rank,
			UserID:            e.UserID,
			Username:          e.Username,
			ProfilePictureURL: e.ProfilePictureURL,
			VehicleType:       e.VehicleType,
			VehicleColor:      e.VehicleColor,
			Value:             e.Value,
		})
	}

	writeJSON(w, http.StatusOK, LeaderboardResponse{
		Category: result.Category,
		Entries:  entries,
		Me: LeaderboardMeEntry{
			Rank:              result.Me.Rank,
			UserID:            result.Me.UserID,
			Username:          result.Me.Username,
			ProfilePictureURL: result.Me.ProfilePictureURL,
			VehicleType:       result.Me.VehicleType,
			VehicleColor:      result.Me.VehicleColor,
			Value:             result.Me.Value,
			InTop:             result.Me.InTop,
		},
	})
}
