package normalize

type CorridorRecord struct {
	ExternalID  string
	Name        string
	RegionCode  string
	MaxspeedKmh int16
	LengthM     float64
	Direction   string
	Gates       []CorridorGate
	SourceTags  map[string]string
}

type CorridorGate struct {
	GateType     string
	Lat          float64
	Lon          float64
	RadiusM      float32
	Sequence     int16
	DirectionDeg *int16
}
