package places

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
	nearbyURL      = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
	defaultTimeout = 8 * time.Second
	maxResults     = 20
)

type Place struct {
	PlaceID  string
	Name     string
	Lat      float64
	Lon      float64
	Types    []string
	OpenNow  *bool
	Rating   *float64
	Category string
}

type Client struct {
	apiKey     string
	endpoint   string
	httpClient *http.Client
}

func NewClient(apiKey string) *Client {
	return &Client{
		apiKey:   strings.TrimSpace(apiKey),
		endpoint: nearbyURL,
		httpClient: &http.Client{
			Timeout: defaultTimeout,
		},
	}
}

func (c *Client) Enabled() bool {
	return c != nil && c.apiKey != ""
}

func (c *Client) SetHTTPForTest(endpoint string, httpClient *http.Client) {
	if c == nil {
		return
	}
	c.endpoint = endpoint
	if httpClient != nil {
		c.httpClient = httpClient
	}
}

type nearbyResponse struct {
	Status       string         `json:"status"`
	ErrorMessage string         `json:"error_message"`
	Results      []nearbyResult `json:"results"`
}

type nearbyResult struct {
	PlaceID          string   `json:"place_id"`
	Name             string   `json:"name"`
	Types            []string `json:"types"`
	Rating           *float64 `json:"rating"`
	Geometry         geometry `json:"geometry"`
	OpeningHours     *struct {
		OpenNow bool `json:"open_now"`
	} `json:"opening_hours"`
}

type geometry struct {
	Location struct {
		Lat float64 `json:"lat"`
		Lng float64 `json:"lng"`
	} `json:"location"`
}

func (c *Client) NearbySearch(ctx context.Context, lat, lon, radiusM float64, placeType, keyword, category string) ([]Place, error) {
	if !c.Enabled() {
		return nil, fmt.Errorf("places api key not configured")
	}
	if radiusM <= 0 {
		return nil, fmt.Errorf("radius must be positive")
	}

	q := url.Values{}
	q.Set("location", formatCoord(lat)+","+formatCoord(lon))
	q.Set("radius", strconv.FormatInt(int64(radiusM), 10))
	q.Set("language", "tr")
	q.Set("key", c.apiKey)
	if placeType != "" {
		q.Set("type", placeType)
	}
	if keyword != "" {
		q.Set("keyword", keyword)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.endpoint+"?"+q.Encode(), nil)
	if err != nil {
		return nil, fmt.Errorf("build places request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("places request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, fmt.Errorf("read places response: %w", err)
	}

	var parsed nearbyResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("decode places response: %w", err)
	}
	// ZERO_RESULTS is a successful empty set.
	if parsed.Status != "OK" && parsed.Status != "ZERO_RESULTS" {
		msg := parsed.Status
		if parsed.ErrorMessage != "" {
			msg = parsed.Status + ": " + parsed.ErrorMessage
		}
		return nil, fmt.Errorf("places status %s", msg)
	}

	limit := len(parsed.Results)
	if limit > maxResults {
		limit = maxResults
	}
	out := make([]Place, 0, limit)
	for i := 0; i < limit; i++ {
		r := parsed.Results[i]
		if r.PlaceID == "" || r.Name == "" {
			continue
		}
		p := Place{
			PlaceID:  r.PlaceID,
			Name:     r.Name,
			Lat:      r.Geometry.Location.Lat,
			Lon:      r.Geometry.Location.Lng,
			Types:    r.Types,
			Rating:   r.Rating,
			Category: category,
		}
		if r.OpeningHours != nil {
			open := r.OpeningHours.OpenNow
			p.OpenNow = &open
		}
		out = append(out, p)
	}
	return out, nil
}

func formatCoord(v float64) string {
	return strconv.FormatFloat(v, 'f', -1, 64)
}
