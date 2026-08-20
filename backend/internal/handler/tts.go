package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

type TTSHandler struct {
	tts *service.TTSService
}

func NewTTSHandler(tts *service.TTSService) *TTSHandler {
	return &TTSHandler{tts: tts}
}

func (h *TTSHandler) Speak(w http.ResponseWriter, r *http.Request) {
	if _, ok := auth.UserIDFromContext(r.Context()); !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.SpeakRequest
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	result, err := h.tts.Speak(r.Context(), body)
	if err != nil {
		writeTTSError(w, err)
		return
	}

	cacheStatus := "MISS"
	if result.CacheHit {
		cacheStatus = "HIT"
	}
	w.Header().Set("Content-Type", "audio/mpeg")
	w.Header().Set("X-TTS-Cache", cacheStatus)
	w.Header().Set("ETag", `"`+result.CacheKey+`"`)
	w.Header().Set("Cache-Control", "private, max-age=86400")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(result.Audio)
}

func (h *TTSHandler) Catalog(w http.ResponseWriter, r *http.Request) {
	if _, ok := auth.UserIDFromContext(r.Context()); !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}
	if !h.tts.Enabled() {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "tts unavailable"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"entries": h.tts.Catalog(),
	})
}

func writeTTSError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrTTSUnavailable):
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "tts unavailable"})
	case errors.Is(err, service.ErrTTSUnknownPhrase),
		errors.Is(err, service.ErrTTSInvalidParams):
		writeBadRequest(w, err.Error())
	default:
		writeError(w, err)
	}
}
