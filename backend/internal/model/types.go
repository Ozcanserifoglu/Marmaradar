package model

import "time"

type Camera struct {
	ID                    int64   `json:"id"`
	Lat                   float64 `json:"lat"`
	Lon                   float64 `json:"lon"`
	MaxspeedKmh           *int16  `json:"maxspeed_kmh,omitempty"`
	DirectionDeg          *int16  `json:"direction_deg,omitempty"`
	DirectionToleranceDeg int16   `json:"direction_tolerance_deg"`
	DistanceM             float64 `json:"distance_m"`
	RoadName              *string `json:"road_name,omitempty"`
	CameraType            string  `json:"camera_type"`
	RegionCode            string  `json:"region_code"`
}

type CorridorGate struct {
	ID           int64   `json:"id"`
	GateType     string  `json:"gate_type"`
	Lat          float64 `json:"lat"`
	Lon          float64 `json:"lon"`
	RadiusM      float32 `json:"radius_m"`
	Sequence     int16   `json:"sequence"`
	DirectionDeg *int16  `json:"direction_deg,omitempty"`
}

type Corridor struct {
	ID          int64   `json:"id"`
	ExternalID  *string `json:"external_id,omitempty"`
	Name        string  `json:"name"`
	MaxspeedKmh int16   `json:"maxspeed_kmh"`
	LengthM     float64 `json:"length_m"`
	Direction   string  `json:"direction"`
	RegionCode  string  `json:"region_code"`
	// Road-following geometry as a Google encoded polyline (precision 5),
	// nil when the corridor has not been enriched with route geometry yet.
	Polyline *string        `json:"polyline,omitempty"`
	Gates    []CorridorGate `json:"gates"`
}

type SyncPayload struct {
	Cameras    []Camera   `json:"cameras"`
	Corridors  []Corridor `json:"corridors"`
	Since      *time.Time `json:"since,omitempty"`
	ServerTime time.Time  `json:"server_time"`
}
