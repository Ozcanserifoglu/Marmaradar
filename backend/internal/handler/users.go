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
// @Summary      View my account and saved preferences
// @Description  ## What this does
// @Description  Returns everything Marmaradar knows about the **currently signed-in user**: email, profile photo URL, and vehicle customization used on the map and in drive videos.
// @Description
// @Description  ## When to call
// @Description  - After login, to hydrate the profile screen.
// @Description  - On app launch, to sync vehicle icon settings from the server.
// @Description
// @Description  ## Response notes
// @Description  - `profile_picture_url` is a **relative path** on the gateway (e.g. `/v1/uploads/avatars/{user-id}.jpg`). Prepend your gateway base URL to display the image.
// @Description  - If the user has never uploaded a photo, `profile_picture_url` is `null`.
// @Description  - `username` is `null` until set via `PATCH /v1/users/me`. On public leaderboards, unset usernames are shown as a masked email local-part.
// @Tags         Account & Profile
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  UserProfileResponse  "Current profile"
// @Failure      401  {object}  ErrorResponse        "Missing or expired access token"
// @Failure      404  {object}  ErrorResponse        "User record no longer exists"
// @Failure      500  {object}  ErrorResponse        "Unexpected server error"
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
// @Summary      Change my username or vehicle icon on the map
// @Description  ## What this does
// @Description  Updates the **username**, **vehicle type**, and/or **color**. Vehicle settings are used as your position marker during live tracking and in exported drive videos. Username appears on public leaderboards.
// @Description
// @Description  ## Partial updates
// @Description  Send only the fields you want to change. Omitted keys are left as-is on the server.
// @Description
// @Description  ```json
// @Description  { "username": "ozcan_driver", "vehicle_type": "hatchback", "vehicle_color": "#E8262D" }
// @Description  ```
// @Description
// @Description  ## Allowed values
// @Description  | Field | Constraints |
// @Description  |-------|-------------|
// @Description  | `username` | lowercase `a-z`, `0-9`, `_`; length 3–20; unique |
// @Description  | `vehicle_type` | `sedan`, `hatchback`, `station_wagon`, `kamyon`, or `tir` |
// @Description  | `vehicle_color` | `#` followed by six hex digits, e.g. `#1E88E5` |
// @Description
// @Description  Unknown JSON keys are rejected with **400 Bad Request**.
// @Tags         Vehicle Customization
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      UpdatePreferencesRequest  true  "Fields to update (partial OK)"
// @Success      200   {object}  UserProfileResponse       "Profile after update"
// @Failure      400   {object}  ErrorResponse             "Invalid username, vehicle_type, vehicle_color, or JSON"
// @Failure      401   {object}  ErrorResponse             "Missing or expired access token"
// @Failure      404   {object}  ErrorResponse             "User record no longer exists"
// @Failure      409   {object}  ErrorResponse             "Username already taken"
// @Failure      500   {object}  ErrorResponse             "Unexpected server error"
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
		case errors.Is(err, service.ErrInvalidUsername):
			writeBadRequest(w, "username must be 3–20 chars: lowercase letters, digits, underscore")
		case errors.Is(err, service.ErrUsernameTaken):
			writeJSON(w, http.StatusConflict, map[string]string{"error": "username already taken"})
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
// @Summary      Upload or replace my profile photo
// @Description  ## What this does
// @Description  Stores a new avatar for the signed-in user. The previous image file is deleted automatically when replaced.
// @Description
// @Description  ## How to send
// @Description  Use `multipart/form-data` with a single field named **`file`** containing the image bytes.
// @Description
// @Description  ## File rules
// @Description  | Rule | Value |
// @Description  |------|-------|
// @Description  | Formats | JPEG, PNG, or WebP |
// @Description  | Max size | 2 MB |
// @Description  | Field name | `file` (required) |
// @Description
// @Description  ## Response
// @Description  Returns the updated profile. The new `profile_picture_url` points to `GET /v1/uploads/avatars/{user-id}.{ext}` on the gateway — no auth required to view avatars.
// @Tags         Profile Photo
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        file  formData  file  true  "Avatar image (JPEG, PNG, or WebP, max 2 MB)"
// @Success      200   {object}  UserProfileResponse  "Profile with new profile_picture_url"
// @Failure      400   {object}  ErrorResponse        "Missing file, unsupported type, or file too large"
// @Failure      401   {object}  ErrorResponse        "Missing or expired access token"
// @Failure      500   {object}  ErrorResponse        "Unexpected server error"
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

// ServeAvatar godoc
// @Summary      Download a user's avatar image
// @Description  ## What this does
// @Description  Serves a publicly cached profile photo previously uploaded via `POST /v1/users/me/profile-picture`.
// @Description
// @Description  ## Path format
// @Description  The `{file}` segment is the stored filename: `{user-uuid}.{jpg|png|webp}` — exactly as returned in `profile_picture_url` after the `/v1/uploads/avatars/` prefix.
// @Description
// @Description  **Example:** `GET /v1/uploads/avatars/550e8400-e29b-41d4-a716-446655440000.jpg`
// @Description
// @Description  ## Caching
// @Description  Responses include `Cache-Control: public, max-age=86400` (24 hours). No authentication required.
// @Tags         Profile Photo
// @Produce      image/jpeg
// @Produce      image/png
// @Param        file  path  string  true  "Avatar filename, e.g. 550e8400-e29b-41d4-a716-446655440000.jpg"
// @Success      200   "Binary image body"
// @Failure      404   "Avatar not found"
// @Router       /v1/uploads/avatars/{file} [get]
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
