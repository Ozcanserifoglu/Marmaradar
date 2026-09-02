package handler

// ErrorResponse is returned when a request cannot be completed.
type ErrorResponse struct {
	// Human-readable explanation suitable to show in a client UI.
	Error string `json:"error" example:"invalid JSON body"`
}

// UserProfileResponse is the signed-in user's account and customization settings.
type UserProfileResponse struct {
	// Marmaradar user UUID.
	ID string `json:"id" example:"550e8400-e29b-41d4-a716-446655440000"`
	// Account email address.
	Email string `json:"email" example:"driver@example.com"`
	// Public display name for leaderboards. Null until the user sets one.
	Username *string `json:"username" example:"ozcan_driver"`
	// Public path to the avatar on the gateway, e.g. `/v1/uploads/avatars/{id}.jpg`. Null if no photo uploaded.
	ProfilePictureURL *string `json:"profile_picture_url" example:"/v1/uploads/avatars/550e8400-e29b-41d4-a716-446655440000.jpg"`
	// Vehicle body style used for the map marker and drive video export.
	VehicleType string `json:"vehicle_type" example:"sedan" enums:"sedan,hatchback,station_wagon,kamyon,tir"`
	// Hex color for the vehicle icon (`#RRGGBB`).
	VehicleColor string `json:"vehicle_color" example:"#1E88E5"`
}

// UpdatePreferencesRequest partially updates vehicle map-marker settings and username.
// Send only the fields you want to change; omitted fields are left unchanged.
type UpdatePreferencesRequest struct {
	// Unique public username: lowercase letters, digits, underscore; 3–20 chars.
	Username *string `json:"username" example:"ozcan_driver"`
	// One of: `sedan`, `hatchback`, `station_wagon`, `kamyon`, `tir`.
	VehicleType *string `json:"vehicle_type" example:"sedan"`
	// Six-digit hex color with leading `#`, e.g. `#E8262D`.
	VehicleColor *string `json:"vehicle_color" example:"#1E88E5"`
}

// LeaderboardEntry is one ranked user on a leaderboard category.
type LeaderboardEntry struct {
	Rank              int     `json:"rank" example:"1"`
	UserID            string  `json:"user_id" example:"550e8400-e29b-41d4-a716-446655440000"`
	Username          string  `json:"username" example:"ozc***"`
	ProfilePictureURL *string `json:"profile_picture_url" example:"/v1/uploads/avatars/550e8400-e29b-41d4-a716-446655440000.jpg"`
	VehicleType       string  `json:"vehicle_type" example:"sedan" enums:"sedan,hatchback,station_wagon,kamyon,tir"`
	VehicleColor      string  `json:"vehicle_color" example:"#E8262D"`
	// Meters for category=distance; contribution count for category=reports.
	Value float64 `json:"value" example:"152340.5"`
}

// LeaderboardMeEntry is the caller's row, always present even outside the top 100.
type LeaderboardMeEntry struct {
	Rank              int     `json:"rank" example:"142"`
	UserID            string  `json:"user_id" example:"550e8400-e29b-41d4-a716-446655440000"`
	Username          string  `json:"username" example:"driver_one"`
	ProfilePictureURL *string `json:"profile_picture_url"`
	VehicleType       string  `json:"vehicle_type" example:"hatchback"`
	VehicleColor      string  `json:"vehicle_color" example:"#1E88E5"`
	Value             float64 `json:"value" example:"8200"`
	// True when the caller appears in entries.
	InTop bool `json:"in_top" example:"false"`
}

// LeaderboardResponse is the dual-category leaderboard payload.
type LeaderboardResponse struct {
	Category string             `json:"category" example:"distance" enums:"distance,reports"`
	Entries  []LeaderboardEntry `json:"entries"`
	Me       LeaderboardMeEntry `json:"me"`
}
