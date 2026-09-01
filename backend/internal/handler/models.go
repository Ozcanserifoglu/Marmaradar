package handler

// ErrorResponse is a standard API error payload.
type ErrorResponse struct {
	Error string `json:"error" example:"invalid JSON body"`
}

// UserProfileResponse is the authenticated user's profile.
type UserProfileResponse struct {
	ID                string  `json:"id" example:"550e8400-e29b-41d4-a716-446655440000"`
	Email             string  `json:"email" example:"user@example.com"`
	ProfilePictureURL *string `json:"profile_picture_url" example:"/v1/uploads/avatars/550e8400.jpg"`
	VehicleType       string  `json:"vehicle_type" example:"sedan" enums:"sedan,hatchback,station_wagon,kamyon,tir"`
	VehicleColor      string  `json:"vehicle_color" example:"#1E88E5"`
}

// UpdatePreferencesRequest updates vehicle map marker preferences.
type UpdatePreferencesRequest struct {
	VehicleType  *string `json:"vehicle_type" example:"sedan"`
	VehicleColor *string `json:"vehicle_color" example:"#1E88E5"`
}
