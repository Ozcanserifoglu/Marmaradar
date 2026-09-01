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
	// Public path to the avatar on the gateway, e.g. `/v1/uploads/avatars/{id}.jpg`. Null if no photo uploaded.
	ProfilePictureURL *string `json:"profile_picture_url" example:"/v1/uploads/avatars/550e8400-e29b-41d4-a716-446655440000.jpg"`
	// Vehicle body style used for the map marker and drive video export.
	VehicleType string `json:"vehicle_type" example:"sedan" enums:"sedan,hatchback,station_wagon,kamyon,tir"`
	// Hex color for the vehicle icon (`#RRGGBB`).
	VehicleColor string `json:"vehicle_color" example:"#1E88E5"`
}

// UpdatePreferencesRequest partially updates vehicle map-marker settings.
// Send only the fields you want to change; omitted fields are left unchanged.
type UpdatePreferencesRequest struct {
	// One of: `sedan`, `hatchback`, `station_wagon`, `kamyon`, `tir`.
	VehicleType *string `json:"vehicle_type" example:"sedan"`
	// Six-digit hex color with leading `#`, e.g. `#E8262D`.
	VehicleColor *string `json:"vehicle_color" example:"#1E88E5"`
}
