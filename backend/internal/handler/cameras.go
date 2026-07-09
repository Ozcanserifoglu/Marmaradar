package handler

import (
	"net/http"
	"strconv"

	"github.com/radar-alert/backend/internal/model"
	"github.com/radar-alert/backend/internal/service"
)

type CameraHandler struct {
	geo *service.GeoService
}

func NewCameraHandler(geo *service.GeoService) *CameraHandler {
	return &CameraHandler{geo: geo}
}

func (h *CameraHandler) Nearby(w http.ResponseWriter, r *http.Request) {
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
	radius, _ := strconv.ParseFloat(r.URL.Query().Get("radius_m"), 64)
	if radius <= 0 || radius > 5000 {
		radius = 1000
	}
	region := r.URL.Query().Get("region")
	if region == "" {
		region = "bursa"
	}

	cameras, err := h.geo.NearbyCameras(r.Context(), lat, lon, radius, region)
	if err != nil {
		writeError(w, err)
		return
	}
	if cameras == nil {
		cameras = []model.Camera{}
	}
	writeJSON(w, http.StatusOK, cameras)
}
