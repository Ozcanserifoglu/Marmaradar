#!/usr/bin/env bash
# Download Geofabrik Turkey extract and import cameras + corridors into PostGIS.
# Prerequisites: docker compose up -d db
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="${DATA_DIR:-$ROOT/data-pipeline/data}"
PBF_URL="${PBF_URL:-https://download.geofabrik.de/europe/turkey-latest.osm.pbf}"
PBF_FILE="${PBF_FILE:-$DATA_DIR/turkey-latest.osm.pbf}"
REGION="${REGION:-}"
export DATABASE_URL="${DATABASE_URL:-postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable}"

mkdir -p "$DATA_DIR"

if [[ ! -f "$PBF_FILE" ]]; then
  echo "Downloading Turkey PBF from Geofabrik..."
  curl -L --fail -o "$PBF_FILE" "$PBF_URL"
else
  echo "Using existing PBF: $PBF_FILE"
  echo "Delete the file or set PBF_FILE to force a re-download."
fi

IMPORTER_ARGS=(-mode pbf -file "$PBF_FILE")
if [[ -n "$REGION" ]]; then
  IMPORTER_ARGS+=(-region "$REGION")
fi

echo "Importing from PBF (region filter: ${REGION:-all})..."
(cd "$ROOT/data-pipeline" && go run ./cmd/importer "${IMPORTER_ARGS[@]}")

echo "Turkey PBF import complete."
