package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type ReportHandler struct {
	reports *service.ReportService
}

func NewReportHandler(reports *service.ReportService) *ReportHandler {
	return &ReportHandler{reports: reports}
}

func (h *ReportHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.CreateReportInput
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	result, err := h.reports.Create(r.Context(), userID, body)
	if err != nil {
		writeReportError(w, err)
		return
	}
	status := http.StatusCreated
	if result.Merged {
		status = http.StatusOK
	}
	writeJSON(w, status, result)
}

func (h *ReportHandler) Vote(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	idStr := chi.URLParam(r, "id")
	cameraID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil || cameraID <= 0 {
		writeBadRequest(w, "invalid report id")
		return
	}

	var body service.VoteInput
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	result, err := h.reports.Vote(r.Context(), userID, cameraID, body)
	if err != nil {
		writeReportError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func writeReportError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrInvalidReport),
		errors.Is(err, service.ErrInvalidVoteValue):
		writeBadRequest(w, err.Error())
	case errors.Is(err, service.ErrReportNotFound):
		writeJSON(w, http.StatusNotFound, map[string]string{"error": err.Error()})
	case errors.Is(err, service.ErrReportInactive),
		errors.Is(err, service.ErrTooFarToVote),
		errors.Is(err, service.ErrCannotVoteOwn):
		writeJSON(w, http.StatusConflict, map[string]string{"error": err.Error()})
	case errors.Is(err, service.ErrReportRateLimited),
		errors.Is(err, service.ErrVoteRateLimited):
		writeJSON(w, http.StatusTooManyRequests, map[string]string{"error": err.Error()})
	case errors.Is(err, service.ErrReportBanned):
		writeJSON(w, http.StatusForbidden, map[string]string{"error": err.Error()})
	default:
		writeError(w, err)
	}
}
