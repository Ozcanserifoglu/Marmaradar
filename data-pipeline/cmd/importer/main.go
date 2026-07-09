package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/data-pipeline/internal/csvimporter"
	"github.com/radar-alert/data-pipeline/internal/overpass"
	"github.com/radar-alert/data-pipeline/internal/store"
)

func main() {
	mode := flag.String("mode", "overpass", "import mode: overpass, csv, json")
	region := flag.String("region", "bursa", "region filter for overpass import")
	file := flag.String("file", "", "path to CSV or JSON file")
	dbURL := flag.String("db", envOr("DATABASE_URL", "postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable"), "database URL")
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
	case "csv":
		if *file == "" {
			log.Fatal("-file is required for csv mode")
		}
		n, err := csvimporter.ImportCSV(ctx, pool, *file, "manual_csv")
		if err != nil {
			log.Fatalf("csv import: %v", err)
		}
		fmt.Printf("imported %d cameras from CSV\n", n)
	case "json":
		if *file == "" {
			log.Fatal("-file is required for json mode")
		}
		n, err := csvimporter.ImportJSON(ctx, pool, *file, "manual_json")
		if err != nil {
			log.Fatalf("json import: %v", err)
		}
		fmt.Printf("imported %d corridors from JSON\n", n)
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
