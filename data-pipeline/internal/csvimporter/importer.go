package csvimporter

import (
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/data-pipeline/internal/normalize"
	"github.com/radar-alert/data-pipeline/internal/store"
)

func ImportCSV(ctx context.Context, pool *pgxpool.Pool, path, sourceName string) (int, error) {
	f, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	sourceID, runID, err := store.BeginImport(ctx, pool, sourceName, "csv", "")
	if err != nil {
		return 0, err
	}
	defer func() {
		_ = store.FinishImport(ctx, pool, runID, err)
	}()

	reader := csv.NewReader(f)
	header, err := reader.Read()
	if err != nil {
		return 0, err
	}
	col := indexColumns(header)

	upserted := 0
	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return upserted, err
		}
		cam, err := parseRow(row, col)
		if err != nil {
			return upserted, err
		}
		if err := store.UpsertCamera(ctx, pool, cam, sourceID); err != nil {
			return upserted, err
		}
		upserted++
	}
	_ = store.UpdateImportCounts(ctx, pool, runID, upserted, upserted)
	return upserted, nil
}

func indexColumns(header []string) map[string]int {
	idx := make(map[string]int, len(header))
	for i, h := range header {
		idx[strings.TrimSpace(strings.ToLower(h))] = i
	}
	return idx
}

func parseRow(row []string, col map[string]int) (normalize.CameraRecord, error) {
	get := func(name string) string {
		i, ok := col[name]
		if !ok || i >= len(row) {
			return ""
		}
		return strings.TrimSpace(row[i])
	}

	lat, err := strconv.ParseFloat(get("lat"), 64)
	if err != nil {
		return normalize.CameraRecord{}, fmt.Errorf("invalid lat: %w", err)
	}
	lon, err := strconv.ParseFloat(get("lon"), 64)
	if err != nil {
		return normalize.CameraRecord{}, fmt.Errorf("invalid lon: %w", err)
	}

	region := get("region_code")
	if region == "" {
		region = normalize.RegionForPoint(lat, lon)
	}

	cam := normalize.CameraRecord{
		ExternalID: get("external_id"),
		RegionCode: region,
		Lat:        lat,
		Lon:        lon,
		RoadName:   get("road_name"),
		CameraType: get("type"),
		Active:     strings.ToLower(get("active")) != "false",
		Confidence: 0.9,
	}
	if cam.ExternalID == "" {
		cam.ExternalID = fmt.Sprintf("csv:%f:%f", lat, lon)
	}
	if cam.CameraType == "" {
		cam.CameraType = "fixed"
	}
	if ms := get("maxspeed_kmh"); ms != "" {
		v, _ := strconv.Atoi(ms)
		i := int16(v)
		cam.MaxspeedKmh = &i
	}
	if d := get("direction_deg"); d != "" {
		v, _ := strconv.Atoi(d)
		i := int16(v)
		cam.DirectionDeg = &i
	}
	return cam, nil
}
