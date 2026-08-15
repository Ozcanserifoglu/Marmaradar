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

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/backend/internal/client/distancematrix"
)

const (
	etaMaxDestinations = 3
	etaCacheTTL        = 25 * time.Second
	etaOriginCellDeg   = 0.001
)

var (
	ErrEtaUnavailable     = errors.New("eta service unavailable")
	ErrEtaTooManyDests    = errors.New("too many destinations")
	ErrEtaInvalidOrigin   = errors.New("invalid origin")
	ErrEtaNoDestinations  = errors.New("no destinations")
	ErrEtaInvalidCameraID = errors.New("invalid camera destination")
)

type EtaDestination struct {
	CameraID int64   `json:"camera_id"`
	Lat      float64 `json:"lat"`
	Lon      float64 `json:"lon"`
}

type EtaRequest struct {
	Origin       LatLon           `json:"origin"`
	Destinations []EtaDestination `json:"destinations"`
}

type LatLon struct {
	Lat float64 `json:"lat"`
	Lon float64 `json:"lon"`
}

type EtaResult struct {
	CameraID    int64   `json:"camera_id"`
	DistanceM   float64 `json:"distance_m"`
	DurationSec float64 `json:"duration_sec"`
	Status      string  `json:"status"`
}

type etaCacheEntry struct {
	results   []EtaResult
	expiresAt time.Time
}

type EtaService struct {
	pool   *pgxpool.Pool
	matrix *distancematrix.Client

	mu    sync.Mutex
	cache map[string]etaCacheEntry

	hits   int64
	misses int64
	errors int64
}

func NewEtaService(pool *pgxpool.Pool, matrix *distancematrix.Client) *EtaService {
	return &EtaService{
		pool:   pool,
		matrix: matrix,
		cache:  make(map[string]etaCacheEntry),
	}
}

func (s *EtaService) CamerasETA(ctx context.Context, req EtaRequest) ([]EtaResult, error) {
	if s == nil || s.matrix == nil || !s.matrix.Enabled() {
		return nil, ErrEtaUnavailable
	}
	if !validCoord(req.Origin.Lat, req.Origin.Lon) {
		return nil, ErrEtaInvalidOrigin
	}
	if len(req.Destinations) == 0 {
		return nil, ErrEtaNoDestinations
	}
	if len(req.Destinations) > etaMaxDestinations {
		return nil, ErrEtaTooManyDests
	}

	dests := make([]EtaDestination, 0, len(req.Destinations))
	seen := make(map[int64]struct{}, len(req.Destinations))
	for _, d := range req.Destinations {
		if d.CameraID <= 0 || !validCoord(d.Lat, d.Lon) {
			return nil, ErrEtaInvalidCameraID
		}
		if _, ok := seen[d.CameraID]; ok {
			continue
		}
		seen[d.CameraID] = struct{}{}
		dests = append(dests, d)
	}
	if len(dests) == 0 {
		return nil, ErrEtaNoDestinations
	}

	if err := s.verifyCamerasExist(ctx, dests); err != nil {
		return nil, err
	}

	cacheKey := etaCacheKey(req.Origin, dests)
	if cached, ok := s.getCache(cacheKey); ok {
		s.mu.Lock()
		s.hits++
		s.mu.Unlock()
		return cached, nil
	}

	s.mu.Lock()
	s.misses++
	s.mu.Unlock()

	origin := distancematrix.LatLng{Lat: req.Origin.Lat, Lon: req.Origin.Lon}
	points := make([]distancematrix.LatLng, len(dests))
	for i, d := range dests {
		points[i] = distancematrix.LatLng{Lat: d.Lat, Lon: d.Lon}
	}

	elements, err := s.matrix.DrivingDistances(ctx, origin, points)
	if err != nil {
		s.mu.Lock()
		s.errors++
		hits, misses, errs := s.hits, s.misses, s.errors
		s.mu.Unlock()
		slog.Warn("distance matrix failed",
			"error", err,
			"cache_hits", hits,
			"cache_misses", misses,
			"matrix_errors", errs,
		)
		return nil, fmt.Errorf("distance matrix: %w", err)
	}

	results := make([]EtaResult, len(dests))
	for i, d := range dests {
		el := elements[i]
		results[i] = EtaResult{
			CameraID:    d.CameraID,
			DistanceM:   el.DistanceM,
			DurationSec: el.DurationSec,
			Status:      el.Status,
		}
	}

	s.putCache(cacheKey, results)
	slog.Info("distance matrix ok",
		"destinations", len(results),
		"cache_key", cacheKey,
	)
	return results, nil
}

func (s *EtaService) verifyCamerasExist(ctx context.Context, dests []EtaDestination) error {
	ids := make([]int64, len(dests))
	for i, d := range dests {
		ids[i] = d.CameraID
	}

	const q = `
		SELECT COUNT(*) FROM fixed_cameras
		WHERE active AND id = ANY($1)`

	var count int
	if err := s.pool.QueryRow(ctx, q, ids).Scan(&count); err != nil {
		return fmt.Errorf("verify cameras: %w", err)
	}
	if count != len(ids) {
		return ErrEtaInvalidCameraID
	}
	return nil
}

func (s *EtaService) getCache(key string) ([]EtaResult, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	entry, ok := s.cache[key]
	if !ok || time.Now().After(entry.expiresAt) {
		if ok {
			delete(s.cache, key)
		}
		return nil, false
	}
	out := make([]EtaResult, len(entry.results))
	copy(out, entry.results)
	return out, true
}

func (s *EtaService) putCache(key string, results []EtaResult) {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := time.Now()
	for k, v := range s.cache {
		if now.After(v.expiresAt) {
			delete(s.cache, k)
		}
	}
	copied := make([]EtaResult, len(results))
	copy(copied, results)
	s.cache[key] = etaCacheEntry{
		results:   copied,
		expiresAt: now.Add(etaCacheTTL),
	}
}

func etaCacheKey(origin LatLon, dests []EtaDestination) string {
	olat := math.Round(origin.Lat/etaOriginCellDeg) * etaOriginCellDeg
	olon := math.Round(origin.Lon/etaOriginCellDeg) * etaOriginCellDeg

	sorted := make([]EtaDestination, len(dests))
	copy(sorted, dests)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].CameraID < sorted[j].CameraID
	})

	parts := make([]string, len(sorted))
	for i, d := range sorted {
		parts[i] = fmt.Sprintf("%d", d.CameraID)
	}
	return fmt.Sprintf("%.4f,%.4f|%s", olat, olon, strings.Join(parts, ","))
}

func validCoord(lat, lon float64) bool {
	return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 &&
		!(lat == 0 && lon == 0)
}
