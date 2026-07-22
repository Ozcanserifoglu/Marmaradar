package distancematrix

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestDrivingDistancesOK(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("mode") != "driving" {
			t.Errorf("expected mode=driving")
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"status": "OK",
			"rows": [{
				"elements": [{
					"status": "OK",
					"distance": {"text": "1.2 km", "value": 1234},
					"duration": {"text": "2 dk", "value": 98}
				}]
			}]
		}`))
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.endpoint = srv.URL
	c.httpClient = srv.Client()

	els, err := c.DrivingDistances(context.Background(),
		LatLng{Lat: 40.2, Lon: 29.0},
		[]LatLng{{Lat: 40.21, Lon: 29.01}},
	)
	if err != nil {
		t.Fatalf("DrivingDistances: %v", err)
	}
	if len(els) != 1 {
		t.Fatalf("want 1 element, got %d", len(els))
	}
	if els[0].Status != "OK" || els[0].DistanceM != 1234 || els[0].DurationSec != 98 {
		t.Fatalf("unexpected element: %+v", els[0])
	}
}

func TestDrivingDistancesRejectsTooMany(t *testing.T) {
	c := NewClient("test-key")
	dests := make([]LatLng, maxDestinations+1)
	_, err := c.DrivingDistances(context.Background(), LatLng{Lat: 1, Lon: 1}, dests)
	if err == nil {
		t.Fatal("expected error for too many destinations")
	}
}

func TestDisabledWithoutKey(t *testing.T) {
	c := NewClient("")
	if c.Enabled() {
		t.Fatal("expected disabled without key")
	}
}
