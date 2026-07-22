package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type EtaHandler struct {
	eta *service.EtaService
}

func NewEtaHandler(eta *service.EtaService) *EtaHandler {
	return &EtaHandler{eta: eta}
}

func (h *EtaHandler) Cameras(w http.ResponseWriter, r *http.Request) {
	if _, ok := auth.UserIDFromContext(r.Context()); !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.EtaRequest
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	results, err := h.eta.CamerasETA(r.Context(), body)
	if err != nil {
		writeEtaError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, results)
}

func writeEtaError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrEtaUnavailable):
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "eta unavailable"})
	case errors.Is(err, service.ErrEtaInvalidOrigin),
		errors.Is(err, service.ErrEtaNoDestinations),
		errors.Is(err, service.ErrEtaTooManyDests),
		errors.Is(err, service.ErrEtaInvalidCameraID):
		writeBadRequest(w, err.Error())
	default:
		writeError(w, err)
	}
}
