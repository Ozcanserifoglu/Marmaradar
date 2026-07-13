// Package enrich fills speed_corridors.route_polyline with road-following
// geometry by routing each corridor's entry gate to its exit gate over the
// OSRM road network. Without this, corridors only have two gate points and
// clients can only draw a straight line between them.
package enrich

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

const DefaultOSRMBaseURL = "https://router.project-osrm.org"

// The public OSRM demo server asks for at most ~1 request per second.
const requestInterval = 1200 * time.Millisecond

type osrmResponse struct {
	Code   string `json:"code"`
	Routes []struct {
		Geometry string  `json:"geometry"` // encoded polyline, precision 5
		Distance float64 `json:"distance"` // meters
	} `json:"routes"`
}

type corridorEndpoints struct {
	id                 int64
	name               string
	entryLat, entryLon float64
	exitLat, exitLon   float64
}

// Corridors routes every active corridor that has entry/exit gates through
// OSRM and stores the resulting geometry. Corridors that already have a
// route_polyline are skipped unless force is true. Returns the number of
// corridors updated.
func Corridors(ctx context.Context, pool *pgxpool.Pool, osrmBaseURL string, force bool) (int, error) {
	if osrmBaseURL == "" {
		osrmBaseURL = DefaultOSRMBaseURL
	}

	q := `
		SELECT sc.id, sc.name,
		       ST_Y(e.location::geometry), ST_X(e.location::geometry),
		       ST_Y(x.location::geometry), ST_X(x.location::geometry)
		FROM speed_corridors sc
		JOIN LATERAL (
			SELECT location FROM corridor_gates
			WHERE corridor_id = sc.id AND gate_type = 'entry'
			ORDER BY sequence LIMIT 1
		) e ON true
		JOIN LATERAL (
			SELECT location FROM corridor_gates
			WHERE corridor_id = sc.id AND gate_type = 'exit'
			ORDER BY sequence DESC LIMIT 1
		) x ON true
		WHERE sc.active`
	if !force {
		q += ` AND sc.route_polyline IS NULL`
	}

	rows, err := pool.Query(ctx, q)
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	var corridors []corridorEndpoints
	for rows.Next() {
		var c corridorEndpoints
		if err := rows.Scan(&c.id, &c.name, &c.entryLat, &c.entryLon, &c.exitLat, &c.exitLon); err != nil {
			return 0, err
		}
		corridors = append(corridors, c)
	}
	if err := rows.Err(); err != nil {
		return 0, err
	}

	client := &http.Client{Timeout: 30 * time.Second}
	updated := 0
	for i, c := range corridors {
		if i > 0 {
			time.Sleep(requestInterval)
		}
		polyline, distanceM, err := route(ctx, client, osrmBaseURL, c)
		if err != nil {
			log.Printf("corridor %d (%s): route failed, skipping: %v", c.id, c.name, err)
			continue
		}
		_, err = pool.Exec(ctx, `
			UPDATE speed_corridors
			SET route_polyline = ST_LineFromEncodedPolyline($1)::geography,
			    length_m = $2,
			    updated_at = now()
			WHERE id = $3`, polyline, distanceM, c.id)
		if err != nil {
			return updated, fmt.Errorf("corridor %d (%s): store polyline: %w", c.id, c.name, err)
		}
		log.Printf("corridor %d (%s): stored route (%.0f m)", c.id, c.name, distanceM)
		updated++
	}
	return updated, nil
}

func route(ctx context.Context, client *http.Client, baseURL string, c corridorEndpoints) (string, float64, error) {
	endpoint := fmt.Sprintf("%s/route/v1/driving/%f,%f;%f,%f",
		baseURL, c.entryLon, c.entryLat, c.exitLon, c.exitLat)
	u, err := url.Parse(endpoint)
	if err != nil {
		return "", 0, err
	}
	qs := u.Query()
	qs.Set("overview", "full")
	qs.Set("geometries", "polyline")
	u.RawQuery = qs.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return "", 0, err
	}
	req.Header.Set("User-Agent", "radar-alert-data-pipeline")

	resp, err := client.Do(req)
	if err != nil {
		return "", 0, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", 0, err
	}
	if resp.StatusCode != http.StatusOK {
		return "", 0, fmt.Errorf("osrm status %d: %s", resp.StatusCode, truncate(string(body), 200))
	}

	var parsed osrmResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return "", 0, err
	}
	if parsed.Code != "Ok" || len(parsed.Routes) == 0 {
		return "", 0, fmt.Errorf("osrm returned code %q with %d routes", parsed.Code, len(parsed.Routes))
	}
	return parsed.Routes[0].Geometry, parsed.Routes[0].Distance, nil
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}
