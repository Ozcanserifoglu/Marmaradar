#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/_run-importer.sh
source "$ROOT/scripts/_run-importer.sh"

export DATABASE_URL="${DATABASE_URL:-postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable}"
SKIP_OVERPASS="${SKIP_OVERPASS:-0}"

echo "Importing CSV cameras..."
run_importer -mode csv -file data/seed/bursa_cameras.csv

echo "Importing corridor JSON..."
run_importer -mode json -file data/seed/bursa_corridors.json

if [[ "$SKIP_OVERPASS" == "1" ]]; then
  echo "Skipping OSM Overpass import (SKIP_OVERPASS=1)."
else
  echo "Importing OSM Overpass (Bursa filter)..."
  run_importer -mode overpass -region bursa
fi

echo "Seed complete."
