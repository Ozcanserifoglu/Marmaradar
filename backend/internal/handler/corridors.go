package handler

import (
	"net/http"
	"strconv"

	"github.com/radar-alert/backend/internal/model"
	"github.com/radar-alert/backend/internal/service"
)

type CorridorHandler struct {
	geo *service.GeoService
}

func NewCorridorHandler(geo *service.GeoService) *CorridorHandler {
	return &CorridorHandler{geo: geo}
}

func (h *CorridorHandler) Nearby(w http.ResponseWriter, r *http.Request) {
	lat, err := strconv.ParseFloat(r.URL.Query().Get("lat"), 64)
	if err != nil {
		writeBadRequest(w, "lat is required")
		return
	}
	lon, err := strconv.ParseFloat(r.URL.Query().Get("lon"), 64)
	if err != nil {
		writeBadRequest(w, "lon is required")
		return
	}
	region := r.URL.Query().Get("region")
	if region == "" {
		region = "bursa"
	}

	corridors, err := h.geo.NearbyCorridors(r.Context(), lat, lon, region)
	if err != nil {
		writeError(w, err)
		return
	}
	if corridors == nil {
		corridors = []model.Corridor{}
	}
	writeJSON(w, http.StatusOK, corridors)
}
