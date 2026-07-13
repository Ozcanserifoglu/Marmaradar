package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/data-pipeline/internal/csvimporter"
	"github.com/radar-alert/data-pipeline/internal/enrich"
	"github.com/radar-alert/data-pipeline/internal/overpass"
	"github.com/radar-alert/data-pipeline/internal/pbf"
	"github.com/radar-alert/data-pipeline/internal/store"
)

func main() {
	mode := flag.String("mode", "overpass", "import mode: overpass, overpass-tiles, csv, poi-csv, json, pbf, enrich-routes")
	region := flag.String("region", "bursa", "region filter (empty = all regions)")
	file := flag.String("file", "", "path to CSV, JSON, or PBF file")
	dbURL := flag.String("db", envOr("DATABASE_URL", "postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable"), "database URL")
	osrmURL := flag.String("osrm", envOr("OSRM_URL", enrich.DefaultOSRMBaseURL), "OSRM base URL for enrich-routes mode")
	force := flag.Bool("force", false, "enrich-routes: recompute corridors that already have geometry")
	flag.Parse()

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, *dbURL)
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}
	defer pool.Close()

	switch *mode {
	case "overpass":
		client := overpass.NewClient()
		result, err := client.Fetch(ctx)
		if err != nil {
			log.Fatalf("overpass fetch: %v", err)
		}
		n, err := store.ImportOverpassCameras(ctx, pool, result.Cameras, *region)
		if err != nil {
			log.Fatalf("import cameras: %v", err)
		}
		fmt.Printf("imported %d cameras from OSM (region=%s)\n", n, *region)

	case "overpass-tiles":
		client := overpass.NewClient()
		tiles := overpass.TurkeyTileGrid()
		log.Printf("fetching %d Overpass tiles for Turkey...", len(tiles))
		result, err := client.FetchTiled(ctx, tiles)
		if err != nil {
			log.Fatalf("overpass tiled fetch: %v", err)
		}
		camN, err := store.ImportOverpassCameras(ctx, pool, result.Cameras, *region)
		if err != nil {
			log.Fatalf("import cameras: %v", err)
		}
		nodeMap := overpass.BuildNodeMap(result.Nodes)
		corridors := overpass.RelationsToCorridors(result.Relations, nodeMap)
		corrN, err := store.ImportCorridors(ctx, pool, corridors, "osm_overpass_tiles", *region)
		if err != nil {
			log.Fatalf("import corridors: %v", err)
		}
		fmt.Printf("imported %d cameras and %d corridors from tiled Overpass (region=%s)\n", camN, corrN, *region)

	case "csv":
		if *file == "" {
			log.Fatal("-file is required for csv mode")
		}
		n, err := csvimporter.ImportCSV(ctx, pool, *file, "manual_csv")
		if err != nil {
			log.Fatalf("csv import: %v", err)
		}
		fmt.Printf("imported %d cameras from CSV\n", n)

	case "poi-csv":
		if *file == "" {
			log.Fatal("-file is required for poi-csv mode")
		}
		n, err := csvimporter.ImportPOICSV(ctx, pool, *file, "community_poi")
		if err != nil {
			log.Fatalf("poi-csv import: %v", err)
		}
		fmt.Printf("imported %d cameras from community POI CSV\n", n)

	case "json":
		if *file == "" {
			log.Fatal("-file is required for json mode")
		}
		n, err := csvimporter.ImportJSON(ctx, pool, *file, "manual_json")
		if err != nil {
			log.Fatalf("json import: %v", err)
		}
		fmt.Printf("imported %d corridors from JSON\n", n)

	case "pbf":
		if *file == "" {
			log.Fatal("-file is required for pbf mode")
		}
		log.Printf("parsing PBF file %s (this may take a few minutes)...", *file)
		result, err := pbf.ParseFile(*file)
		if err != nil {
			log.Fatalf("pbf parse: %v", err)
		}
		camN, corrN, err := store.ImportPBF(ctx, pool, result.Cameras, result.Corridors, *region)
		if err != nil {
			log.Fatalf("pbf import: %v", err)
		}
		fmt.Printf("imported %d cameras and %d corridors from PBF (region=%s)\n", camN, corrN, *region)

	case "enrich-routes":
		n, err := enrich.Corridors(ctx, pool, *osrmURL, *force)
		if err != nil {
			log.Fatalf("enrich routes: %v", err)
		}
		fmt.Printf("enriched %d corridors with road-following geometry\n", n)

	default:
		log.Fatalf("unknown mode: %s", *mode)
	}
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
