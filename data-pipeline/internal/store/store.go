package store

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/data-pipeline/internal/normalize"
)

func BeginImport(ctx context.Context, pool *pgxpool.Pool, name, kind, region string) (sourceID, runID int64, err error) {
	err = pool.QueryRow(ctx, `
		INSERT INTO data_sources (name, source_url, license)
		VALUES ($1, $2, 'ODbL')
		RETURNING id`, name, kind).Scan(&sourceID)
	if err != nil {
		return 0, 0, err
	}

	var regionPtr *string
	if region != "" {
		regionPtr = &region
	}
	err = pool.QueryRow(ctx, `
		INSERT INTO import_runs (data_source_id, region_code, status)
		VALUES ($1, $2, 'running')
		RETURNING id`, sourceID, regionPtr).Scan(&runID)
	return sourceID, runID, err
}

func FinishImport(ctx context.Context, pool *pgxpool.Pool, runID int64, importErr error) error {
	status := "success"
	var errMsg *string
	if importErr != nil {
		status = "failed"
		msg := importErr.Error()
		errMsg = &msg
	}
	_, err := pool.Exec(ctx, `
		UPDATE import_runs
		SET status = $1, error_message = $2, finished_at = $3
		WHERE id = $4`, status, errMsg, time.Now().UTC(), runID)
	return err
}

func UpdateImportCounts(ctx context.Context, pool *pgxpool.Pool, runID int64, recordsIn, upserted int) error {
	_, err := pool.Exec(ctx, `
		UPDATE import_runs SET records_in = $1, records_upserted = $2 WHERE id = $3`,
		recordsIn, upserted, runID)
	return err
}

func UpsertCamera(ctx context.Context, pool *pgxpool.Pool, cam normalize.CameraRecord, sourceID int64) error {
	tagsJSON, err := json.Marshal(cam.SourceTags)
	if err != nil || len(cam.SourceTags) == 0 {
		tagsJSON = []byte("{}")
	}
	_, err = pool.Exec(ctx, `
		INSERT INTO fixed_cameras (
			external_id, region_code, location, road_name, maxspeed_kmh,
			direction_deg, camera_type, active, source_id, source_tags, confidence, updated_at
		) VALUES (
			$1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography,
			NULLIF($5, ''), $6, $7, $8, $9, $10, $11::jsonb, $12, now()
		)
		ON CONFLICT (region_code, external_id) DO UPDATE SET
			location = EXCLUDED.location,
			road_name = EXCLUDED.road_name,
			maxspeed_kmh = EXCLUDED.maxspeed_kmh,
			direction_deg = EXCLUDED.direction_deg,
			camera_type = EXCLUDED.camera_type,
			active = EXCLUDED.active,
			source_tags = EXCLUDED.source_tags,
			confidence = EXCLUDED.confidence,
			updated_at = now()`,
		cam.ExternalID, cam.RegionCode, cam.Lon, cam.Lat, cam.RoadName,
		cam.MaxspeedKmh, cam.DirectionDeg, cam.CameraType, cam.Active,
		sourceID, string(tagsJSON), cam.Confidence)
	return err
}

type GateInput struct {
	GateType     string
	Lat          float64
	Lon          float64
	RadiusM      float32
	Sequence     int16
	DirectionDeg *int16
}

func UpsertCorridor(ctx context.Context, pool *pgxpool.Pool, externalID, name, region string, maxspeed int16, lengthM float64, direction string, gates []GateInput, sourceID int64) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var corridorID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO speed_corridors (external_id, region_code, name, length_m, maxspeed_kmh, direction, source_id, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, now())
		ON CONFLICT (region_code, external_id) DO UPDATE SET
			name = EXCLUDED.name,
			length_m = EXCLUDED.length_m,
			maxspeed_kmh = EXCLUDED.maxspeed_kmh,
			direction = EXCLUDED.direction,
			updated_at = now()
		RETURNING id`,
		externalID, region, name, lengthM, maxspeed, direction, sourceID).Scan(&corridorID)
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx, `DELETE FROM corridor_gates WHERE corridor_id = $1`, corridorID)
	if err != nil {
		return err
	}

	for _, g := range gates {
		radius := g.RadiusM
		if radius == 0 {
			radius = 80
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO corridor_gates (corridor_id, gate_type, location, radius_m, sequence, direction_deg)
			VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5, $6, $7)`,
			corridorID, g.GateType, g.Lon, g.Lat, radius, g.Sequence, g.DirectionDeg)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func ImportOverpassCameras(ctx context.Context, pool *pgxpool.Pool, cameras []normalize.CameraRecord, region string) (int, error) {
	sourceID, runID, err := BeginImport(ctx, pool, "osm_overpass", "overpass", region)
	if err != nil {
		return 0, err
	}
	defer func() {
		_ = FinishImport(ctx, pool, runID, err)
	}()

	upserted := 0
	for _, cam := range cameras {
		if region != "" && cam.RegionCode != region {
			continue
		}
		if err := UpsertCamera(ctx, pool, cam, sourceID); err != nil {
			return upserted, err
		}
		upserted++
	}
	_ = UpdateImportCounts(ctx, pool, runID, len(cameras), upserted)
	return upserted, nil
}
