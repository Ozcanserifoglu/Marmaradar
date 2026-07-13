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

// ImportPOICSV reads community radar POI files (Waze/iGO/Garmin style).
// Supports:
//   - Headered CSV with lat,lon,maxspeed_kmh,direction_deg columns
//   - Headerless "lat,lon,speed,direction" rows
func ImportPOICSV(ctx context.Context, pool *pgxpool.Pool, path, sourceName string) (int, error) {
	f, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	sourceID, runID, err := store.BeginImport(ctx, pool, sourceName, "poi_csv", "")
	if err != nil {
		return 0, err
	}
	defer func() {
		_ = store.FinishImport(ctx, pool, runID, err)
	}()

	reader := csv.NewReader(f)
	reader.FieldsPerRecord = -1
	reader.TrimLeadingSpace = true

	first, err := reader.Read()
	if err != nil {
		return 0, err
	}

	col := indexColumns(first)
	hasHeader := looksLikeHeader(first)
	if !hasHeader {
		cam, parseErr := parsePOIRow(first, nil)
		if parseErr != nil {
			return 0, parseErr
		}
		if err = store.UpsertCamera(ctx, pool, cam, sourceID); err != nil {
			return 0, err
		}
	}

	upserted := 0
	if hasHeader {
		// first row was header; data starts on next Read
	} else {
		upserted = 1
	}

	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return upserted, err
		}
		cam, err := parsePOIRow(row, col)
		if err != nil {
			continue
		}
		if err := store.UpsertCamera(ctx, pool, cam, sourceID); err != nil {
			return upserted, err
		}
		upserted++
	}
	_ = store.UpdateImportCounts(ctx, pool, runID, upserted, upserted)
	return upserted, nil
}

func looksLikeHeader(row []string) bool {
	if len(row) == 0 {
		return false
	}
	first := strings.ToLower(strings.TrimSpace(row[0]))
	return first == "lat" || first == "latitude" || first == "external_id"
}

func parsePOIRow(row []string, col map[string]int) (normalize.CameraRecord, error) {
	if col != nil && len(col) > 0 {
		return parseRow(row, col)
	}
	if len(row) < 2 {
		return normalize.CameraRecord{}, fmt.Errorf("row too short")
	}

	lat, err := strconv.ParseFloat(strings.TrimSpace(row[0]), 64)
	if err != nil {
		return normalize.CameraRecord{}, err
	}
	lon, err := strconv.ParseFloat(strings.TrimSpace(row[1]), 64)
	if err != nil {
		return normalize.CameraRecord{}, err
	}

	cam := normalize.CameraRecord{
		ExternalID: fmt.Sprintf("poi:%f:%f", lat, lon),
		RegionCode: normalize.RegionForPoint(lat, lon),
		Lat:        lat,
		Lon:        lon,
		CameraType: "fixed",
		Active:     true,
		Confidence: 0.6,
	}
	if len(row) > 2 && strings.TrimSpace(row[2]) != "" {
		if v, err := strconv.Atoi(strings.TrimSpace(row[2])); err == nil {
			i := int16(v)
			cam.MaxspeedKmh = &i
		}
	}
	if len(row) > 3 && strings.TrimSpace(row[3]) != "" {
		if v, err := strconv.Atoi(strings.TrimSpace(row[3])); err == nil {
			i := int16(v)
			cam.DirectionDeg = &i
		}
	}
	return cam, nil
}
