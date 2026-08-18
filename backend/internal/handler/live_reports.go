package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type LiveReportHandler struct {
	reports *service.LiveReportService
}

func NewLiveReportHandler(reports *service.LiveReportService) *LiveReportHandler {
	return &LiveReportHandler{reports: reports}
}

func (h *LiveReportHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.CreateLiveReportInput
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	result, err := h.reports.Create(r.Context(), userID, body)
	if err != nil {
		if errors.Is(err, service.ErrInvalidLiveReport) {
			writeBadRequest(w, err.Error())
			return
		}
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, result)
}

func (h *LiveReportHandler) Active(w http.ResponseWriter, r *http.Request) {
	reports, err := h.reports.ListActive(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, reports)
}
