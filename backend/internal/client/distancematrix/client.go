package distancematrix

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
	matrixURL      = "https://maps.googleapis.com/maps/api/distancematrix/json"
	defaultTimeout = 5 * time.Second
	maxDestinations = 3
)

// LatLng is a geographic coordinate.
type LatLng struct {
	Lat float64
	Lon float64
}

// Element is one origin→destination result from Distance Matrix.
type Element struct {
	DistanceM   float64
	DurationSec float64
	Status      string
}

// Client calls the Google Maps Distance Matrix API.
type Client struct {
	apiKey     string
	endpoint   string
	httpClient *http.Client
}

// NewClient returns a Distance Matrix client. An empty apiKey disables calls.
func NewClient(apiKey string) *Client {
	return &Client{
		apiKey:   strings.TrimSpace(apiKey),
		endpoint: matrixURL,
		httpClient: &http.Client{
			Timeout: defaultTimeout,
		},
	}
}

// Enabled reports whether an API key is configured.
func (c *Client) Enabled() bool {
	return c != nil && c.apiKey != ""
}

type matrixResponse struct {
	Status               string `json:"status"`
	ErrorMessage         string `json:"error_message"`
	DestinationAddresses []string `json:"destination_addresses"`
	OriginAddresses      []string `json:"origin_addresses"`
	Rows                 []matrixRow `json:"rows"`
}

type matrixRow struct {
	Elements []matrixElement `json:"elements"`
}

type matrixElement struct {
	Status   string       `json:"status"`
	Distance *matrixValue `json:"distance"`
	Duration *matrixValue `json:"duration"`
}

type matrixValue struct {
	Text  string `json:"text"`
	Value int64  `json:"value"`
}

// DrivingDistances returns road distance and duration from origin to each
// destination (max 3). Element order matches the destinations slice.
func (c *Client) DrivingDistances(ctx context.Context, origin LatLng, destinations []LatLng) ([]Element, error) {
	if !c.Enabled() {
		return nil, fmt.Errorf("distance matrix api key not configured")
	}
	if len(destinations) == 0 {
		return nil, fmt.Errorf("at least one destination required")
	}
	if len(destinations) > maxDestinations {
		return nil, fmt.Errorf("at most %d destinations allowed", maxDestinations)
	}

	destParts := make([]string, len(destinations))
	for i, d := range destinations {
		destParts[i] = formatCoord(d.Lat) + "," + formatCoord(d.Lon)
	}

	q := url.Values{}
	q.Set("origins", formatCoord(origin.Lat)+","+formatCoord(origin.Lon))
	q.Set("destinations", strings.Join(destParts, "|"))
	q.Set("mode", "driving")
	q.Set("language", "tr")
	q.Set("key", c.apiKey)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.endpoint+"?"+q.Encode(), nil)
	if err != nil {
		return nil, fmt.Errorf("build distance matrix request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("distance matrix request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, fmt.Errorf("read distance matrix response: %w", err)
	}

	var parsed matrixResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("decode distance matrix response: %w", err)
	}
	if parsed.Status != "OK" {
		msg := parsed.Status
		if parsed.ErrorMessage != "" {
			msg = parsed.Status + ": " + parsed.ErrorMessage
		}
		return nil, fmt.Errorf("distance matrix status %s", msg)
	}
	if len(parsed.Rows) == 0 || len(parsed.Rows[0].Elements) != len(destinations) {
		return nil, fmt.Errorf("distance matrix returned unexpected element count")
	}

	out := make([]Element, len(destinations))
	for i, el := range parsed.Rows[0].Elements {
		out[i] = Element{Status: el.Status}
		if el.Status != "OK" {
			continue
		}
		if el.Distance != nil {
			out[i].DistanceM = float64(el.Distance.Value)
		}
		if el.Duration != nil {
			out[i].DurationSec = float64(el.Duration.Value)
		}
	}
	return out, nil
}

func formatCoord(v float64) string {
	return strconv.FormatFloat(v, 'f', -1, 64)
}
