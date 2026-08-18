#!/usr/bin/env bash
# Download Geofabrik Turkey extract and import cameras + corridors into PostGIS.
# Prerequisites: docker compose up -d db
# The VM does not need Go; Docker is used as a fallback.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/_run-importer.sh
source "$ROOT/scripts/_run-importer.sh"

DATA_DIR="${DATA_DIR:-$ROOT/data-pipeline/data}"
PBF_URL="${PBF_URL:-https://download.geofabrik.de/europe/turkey-latest.osm.pbf}"
PBF_FILE="${PBF_FILE:-$DATA_DIR/turkey-latest.osm.pbf}"
# Empty region = whole extract. Must be passed explicitly; importer default is "bursa".
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

# Path the importer sees (cwd / Docker mount is data-pipeline/).
if [[ "$PBF_FILE" == "$DATA_DIR/"* ]]; then
  PBF_ARG="data/${PBF_FILE#"$DATA_DIR"/}"
else
  PBF_ARG="$PBF_FILE"
fi

echo "Importing from PBF (region filter: ${REGION:-all})..."
run_importer -mode pbf -file "$PBF_ARG" -region "$REGION"

echo "Turkey PBF import complete."
