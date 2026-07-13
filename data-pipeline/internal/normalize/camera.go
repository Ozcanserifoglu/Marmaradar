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
