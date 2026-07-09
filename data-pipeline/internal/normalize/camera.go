package normalize

import (
	"strconv"
	"strings"
)

type CameraRecord struct {
	ExternalID    string
	RegionCode    string
	Lat           float64
	Lon           float64
	RoadName      string
	MaxspeedKmh   *int16
	DirectionDeg  *int16
	CameraType    string
	Active        bool
	SourceTags    map[string]string
	Confidence    float32
}

func CameraTypeFromTags(tags map[string]string) string {
	if t := tags["camera:type"]; t != "" {
		return t
	}
	return "fixed"
}

func ParseMaxspeed(tags map[string]string) *int16 {
	raw := tags["maxspeed"]
	if raw == "" {
		return nil
	}
	raw = strings.TrimSuffix(strings.TrimSpace(raw), " km/h")
	v, err := strconv.Atoi(raw)
	if err != nil {
		return nil
	}
	i := int16(v)
	return &i
}

func RegionForPoint(lat, lon float64) string {
	if lat >= 39.95 && lat <= 40.55 && lon >= 28.75 && lon <= 29.55 {
		return "bursa"
	}
	if lat >= 40.8 && lat <= 41.35 && lon >= 28.4 && lon <= 29.5 {
		return "istanbul"
	}
	return "marmara"
}
