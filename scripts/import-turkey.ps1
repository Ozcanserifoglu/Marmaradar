# Download Geofabrik Turkey extract and import cameras + corridors into PostGIS.
# Prerequisites: docker compose up -d db

param(
    [string]$Region = "",
    [switch]$ForceDownload
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$DataDir = if ($env:DATA_DIR) { $env:DATA_DIR } else { Join-Path $Root "data-pipeline\data" }
$PbfUrl = if ($env:PBF_URL) { $env:PBF_URL } else { "https://download.geofabrik.de/europe/turkey-latest.osm.pbf" }
$PbfFile = if ($env:PBF_FILE) { $env:PBF_FILE } else { Join-Path $DataDir "turkey-latest.osm.pbf" }
$DbUrl = "postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable"

function Invoke-Importer {
    param([string[]]$ImporterArgs)
    & go run ./cmd/importer @ImporterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "importer failed (exit $LASTEXITCODE)"
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

New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

if ($ForceDownload -or -not (Test-Path $PbfFile)) {
    Write-Host "Downloading Turkey PBF from Geofabrik..."
    Invoke-WebRequest -Uri $PbfUrl -OutFile $PbfFile
} else {
    Write-Host "Using existing PBF: $PbfFile"
    Write-Host "Pass -ForceDownload to re-download."
}

$env:DATABASE_URL = $DbUrl
$importerArgs = @("-mode", "pbf", "-file", $PbfFile)
if ($Region) {
    $importerArgs += @("-region", $Region)
}

Push-Location "$Root\data-pipeline"
try {
    $filterLabel = if ($Region) { $Region } else { "all" }
    Write-Host "Importing from PBF (region filter: $filterLabel)..."
    Invoke-Importer $importerArgs
} finally {
    Pop-Location
}

Write-Host "Turkey PBF import complete."
