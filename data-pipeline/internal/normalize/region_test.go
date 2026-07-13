package normalize

import "testing"

func TestRegionForPoint(t *testing.T) {
	tests := []struct {
		lat, lon float64
		want     string
	}{
		{40.2, 29.0, "bursa"},
		{41.0, 29.0, "istanbul"},
		{39.9, 32.7, "ankara"},
		{38.4, 27.1, "izmir"},
		{40.7, 30.0, "marmara"},
		{37.0, 35.0, "turkey"},
		{36.0, 30.0, "turkey"},
	}
	for _, tc := range tests {
		if got := RegionForPoint(tc.lat, tc.lon); got != tc.want {
			t.Errorf("RegionForPoint(%f,%f) = %q, want %q", tc.lat, tc.lon, got, tc.want)
		}
	}
}

func TestTurkeyBbox(t *testing.T) {
	if TurkeyBbox() != "25.66,35.8,44.8,42.1" {
		t.Fatalf("unexpected turkey bbox: %s", TurkeyBbox())
	}
}
