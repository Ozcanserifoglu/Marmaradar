package service

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/radar-alert/backend/internal/client/places"
)

const (
	amenityCellDeg       = 0.02
	amenitySearchRadiusM = 1500
	amenityPerCellCap    = 12
	amenityMaxCells      = 3
	amenityCacheTTL      = 45 * time.Minute
)

var (
	ErrAmenitiesUnavailable = errors.New("amenities service unavailable")
	ErrAmenitiesNoCells     = errors.New("no cells")
	ErrAmenitiesTooMany     = errors.New("too many cells")
	ErrAmenitiesInvalidCell = errors.New("invalid cell")
	ErrAmenitiesInvalidType = errors.New("invalid amenity type")
)

type AmenityCellRef struct {
	LatIndex int `json:"lat_index"`
	LonIndex int `json:"lon_index"`
}

type AmenitiesRequest struct {
	Cells []AmenityCellRef `json:"cells"`
	Types []string         `json:"types"`
}

type AmenityPlace struct {
	PlaceID  string   `json:"place_id"`
	Name     string   `json:"name"`
	Lat      float64  `json:"lat"`
	Lon      float64  `json:"lon"`
	Category string   `json:"category"`
	CellKey  string   `json:"cell_key"`
	OpenNow  *bool    `json:"open_now,omitempty"`
	Rating   *float64 `json:"rating,omitempty"`
}

type amenityCacheEntry struct {
	places    []AmenityPlace
	expiresAt time.Time
}

type AmenitiesService struct {
	places *places.Client

	mu    sync.Mutex
	cache map[string]amenityCacheEntry

	hits   int64
	misses int64
	errors int64
}

func NewAmenitiesService(placesClient *places.Client) *AmenitiesService {
	return &AmenitiesService{
		places: placesClient,
		cache:  make(map[string]amenityCacheEntry),
	}
}

func (s *AmenitiesService) Cells(ctx context.Context, req AmenitiesRequest) ([]AmenityPlace, error) {
	if s == nil || s.places == nil || !s.places.Enabled() {
		return nil, ErrAmenitiesUnavailable
	}
	if len(req.Cells) == 0 {
		return nil, ErrAmenitiesNoCells
	}
	if len(req.Cells) > amenityMaxCells {
		return nil, ErrAmenitiesTooMany
	}

	types, err := normalizeAmenityTypes(req.Types)
	if err != nil {
		return nil, err
	}

	cells := dedupeCells(req.Cells)
	if len(cells) == 0 {
		return nil, ErrAmenitiesNoCells
	}
	for _, c := range cells {
		if !validAmenityCell(c) {
			return nil, ErrAmenitiesInvalidCell
		}
	}

	out := make([]AmenityPlace, 0, len(cells)*amenityPerCellCap)
	for _, cell := range cells {
		placesForCell, err := s.placesForCell(ctx, cell, types)
		if err != nil {
			return nil, err
		}
		out = append(out, placesForCell...)
	}
	return out, nil
}

func (s *AmenitiesService) placesForCell(ctx context.Context, cell AmenityCellRef, types []string) ([]AmenityPlace, error) {
	cellKey := amenityCellKey(cell)
	cacheKey := cellKey + "|" + strings.Join(types, ",")

	if cached, ok := s.getCache(cacheKey); ok {
		s.mu.Lock()
		s.hits++
		s.mu.Unlock()
		return cached, nil
	}

	s.mu.Lock()
	s.misses++
	s.mu.Unlock()

	lat, lon := cellCenter(cell)
	seen := make(map[string]struct{})
	merged := make([]AmenityPlace, 0, amenityPerCellCap)

	for _, t := range types {
		var (
			found []places.Place
			err   error
		)
		switch t {
		case "gas_station":
			found, err = s.places.NearbySearch(ctx, lat, lon, amenitySearchRadiusM, "gas_station", "", "gas_station")
		case "rest_stop":
			// TR highway rest areas are better matched by keyword than a Places type.
			found, err = s.places.NearbySearch(ctx, lat, lon, amenitySearchRadiusM, "", "dinlenme", "rest_stop")
		default:
			return nil, ErrAmenitiesInvalidType
		}
		if err != nil {
			s.mu.Lock()
			s.errors++
			hits, misses, errs := s.hits, s.misses, s.errors
			s.mu.Unlock()
			slog.Warn("places nearby failed",
				"error", err,
				"category", t,
				"cell", cellKey,
				"cache_hits", hits,
				"cache_misses", misses,
				"places_errors", errs,
			)
			return nil, fmt.Errorf("places nearby: %w", err)
		}
		for _, p := range found {
			if _, ok := seen[p.PlaceID]; ok {
				continue
			}
			seen[p.PlaceID] = struct{}{}
			merged = append(merged, AmenityPlace{
				PlaceID:  p.PlaceID,
				Name:     p.Name,
				Lat:      p.Lat,
				Lon:      p.Lon,
				Category: p.Category,
				CellKey:  cellKey,
				OpenNow:  p.OpenNow,
				Rating:   p.Rating,
			})
			if len(merged) >= amenityPerCellCap {
				break
			}
		}
		if len(merged) >= amenityPerCellCap {
			break
		}
	}

	s.putCache(cacheKey, merged)
	slog.Info("places nearby ok",
		"cell", cellKey,
		"places", len(merged),
		"types", strings.Join(types, ","),
	)
	return merged, nil
}

