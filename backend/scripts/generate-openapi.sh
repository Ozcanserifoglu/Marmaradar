#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$(go env GOPATH)/bin:${PATH}"
swag init \
  -g cmd/api/main.go \
  -o docs \
  --parseDependency \
  --parseInternal \
  --outputTypes json,go
echo "Generated backend/docs/swagger.json"
