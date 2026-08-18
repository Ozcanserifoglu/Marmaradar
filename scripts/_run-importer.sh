# shellcheck shell=bash
# Sourced by import/seed scripts. Expects ROOT and DATABASE_URL.

run_importer() {
  if command -v go >/dev/null 2>&1; then
    (cd "$ROOT/data-pipeline" && go run ./cmd/importer "$@")
    return
  fi
  if command -v docker >/dev/null 2>&1; then
    echo "Go not installed; running importer with Docker (golang:1.22)..."
    docker run --rm \
      --network host \
      -v "$ROOT/data-pipeline:/src" \
      -w /src \
      -e DATABASE_URL="$DATABASE_URL" \
      golang:1.22 \
      go run ./cmd/importer "$@"
    return
  fi
  echo "Need the Go toolchain or Docker to run the importer." >&2
  exit 1
}
