package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type AmenitiesHandler struct {
	amenities *service.AmenitiesService
}

func NewAmenitiesHandler(amenities *service.AmenitiesService) *AmenitiesHandler {
	return &AmenitiesHandler{amenities: amenities}
}

func (h *AmenitiesHandler) Cells(w http.ResponseWriter, r *http.Request) {
	if _, ok := auth.UserIDFromContext(r.Context()); !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.AmenitiesRequest
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	results, err := h.amenities.Cells(r.Context(), body)
	if err != nil {
		writeAmenitiesError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, results)
}

func writeAmenitiesError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrAmenitiesUnavailable):
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "amenities unavailable"})
	case errors.Is(err, service.ErrAmenitiesNoCells),
		errors.Is(err, service.ErrAmenitiesTooMany),
		errors.Is(err, service.ErrAmenitiesInvalidCell),
		errors.Is(err, service.ErrAmenitiesInvalidType):
		writeBadRequest(w, err.Error())
	default:
		writeError(w, err)
	}
}
