package places

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNearbySearchOK(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("type") != "gas_station" {
			t.Errorf("expected type=gas_station, got %q", r.URL.Query().Get("type"))
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"status": "OK",
			"results": [{
				"place_id": "abc",
				"name": "Shell",
				"types": ["gas_station"],
				"rating": 4.2,
				"geometry": {"location": {"lat": 40.2, "lng": 29.0}},
				"opening_hours": {"open_now": true}
			}]
		}`))
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.endpoint = srv.URL
	c.httpClient = srv.Client()

	places, err := c.NearbySearch(context.Background(), 40.2, 29.0, 1500, "gas_station", "", "gas_station")
	if err != nil {
		t.Fatalf("NearbySearch: %v", err)
	}
	if len(places) != 1 {
		t.Fatalf("want 1 place, got %d", len(places))
	}
	if places[0].PlaceID != "abc" || places[0].Name != "Shell" {
		t.Fatalf("unexpected place: %+v", places[0])
	}
	if places[0].OpenNow == nil || !*places[0].OpenNow {
		t.Fatal("expected open_now true")
	}
	if places[0].Category != "gas_station" {
		t.Fatalf("category = %q", places[0].Category)
	}
}

func TestNearbySearchZeroResults(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ZERO_RESULTS","results":[]}`))
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.endpoint = srv.URL
	c.httpClient = srv.Client()

	places, err := c.NearbySearch(context.Background(), 40.2, 29.0, 1500, "", "dinlenme", "rest_stop")
	if err != nil {
		t.Fatalf("NearbySearch: %v", err)
	}
	if len(places) != 0 {
		t.Fatalf("want 0 places, got %d", len(places))
	}
}

func TestDisabledWithoutKey(t *testing.T) {
	c := NewClient("")
	if c.Enabled() {
		t.Fatal("expected disabled without key")
	}
}
