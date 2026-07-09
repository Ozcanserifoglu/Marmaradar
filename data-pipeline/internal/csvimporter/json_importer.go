package csvimporter

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/data-pipeline/internal/store"
)

type corridorFile struct {
	Corridors []corridorRecord `json:"corridors"`
}

type corridorRecord struct {
	ExternalID  string       `json:"external_id"`
	Name        string       `json:"name"`
	MaxspeedKmh int16        `json:"maxspeed_kmh"`
	LengthM     float64      `json:"length_m"`
	RegionCode  string       `json:"region_code"`
	Direction   string       `json:"direction"`
	Gates       []gateRecord `json:"gates"`
}

type gateRecord struct {
	GateType     string  `json:"gate_type"`
	Lat          float64 `json:"lat"`
	Lon          float64 `json:"lon"`
	RadiusM      float32 `json:"radius_m"`
	Sequence     int16   `json:"sequence"`
	DirectionDeg *int16  `json:"direction_deg"`
}

func ImportJSON(ctx context.Context, pool *pgxpool.Pool, path, sourceName string) (int, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return 0, err
	}

	var file corridorFile
	if err := json.Unmarshal(data, &file); err != nil {
		return 0, err
	}

	sourceID, runID, err := store.BeginImport(ctx, pool, sourceName, path, "")
	if err != nil {
		return 0, err
	}
	defer func() {
		_ = store.FinishImport(ctx, pool, runID, err)
	}()

	upserted := 0
	for _, c := range file.Corridors {
		if c.Direction == "" {
			c.Direction = "both"
		}
		gates := make([]store.GateInput, len(c.Gates))
		for i, g := range c.Gates {
			gates[i] = store.GateInput{
				GateType:     g.GateType,
				Lat:          g.Lat,
				Lon:          g.Lon,
				RadiusM:      g.RadiusM,
				Sequence:     g.Sequence,
				DirectionDeg: g.DirectionDeg,
			}
		}
		if err := store.UpsertCorridor(ctx, pool, c.ExternalID, c.Name, c.RegionCode, c.MaxspeedKmh, c.LengthM, c.Direction, gates, sourceID); err != nil {
			return upserted, fmt.Errorf("corridor %s: %w", c.ExternalID, err)
		}
		upserted++
	}
	_ = store.UpdateImportCounts(ctx, pool, runID, len(file.Corridors), upserted)
	return upserted, nil
}
