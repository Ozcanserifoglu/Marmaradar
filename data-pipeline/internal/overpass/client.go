package overpass

import (
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/radar-alert/data-pipeline/internal/normalize"
)

//go:embed query_bursa.ql
var defaultQuery string

var endpoints = []string{
	"https://overpass.kumi.systems/api/interpreter",
	"https://overpass.openstreetmap.ru/api/interpreter",
	"https://overpass-api.de/api/interpreter",
}

type Client struct {
	httpClient *http.Client
	query      string
}

func NewClient() *Client {
	return &Client{
		httpClient: &http.Client{Timeout: 90 * time.Second},
		query:      defaultQuery,
	}
}

type overpassResponse struct {
	Elements []overpassElement `json:"elements"`
}

type overpassElement struct {
	Type    string            `json:"type"`
	ID      int64             `json:"id"`
	Lat     float64           `json:"lat"`
	Lon     float64           `json:"lon"`
	Tags    map[string]string `json:"tags"`
	Members []overpassMember  `json:"members"`
}

type overpassMember struct {
	Type string `json:"type"`
	Ref  int64  `json:"ref"`
	Role string `json:"role"`
}

type ImportResult struct {
	Cameras   []normalize.CameraRecord
	Relations []overpassElement
}

func (c *Client) Fetch(ctx context.Context) (*ImportResult, error) {
	var lastErr error
	for _, endpoint := range endpoints {
		result, err := c.fetchFrom(ctx, endpoint)
		if err == nil {
			return result, nil
		}
		lastErr = fmt.Errorf("%s: %w", endpoint, err)
	}
	return nil, lastErr
}

func (c *Client) fetchFrom(ctx context.Context, endpoint string) (*ImportResult, error) {
	form := url.Values{"data": {c.query}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "radar-alert-importer/1.0 (contact: dev@localhost)")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		snippet := string(body)
		if len(snippet) > 200 {
			snippet = snippet[:200]
		}
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, snippet)
	}

	var parsed overpassResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, err
	}

	result := &ImportResult{}
	for _, el := range parsed.Elements {
		switch el.Type {
		case "node":
			if el.Tags["highway"] != "speed_camera" {
				continue
			}
			result.Cameras = append(result.Cameras, normalize.CameraRecord{
				ExternalID:  fmt.Sprintf("osm:node:%d", el.ID),
				RegionCode:  normalize.RegionForPoint(el.Lat, el.Lon),
				Lat:         el.Lat,
				Lon:         el.Lon,
				RoadName:    el.Tags["ref"],
				MaxspeedKmh: normalize.ParseMaxspeed(el.Tags),
				CameraType:  normalize.CameraTypeFromTags(el.Tags),
				Active:      true,
				SourceTags:  el.Tags,
				Confidence:  0.7,
			})
		case "relation":
			if el.Tags["type"] == "enforcement" {
				result.Relations = append(result.Relations, el)
			}
		}
	}
	return result, nil
}
