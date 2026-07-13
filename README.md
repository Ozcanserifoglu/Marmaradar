# Radar Alert

Cross-platform mobile app that warns drivers about fixed speed cameras (EDS) and average-speed corridors in the Marmara region (Bursa-first).

## Stack

| Component | Technology |
|-----------|------------|
| Mobile | Flutter, Riverpod, Drift, geolocator |
| Backend | Go, Chi, pgx, PostGIS |
| API Gateway | KrakenD (rate limiting, reverse proxy) |
| Data pipeline | Go CLI, Overpass API, CSV/JSON importers |

## Quick start

### Database + API (via KrakenD gateway)

```bash
docker compose up -d
```

Gateway (public entry): http://localhost:8081/health

> **Note:** Port `8081` is KrakenD. The Go API runs on the internal Docker network only (`api:8080`). Port `5433` is Postgres on the host.

### Import data

```bash
docker compose up -d
# Windows:
.\scripts\seed-bursa.ps1
# macOS/Linux:
./scripts/seed-bursa.sh
```

Or manually:

```bash
cd data-pipeline
go run ./cmd/importer -mode csv -file data/seed/bursa_cameras.csv
go run ./cmd/importer -mode json -file data/seed/bursa_corridors.json
go run ./cmd/importer -mode overpass -region bursa
```

### Backend (local)

```bash
cd backend
set DATABASE_URL=postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable
go run ./cmd/api
```

### Mobile

```bash
cd mobile
flutter pub get
dart run build_runner build
flutter run
```

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness |
| GET | `/v1/cameras/nearby?lat=&lon=&radius_m=1000&region=bursa` | Cameras in radius |
| GET | `/v1/corridors/nearby?lat=&lon=&region=bursa` | Corridors at point |
| GET | `/v1/sync?region=bursa&bbox=w,s,e,n&since=` | Delta sync for mobile |

## API gateway (KrakenD)

All client traffic should go through KrakenD, not the Go API directly.

| Environment | Entry URL |
|-------------|-----------|
| Local | http://localhost:8081 |
| Production | https://marmaradar-gateway.onrender.com |

Config lives in [`gateway/config/`](gateway/config/). Rate limits on `/v1/*`: 100 req/s global, 10 req/s per IP.

### Deploy gateway on Render

Create a second Web Service (keep the existing Go API service):

| Setting | Value |
|---------|-------|
| Root Directory | `gateway` |
| Runtime | Docker |
| Port | `8080` |
| Region | Frankfurt |

No database env vars needed. The gateway proxies to `https://marmaradar.onrender.com`.

## Background location

The Flutter app uses `geolocator` with an Android foreground service notification. See `mobile/docs/BACKGROUND_LOCATION.md` for device testing notes and tracelet migration path.
