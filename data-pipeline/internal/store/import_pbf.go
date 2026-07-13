package store

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/data-pipeline/internal/normalize"
)

func ImportPBF(ctx context.Context, pool *pgxpool.Pool, cameras []normalize.CameraRecord, corridors []normalize.CorridorRecord, region string) (camerasUpserted, corridorsUpserted int, err error) {
	sourceID, runID, err := BeginImport(ctx, pool, "osm_geofabrik", "pbf", region)
	if err != nil {
		return 0, 0, err
	}
	defer func() {
		_ = FinishImport(ctx, pool, runID, err)
	}()

	for _, cam := range cameras {
		if region != "" && cam.RegionCode != region {
			continue
		}
		if err = UpsertCamera(ctx, pool, cam, sourceID); err != nil {
			return camerasUpserted, corridorsUpserted, err
		}
		camerasUpserted++
	}

	for _, c := range corridors {
		if region != "" && c.RegionCode != region {
			continue
		}
		gates := make([]GateInput, len(c.Gates))
		for i, g := range c.Gates {
			gates[i] = GateInput{
				GateType:     g.GateType,
				Lat:          g.Lat,
				Lon:          g.Lon,
				RadiusM:      g.RadiusM,
				Sequence:     g.Sequence,
				DirectionDeg: g.DirectionDeg,
			}
		}
		if err = UpsertCorridor(ctx, pool, c.ExternalID, c.Name, c.RegionCode, c.MaxspeedKmh, c.LengthM, c.Direction, gates, sourceID); err != nil {
			return camerasUpserted, corridorsUpserted, err
		}
		if len(c.SourceTags) > 0 {
			tagsJSON, _ := json.Marshal(c.SourceTags)
			_, _ = pool.Exec(ctx, `UPDATE speed_corridors SET metadata = $1::jsonb WHERE region_code = $2 AND external_id = $3`,
				string(tagsJSON), c.RegionCode, c.ExternalID)
		}
		corridorsUpserted++
	}

	_ = UpdateImportCounts(ctx, pool, runID, len(cameras)+len(corridors), camerasUpserted+corridorsUpserted)
	return camerasUpserted, corridorsUpserted, nil
}

func ImportCorridors(ctx context.Context, pool *pgxpool.Pool, corridors []normalize.CorridorRecord, sourceName, region string) (int, error) {
	sourceID, runID, err := BeginImport(ctx, pool, sourceName, "overpass", region)
	if err != nil {
		return 0, err
	}
	defer func() {
		_ = FinishImport(ctx, pool, runID, err)
	}()

	upserted := 0
	for _, c := range corridors {
		if region != "" && c.RegionCode != region {
			continue
		}
		gates := make([]GateInput, len(c.Gates))
		for i, g := range c.Gates {
			gates[i] = GateInput{
				GateType:     g.GateType,
				Lat:          g.Lat,
				Lon:          g.Lon,
				RadiusM:      g.RadiusM,
				Sequence:     g.Sequence,
				DirectionDeg: g.DirectionDeg,
			}
		}
		if err = UpsertCorridor(ctx, pool, c.ExternalID, c.Name, c.RegionCode, c.MaxspeedKmh, c.LengthM, c.Direction, gates, sourceID); err != nil {
			return upserted, err
		}
		upserted++
	}
	_ = UpdateImportCounts(ctx, pool, runID, len(corridors), upserted)
	return upserted, nil
}
