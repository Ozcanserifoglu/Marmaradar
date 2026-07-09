# Seed Bursa data into PostgreSQL
# Prerequisites: docker compose up -d db

param(
    [switch]$SkipOverpass
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
# Use 5433 — host port mapped in docker-compose (avoids local PostgreSQL on 5432)
$DbUrl = "postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable"

function Invoke-Importer {
    param([string[]]$ImporterArgs)
    & go run ./cmd/importer @ImporterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "importer failed (exit $LASTEXITCODE): go run ./cmd/importer $($ImporterArgs -join ' ')"
    }
}

Write-Host "Waiting for database on 127.0.0.1:5433..."
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    $cid = docker compose -f "$Root\docker-compose.yml" ps -q db 2>$null
    if ($cid) {
        docker exec $cid pg_isready -U radar -d radar_alert 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ready = $true
            break
        }
    }
    Start-Sleep -Seconds 2
}
if (-not $ready) {
    throw "Database not ready. Run: docker compose up -d db"
}

$env:DATABASE_URL = $DbUrl

Push-Location "$Root\data-pipeline"
try {
    Write-Host "Importing CSV cameras..."
    Invoke-Importer @("-mode", "csv", "-file", "data/seed/bursa_cameras.csv")

    Write-Host "Importing corridor JSON..."
    Invoke-Importer @("-mode", "json", "-file", "data/seed/bursa_corridors.json")

    if (-not $SkipOverpass) {
        Write-Host "Importing OSM Overpass (Bursa filter, optional)..."
        try {
            Invoke-Importer @("-mode", "overpass", "-region", "bursa")
        } catch {
            Write-Warning "OSM Overpass import failed (CSV/JSON seed is still usable): $_"
            Write-Warning "Retry later or run: .\scripts\seed-bursa.ps1 -SkipOverpass"
        }
    } else {
        Write-Host "Skipping OSM Overpass import (-SkipOverpass)."
    }
}
finally {
    Pop-Location
}

Write-Host "Seed complete."
