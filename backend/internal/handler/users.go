package handler

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"path"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/service"
)

const maxMultipartMemory = 4 << 20 // 4 MiB

type UsersHandler struct {
	users *service.UsersService
}

func NewUsersHandler(users *service.UsersService) *UsersHandler {
	return &UsersHandler{users: users}
}

// Me godoc
// @Summary      Get my profile
// @Description  Returns the authenticated user's profile including vehicle customization.
// @Tags         Users
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  UserProfileResponse
// @Failure      401  {object}  ErrorResponse
// @Failure      404  {object}  ErrorResponse
// @Failure      500  {object}  ErrorResponse
// @Router       /v1/users/me [get]
func (h *UsersHandler) Me(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	profile, err := h.users.GetProfile(r.Context(), userID)
	if err != nil {
		if errors.Is(err, service.ErrUserNotFound) {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "user not found"})
			return
		}
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

// UpdateMe godoc
// @Summary      Update vehicle preferences
// @Description  Set vehicle type and color used for map markers and drive exports.
// @Tags         Users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      UpdatePreferencesRequest  true  "Vehicle preferences"
// @Success      200   {object}  UserProfileResponse
// @Failure      400   {object}  ErrorResponse
// @Failure      401   {object}  ErrorResponse
// @Failure      404   {object}  ErrorResponse
// @Failure      500   {object}  ErrorResponse
// @Router       /v1/users/me [patch]
func (h *UsersHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	var body service.UpdatePreferencesInput
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeBadRequest(w, "invalid JSON body")
		return
	}

	profile, err := h.users.UpdatePreferences(r.Context(), userID, body)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidVehicleType):
			writeBadRequest(w, "vehicle_type must be one of: sedan, hatchback, station_wagon, kamyon, tir")
		case errors.Is(err, service.ErrInvalidVehicleColor):
			writeBadRequest(w, "vehicle_color must be a #RRGGBB hex color")
		case errors.Is(err, service.ErrUserNotFound):
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "user not found"})
		default:
			writeError(w, err)
		}
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

// UploadProfilePicture godoc
// @Summary      Upload profile picture
// @Description  Upload a JPEG, PNG, or WebP avatar (max 2 MB).
// @Tags         Users
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        file  formData  file  true  "Avatar image"
// @Success      200   {object}  UserProfileResponse
// @Failure      400   {object}  ErrorResponse
// @Failure      401   {object}  ErrorResponse
// @Failure      500   {object}  ErrorResponse
// @Router       /v1/users/me/profile-picture [post]
func (h *UsersHandler) UploadProfilePicture(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	if err := r.ParseMultipartForm(maxMultipartMemory); err != nil {
		writeBadRequest(w, "invalid multipart form")
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		writeBadRequest(w, "file field is required")
		return
	}
	defer file.Close()

	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	// Prefer extension sniff when client sends a generic type.
	if contentType == "application/octet-stream" || contentType == "binary/octet-stream" {
		name := strings.ToLower(header.Filename)
		switch {
		case strings.HasSuffix(name, ".jpg"), strings.HasSuffix(name, ".jpeg"):
			contentType = "image/jpeg"
		case strings.HasSuffix(name, ".png"):
			contentType = "image/png"
		case strings.HasSuffix(name, ".webp"):
			contentType = "image/webp"
		}
	}

	profile, err := h.users.SaveProfilePicture(r.Context(), userID, file, contentType, header.Size)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidImageType):
			writeBadRequest(w, "file must be jpeg, png, or webp")
		case errors.Is(err, service.ErrImageTooLarge):
			writeBadRequest(w, "file must be at most 2MB")
		default:
			writeError(w, err)
		}
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (h *UsersHandler) ServeUpload(w http.ResponseWriter, r *http.Request) {
	key := chi.URLParam(r, "*")
	key = path.Clean("/" + strings.TrimPrefix(key, "/"))
	key = strings.TrimPrefix(key, "/")
	if key == "" || key == "." {
		http.NotFound(w, r)
		return
	}

	body, contentType, err := h.users.OpenUpload(r.Context(), key)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer body.Close()

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "public, max-age=86400")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, body)
}
