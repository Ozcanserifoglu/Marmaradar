package service

import (
	"context"
	"encoding/json"
	"math"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"github.com/radar-alert/backend/internal/client/places"
)

func TestAmenityCellIndexes(t *testing.T) {
	latIdx, lonIdx := AmenityCellIndexes(40.21, 29.05)
	wantLat := int(math.Floor(40.21 / amenityCellDeg))
	wantLon := int(math.Floor(29.05 / amenityCellDeg))
	if latIdx != wantLat || lonIdx != wantLon {
		t.Fatalf("got %d,%d want %d,%d", latIdx, lonIdx, wantLat, wantLon)
	}
}

func TestAmenitiesCellsCacheHit(t *testing.T) {
	var calls atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		_ = r
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"status": "OK",
			"results": []map[string]any{
				{
					"place_id": "p1",
					"name":     "Petrol",
					"types":    []string{"gas_station"},
					"geometry": map[string]any{
						"location": map[string]any{"lat": 40.21, "lng": 29.05},
					},
				},
			},
		})
	}))
	defer srv.Close()

	client := places.NewClient("test-key")
	client.SetHTTPForTest(srv.URL, srv.Client())

	svc := NewAmenitiesService(client)
	latIdx, lonIdx := AmenityCellIndexes(40.21, 29.05)
	req := AmenitiesRequest{
		Cells: []AmenityCellRef{{LatIndex: latIdx, LonIndex: lonIdx}},
		Types: []string{"gas_station"},
	}

	first, err := svc.Cells(context.Background(), req)
	if err != nil {
		t.Fatalf("first Cells: %v", err)
	}
	if len(first) != 1 || first[0].PlaceID != "p1" {
		t.Fatalf("unexpected first result: %+v", first)
	}

	second, err := svc.Cells(context.Background(), req)
	if err != nil {
		t.Fatalf("second Cells: %v", err)
	}
	if len(second) != 1 {
		t.Fatalf("want cached 1 place, got %d", len(second))
	}
	if calls.Load() != 1 {
		t.Fatalf("want 1 google call (cache hit), got %d", calls.Load())
	}
}

func TestAmenitiesRejectsTooManyCells(t *testing.T) {
	svc := NewAmenitiesService(places.NewClient("key"))
	cells := make([]AmenityCellRef, amenityMaxCells+1)
	_, err := svc.Cells(context.Background(), AmenitiesRequest{Cells: cells})
	if err != ErrAmenitiesTooMany {
		t.Fatalf("want ErrAmenitiesTooMany, got %v", err)
	}
}
