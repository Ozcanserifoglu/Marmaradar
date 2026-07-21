package roads

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestClientEnabled(t *testing.T) {
	if NewClient("").Enabled() {
		t.Fatal("empty key should disable client")
	}
	if !NewClient("abc").Enabled() {
		t.Fatal("non-empty key should enable client")
	}
}

func TestSnapToRoadsSinglePage(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("interpolate") != "true" {
			t.Errorf("expected interpolate=true, got %q", r.URL.Query().Get("interpolate"))
		}
		if got := r.URL.Query().Get("key"); got != "test-key" {
			t.Errorf("key = %q", got)
		}
		_ = json.NewEncoder(w).Encode(map[string]any{
			"snappedPoints": []map[string]any{
				{
					"location":      map[string]float64{"latitude": 40.0, "longitude": 29.0},
					"originalIndex": 0,
				},
				{
					"location": map[string]float64{"latitude": 40.001, "longitude": 29.001},
				},
				{
					"location":      map[string]float64{"latitude": 40.002, "longitude": 29.002},
					"originalIndex": 1,
				},
			},
		})
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.endpoint = srv.URL

	out, err := c.SnapToRoads(context.Background(), []LatLng{
		{Lat: 40, Lon: 29},
		{Lat: 40.002, Lon: 29.002},
	})
	if err != nil {
		t.Fatalf("SnapToRoads: %v", err)
	}
	if len(out) != 3 {
		t.Fatalf("got %d points, want 3", len(out))
	}
	if out[0].Lat != 40.0 || out[2].Lon != 29.002 {
		t.Fatalf("unexpected coords: %+v", out)
	}
}

func TestSnapToRoadsMissingKey(t *testing.T) {
	c := NewClient("")
	_, err := c.SnapToRoads(context.Background(), []LatLng{
		{Lat: 40, Lon: 29},
		{Lat: 40.002, Lon: 29.002},
	})
	if err == nil {
		t.Fatal("expected error when key missing")
	}
}
