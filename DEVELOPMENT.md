# Development

Developer setup for **Marmaradar**. For a product overview, see [README.md](README.md).

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

### Turkey-wide import (Geofabrik PBF)

Downloads `turkey-latest.osm.pbf` from Geofabrik and imports fixed cameras plus average-speed corridors:

```bash
# Windows:
.\scripts\import-turkey.ps1
# macOS/Linux:
./scripts/import-turkey.sh
```

Other import modes:

```bash
cd data-pipeline
# Offline PBF (after download):
go run ./cmd/importer -mode pbf -file data/turkey-latest.osm.pbf -region ""
# Tiled Overpass fallback (slower, rate-limited):
go run ./cmd/importer -mode overpass-tiles -region ""
# Community POI CSV (lat,lon,speed,direction):
go run ./cmd/importer -mode poi-csv -file path/to/radars.csv
# Road-following corridor geometry via OSRM (run after corridors are imported;
# fills speed_corridors.route_polyline so the app can paint the actual road):
go run ./cmd/importer -mode enrich-routes
# Recompute all corridors, or use a self-hosted OSRM:
go run ./cmd/importer -mode enrich-routes -force -osrm https://router.project-osrm.org
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

One-command run (API + app):

```bash
./scripts/run-local-mobile.sh
```

By default it starts local gateway + local API wired to `LIVE_DATABASE_URL` (live DB).
Set `LIVE_DATABASE_URL` in `.env.local` (gitignored). You can copy `.env.local.example`.

Run modes:

```bash
# local gateway + local API + LIVE_DATABASE_URL (default)
./scripts/run-local-mobile.sh

# local gateway + local API + local docker db
./scripts/run-local-mobile.sh --local

# direct production gateway
./scripts/run-local-mobile.sh --live
```

You can pass normal `flutter run` args through, for example:

```bash
./scripts/run-local-mobile.sh -d emulator-5554
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
| Production | http://34.59.226.182:8081 (GCP VM) |

Config lives in [`gateway/config/`](gateway/config/). Rate limits on `/v1/*`: 100 req/s global, 10 req/s per IP.

### Deploy API on Render

The API Dockerfile builds from the `backend/` directory (not the monorepo root). If the build fails with `"/backend": not found`, the Root Directory is wrong.

| Setting | Value |
|---------|-------|
| Root Directory | `backend` |
| Runtime | Docker |
| Dockerfile Path | `Dockerfile` (default inside `backend/`) |
| Port | `8080` |
| Region | Frankfurt |

Required env vars:

| Variable | Value |
|----------|-------|
| `DATABASE_URL` | Neon connection string (with password) |
| `PORT` | `8080` |

Migrations ship inside the image at `/migrations` — no extra volume needed.

### Deploy gateway on Render

Create a second Web Service (keep the existing Go API service):

| Setting | Value |
|---------|-------|
| Root Directory | `gateway` |
| Runtime | Docker |
| Port | `8080` |
| Region | Frankfurt |

No database env vars needed. On the GCP VM the gateway proxies to the `api` container (`http://api:8080`).

### GCP VM (current production)

The Flutter app talks to the KrakenD gateway at `http://34.59.226.182:8081`. Do **not** publish the Go API port (8080) to the internet.

Reserve the VM's external IP as **static** (VPC network → IP addresses). An ephemeral IP changes when the VM stops, which breaks every installed app until it is rebuilt.

Create `.env` on the VM before starting the stack — without `JWT_SECRET` the API signs tokens with the dev default published in this repo, and anyone can forge them:

```bash
printf 'JWT_SECRET=%s\n' "$(openssl rand -base64 48)" >> .env
```

Open **TCP 8081** in the VPC firewall so phones can reach the gateway.

1. Google Cloud Console → **VPC network** → **Firewall** → **Create firewall rule**
2. Targets: the VM's network tag (or all instances in the VPC)
3. Source IPv4 ranges: `0.0.0.0/0`
4. Protocols and ports: TCP `8081`
5. Recreate the API container so `GEO_RESTRICT_COUNTRIES=TR` is applied (`docker compose up -d`)

Country blocking is enforced in the Go API (`GEO_RESTRICT_COUNTRIES=TR`): public IPs outside Turkey get HTTP 403. `/health` stays open for checks. This is an application filter, not a packet filter — it does not replace Cloud Armor.

**VPC firewall cannot filter by country.** For edge-level geo blocking (drop traffic before it hits the VM):

1. Put an **HTTP(S) Load Balancer** in front of the VM (Network services → Load balancing)
2. **Network Security** → **Cloud Armor** → **Create security policy**
3. Default rule: **Deny** (403)
4. Add a higher-priority allow rule with match `origin.region_code == "TR"`
5. Attach the policy to the load balancer backend

Cloud Armor only works on a load balancer, not on the VM's raw external IP.

## Background location

The Flutter app uses `geolocator` with an Android foreground service notification. See `mobile/docs/BACKGROUND_LOCATION.md` for device testing notes and tracelet migration path.

## Security

This repo is public. Production secrets (`DATABASE_URL`, `JWT_SECRET`, signing keys) must live in the GCP VM environment and local `.env` files only — never in git. See [SECURITY.md](SECURITY.md).
