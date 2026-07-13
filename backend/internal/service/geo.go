package service

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/backend/internal/model"
)

type GeoService struct {
	pool *pgxpool.Pool
}

func NewGeoService(pool *pgxpool.Pool) *GeoService {
	return &GeoService{pool: pool}
}

func (s *GeoService) NearbyCameras(ctx context.Context, lat, lon, radiusM float64, region string) ([]model.Camera, error) {
	const q = `
		SELECT id, ST_Y(location::geometry), ST_X(location::geometry),
		       maxspeed_kmh, direction_deg, direction_tolerance_deg,
		       ST_Distance(location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) AS distance_m,
		       road_name, camera_type, region_code
		FROM fixed_cameras
		WHERE active AND region_code = $3
		  AND ST_DWithin(location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $4)
		ORDER BY distance_m
		LIMIT 50`

	rows, err := s.pool.Query(ctx, q, lon, lat, region, radiusM)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cameras []model.Camera
	for rows.Next() {
		var c model.Camera
		if err := rows.Scan(
			&c.ID, &c.Lat, &c.Lon,
			&c.MaxspeedKmh, &c.DirectionDeg, &c.DirectionToleranceDeg,
			&c.DistanceM, &c.RoadName, &c.CameraType, &c.RegionCode,
		); err != nil {
			return nil, err
		}
		cameras = append(cameras, c)
	}
	return cameras, rows.Err()
}

func (s *GeoService) NearbyCorridors(ctx context.Context, lat, lon float64, region string) ([]model.Corridor, error) {
	const q = `
		SELECT id, external_id, name, maxspeed_kmh, length_m, direction, region_code,
		       CASE WHEN route_polyline IS NOT NULL
		            THEN ST_AsEncodedPolyline(route_polyline::geometry)
		       END AS polyline
		FROM speed_corridors sc
		WHERE sc.active AND sc.region_code = $3
		  AND (
		    (sc.corridor_polygon IS NOT NULL AND ST_Contains(sc.corridor_polygon::geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326)))
		    OR EXISTS (
		      SELECT 1 FROM corridor_gates cg
		      WHERE cg.corridor_id = sc.id
		        AND ST_DWithin(cg.location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, cg.radius_m + 200)
		    )
		  )`

	rows, err := s.pool.Query(ctx, q, lon, lat, region)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var corridors []model.Corridor
	for rows.Next() {
		var c model.Corridor
		if err := rows.Scan(&c.ID, &c.ExternalID, &c.Name, &c.MaxspeedKmh, &c.LengthM, &c.Direction, &c.RegionCode, &c.Polyline); err != nil {
			return nil, err
		}
		gates, err := s.gatesForCorridor(ctx, c.ID)
		if err != nil {
			return nil, err
		}
		c.Gates = gates
		corridors = append(corridors, c)
	}
	return corridors, rows.Err()
}

