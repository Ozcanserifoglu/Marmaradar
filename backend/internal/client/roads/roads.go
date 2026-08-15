package roads

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

const (
	snapURL           = "https://roads.googleapis.com/v1/snapToRoads"
	pageSizeLimit     = 100
	paginationOverlap = 5
	defaultTimeout    = 15 * time.Second
)

type LatLng struct {
	Lat float64
	Lon float64
}

type Client struct {
	apiKey     string
	endpoint   string
	httpClient *http.Client
}

func NewClient(apiKey string) *Client {
	return &Client{
		apiKey:   strings.TrimSpace(apiKey),
		endpoint: snapURL,
		httpClient: &http.Client{
			Timeout: defaultTimeout,
		},
	}
}

func (c *Client) Enabled() bool {
	return c != nil && c.apiKey != ""
}

type snapResponse struct {
	SnappedPoints []snappedPoint `json:"snappedPoints"`
	Error         *apiError      `json:"error"`
}

type snappedPoint struct {
	Location      location `json:"location"`
	OriginalIndex *int     `json:"originalIndex"`
	PlaceID       string   `json:"placeId"`
}

type location struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type apiError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Status  string `json:"status"`
}

func (e *apiError) Error() string {
	if e == nil {
		return "roads api error"
	}
	return fmt.Sprintf("roads api %s (%d): %s", e.Status, e.Code, e.Message)
}

func (c *Client) SnapToRoads(ctx context.Context, points []LatLng) ([]LatLng, error) {
	if !c.Enabled() {
		return nil, fmt.Errorf("roads api key not configured")
	}
	if len(points) < 2 {
		return nil, fmt.Errorf("at least 2 points required for snap")
	}

	var snapped []LatLng
	offset := 0
	for offset < len(points) {
		if offset > 0 {
			offset -= paginationOverlap
			if offset < 0 {
				offset = 0
			}
		}
		upper := offset + pageSizeLimit
		if upper > len(points) {
			upper = len(points)
		}
		page := points[offset:upper]

		pageSnapped, err := c.snapPage(ctx, page)
		if err != nil {
			return nil, err
		}

		// Google sample: skip overlap on subsequent pages so the path concatenates.
		passedOverlap := offset == 0
		for _, sp := range pageSnapped {
			if !passedOverlap {
				if sp.OriginalIndex != nil && *sp.OriginalIndex >= paginationOverlap-1 {
					passedOverlap = true
				} else {
					continue
				}
			}
			pt := LatLng{Lat: sp.Location.Latitude, Lon: sp.Location.Longitude}
			if len(snapped) > 0 {
				last := snapped[len(snapped)-1]
				if last.Lat == pt.Lat && last.Lon == pt.Lon {
					continue
				}
			}
			snapped = append(snapped, pt)
		}

		offset = upper
	}

	if len(snapped) < 2 {
		return nil, fmt.Errorf("snap returned fewer than 2 points")
	}
	return snapped, nil
}

func (c *Client) snapPage(ctx context.Context, points []LatLng) ([]snappedPoint, error) {
	pathParts := make([]string, len(points))
	for i, p := range points {
		pathParts[i] = formatCoord(p.Lat) + "," + formatCoord(p.Lon)
	}

	q := url.Values{}
	q.Set("interpolate", "true")
	q.Set("path", strings.Join(pathParts, "|"))
	q.Set("key", c.apiKey)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.endpoint+"?"+q.Encode(), nil)
	if err != nil {
		return nil, fmt.Errorf("build snap request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("snap request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, fmt.Errorf("read snap response: %w", err)
	}

	var parsed snapResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("decode snap response: %w", err)
	}
	if parsed.Error != nil {
		return nil, parsed.Error
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("snap http %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	if len(parsed.SnappedPoints) == 0 {
		return nil, fmt.Errorf("snap returned no points")
	}
	return parsed.SnappedPoints, nil
}

func formatCoord(v float64) string {
	return strconv.FormatFloat(v, 'f', -1, 64)
}
