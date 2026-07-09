package handler

import (
	"net/http"
	"time"

	"github.com/radar-alert/backend/internal/service"
)

type SyncHandler struct {
	geo *service.GeoService
}

func NewSyncHandler(geo *service.GeoService) *SyncHandler {
	return &SyncHandler{geo: geo}
}

func (h *SyncHandler) Delta(w http.ResponseWriter, r *http.Request) {
	region := r.URL.Query().Get("region")
	if region == "" {
		region = "bursa"
	}
	bbox := r.URL.Query().Get("bbox")
	if bbox == "" {
		writeBadRequest(w, "bbox is required (west,south,east,north)")
		return
	}

	var since *time.Time
	if sinceStr := r.URL.Query().Get("since"); sinceStr != "" {
		t, err := time.Parse(time.RFC3339, sinceStr)
		if err != nil {
			writeBadRequest(w, "since must be RFC3339")
			return
		}
		since = &t
	}

	payload, err := h.geo.SyncDelta(r.Context(), region, bbox, since)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, payload)
}