func (s *AmenitiesService) getCache(key string) ([]AmenityPlace, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	entry, ok := s.cache[key]
	if !ok || time.Now().After(entry.expiresAt) {
		if ok {
			delete(s.cache, key)
		}
		return nil, false
	}
	out := make([]AmenityPlace, len(entry.places))
	copy(out, entry.places)
	return out, true
}

func (s *AmenitiesService) putCache(key string, list []AmenityPlace) {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := time.Now()
	for k, v := range s.cache {
		if now.After(v.expiresAt) {
			delete(s.cache, k)
		}
	}
	copied := make([]AmenityPlace, len(list))
	copy(copied, list)
	s.cache[key] = amenityCacheEntry{
		places:    copied,
		expiresAt: now.Add(amenityCacheTTL),
	}
}

func normalizeAmenityTypes(types []string) ([]string, error) {
	if len(types) == 0 {
		return []string{"gas_station", "rest_stop"}, nil
	}
	allowed := map[string]struct{}{
		"gas_station": {},
		"rest_stop":   {},
	}
	seen := make(map[string]struct{}, len(types))
	out := make([]string, 0, len(types))
	for _, t := range types {
		t = strings.TrimSpace(t)
		if _, ok := allowed[t]; !ok {
			return nil, ErrAmenitiesInvalidType
		}
		if _, ok := seen[t]; ok {
			continue
		}
		seen[t] = struct{}{}
		out = append(out, t)
	}
	sort.Strings(out)
	if len(out) == 0 {
		return nil, ErrAmenitiesInvalidType
	}
	return out, nil
}

func dedupeCells(cells []AmenityCellRef) []AmenityCellRef {
	seen := make(map[string]struct{}, len(cells))
	out := make([]AmenityCellRef, 0, len(cells))
	for _, c := range cells {
		k := amenityCellKey(c)
		if _, ok := seen[k]; ok {
			continue
		}
		seen[k] = struct{}{}
		out = append(out, c)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].LatIndex != out[j].LatIndex {
			return out[i].LatIndex < out[j].LatIndex
		}
		return out[i].LonIndex < out[j].LonIndex
	})
	return out
}

func amenityCellKey(c AmenityCellRef) string {
	return fmt.Sprintf("%d:%d", c.LatIndex, c.LonIndex)
}

func cellCenter(c AmenityCellRef) (lat, lon float64) {
	lat = (float64(c.LatIndex) + 0.5) * amenityCellDeg
	lon = (float64(c.LonIndex) + 0.5) * amenityCellDeg
	return lat, lon
}

func validAmenityCell(c AmenityCellRef) bool {
	maxLat := int(math.Floor(90 / amenityCellDeg))
	maxLon := int(math.Floor(180 / amenityCellDeg))
	return c.LatIndex >= -maxLat && c.LatIndex <= maxLat &&
		c.LonIndex >= -maxLon && c.LonIndex <= maxLon
}

func AmenityCellIndexes(lat, lon float64) (latIndex, lonIndex int) {
	return int(math.Floor(lat / amenityCellDeg)), int(math.Floor(lon / amenityCellDeg))
}