func (s *GeoService) gatesForCorridor(ctx context.Context, corridorID int64) ([]model.CorridorGate, error) {
	const q = `
		SELECT id, gate_type, ST_Y(location::geometry), ST_X(location::geometry),
		       radius_m, sequence, direction_deg
		FROM corridor_gates
		WHERE corridor_id = $1
		ORDER BY sequence`

	rows, err := s.pool.Query(ctx, q, corridorID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var gates []model.CorridorGate
	for rows.Next() {
		var g model.CorridorGate
		if err := rows.Scan(&g.ID, &g.GateType, &g.Lat, &g.Lon, &g.RadiusM, &g.Sequence, &g.DirectionDeg); err != nil {
			return nil, err
		}
		gates = append(gates, g)
	}
	return gates, rows.Err()
}

func (s *GeoService) SyncDelta(ctx context.Context, region, bbox string, since *time.Time) (model.SyncPayload, error) {
	west, south, east, north, err := parseBBox(bbox)
	if err != nil {
		return model.SyncPayload{}, err
	}

	cameras, err := s.camerasInBBox(ctx, region, west, south, east, north, since)
	if err != nil {
		return model.SyncPayload{}, err
	}
	corridors, err := s.corridorsInBBox(ctx, region, west, south, east, north, since)
	if err != nil {
		return model.SyncPayload{}, err
	}

	return model.SyncPayload{
		Cameras:    cameras,
		Corridors:  corridors,
		Since:      since,
		ServerTime: time.Now().UTC(),
	}, nil
}

func (s *GeoService) camerasInBBox(ctx context.Context, region string, west, south, east, north float64, since *time.Time) ([]model.Camera, error) {
	q := `
		SELECT id, ST_Y(location::geometry), ST_X(location::geometry),
		       maxspeed_kmh, direction_deg, direction_tolerance_deg,
		       0::float8 AS distance_m, road_name, camera_type, region_code
		FROM fixed_cameras
		WHERE active`
	args := []any{}
	argN := 1

	if region != "" && region != "turkey" {
		q += fmt.Sprintf(` AND region_code = $%d`, argN)
		args = append(args, region)
		argN++
	}

	q += fmt.Sprintf(` AND location && ST_MakeEnvelope($%d, $%d, $%d, $%d, 4326)::geography`, argN, argN+1, argN+2, argN+3)
	args = append(args, west, south, east, north)
	argN += 4

	if since != nil {
		q += fmt.Sprintf(` AND updated_at > $%d`, argN)
		args = append(args, *since)
	}

	rows, err := s.pool.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cameras []model.Camera
	for rows.Next() {
		var c model.Camera
		if err := rows.Scan(
			&c.ID, &c.Lat, &c.Lon,
			&c.MaxspeedKmh, &c.DirectionDeg, &c.DirectionToleranceDeg,
			&c.DistanceM, &c.RoadName, &c.CameraType, &c.RegionCode,
		); err != nil {
			return nil, err
		}
		cameras = append(cameras, c)
	}
	return cameras, rows.Err()
}

func (s *GeoService) corridorsInBBox(ctx context.Context, region string, west, south, east, north float64, since *time.Time) ([]model.Corridor, error) {
	q := `
		SELECT id, external_id, name, maxspeed_kmh, length_m, direction, region_code,
		       CASE WHEN route_polyline IS NOT NULL
		            THEN ST_AsEncodedPolyline(route_polyline::geometry)
		       END AS polyline
		FROM speed_corridors
		WHERE active`
	args := []any{}
	argN := 1

	if region != "" && region != "turkey" {
		q += fmt.Sprintf(` AND region_code = $%d`, argN)
		args = append(args, region)
		argN++
	}

	q += fmt.Sprintf(` AND (
		    (corridor_polygon IS NOT NULL AND corridor_polygon && ST_MakeEnvelope($%d, $%d, $%d, $%d, 4326)::geography)
		    OR id IN (
		      SELECT corridor_id FROM corridor_gates
		      WHERE location && ST_MakeEnvelope($%d, $%d, $%d, $%d, 4326)::geography
		    )
		  )`, argN, argN+1, argN+2, argN+3, argN, argN+1, argN+2, argN+3)
	args = append(args, west, south, east, north)
	argN += 4

	if since != nil {
		q += fmt.Sprintf(` AND updated_at > $%d`, argN)
		args = append(args, *since)
	}

	rows, err := s.pool.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var corridors []model.Corridor
	for rows.Next() {
		var c model.Corridor
		if err := rows.Scan(&c.ID, &c.ExternalID, &c.Name, &c.MaxspeedKmh, &c.LengthM, &c.Direction, &c.RegionCode, &c.Polyline); err != nil {
			return nil, err
		}
		gates, err := s.gatesForCorridor(ctx, c.ID)
		if err != nil {
			return nil, err
		}
		c.Gates = gates
		corridors = append(corridors, c)
	}
	return corridors, rows.Err()
}

func parseBBox(bbox string) (west, south, east, north float64, err error) {
	if bbox == "" {
		return 0, 0, 0, 0, fmt.Errorf("bbox is required (west,south,east,north)")
	}
	_, err = fmt.Sscanf(bbox, "%f,%f,%f,%f", &west, &south, &east, &north)
	if err != nil {
		return 0, 0, 0, 0, fmt.Errorf("invalid bbox format: %w", err)
	}
	return west, south, east, north, nil
}
