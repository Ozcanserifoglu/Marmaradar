package handler

import (
	"net/http"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type StatsHandler struct {
	stats *service.StatsService
}

func NewStatsHandler(stats *service.StatsService) *StatsHandler {
	return &StatsHandler{stats: stats}
}

func (h *StatsHandler) Me(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	result, err := h.stats.GetMe(r.Context(), userID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}
