package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type DriveHandler struct {
	drives *service.DriveService
}

func NewDriveHandler(drives *service.DriveService) *DriveHandler {
	return &DriveHandler{drives: drives}
}

func (h *DriveHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.CreateDriveInput
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	result, err := h.drives.Create(r.Context(), userID, body)
	if err != nil {
		writeDriveError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, result)
}

func writeDriveError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrTooFewPoints),
		errors.Is(err, service.ErrTooManyPoints),
		errors.Is(err, service.ErrInvalidDrive),
		strings.Contains(err.Error(), "ended_at"),
		strings.Contains(err.Error(), "coordinates"):
		writeBadRequest(w, err.Error())
	default:
		writeError(w, err)
	}
}
