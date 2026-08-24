# Development

Developer setup for **Marmaradar**. Product overview: [README.md](README.md). Secrets: [SECURITY.md](SECURITY.md).

## Repo layout

| Path | Role |
|------|------|
| `mobile/` | Flutter app (Android / iOS) |
| `backend/` | Go API (Chi, pgx, PostGIS) |
| `gateway/` | KrakenD reverse proxy + rate limits |
| `data-pipeline/` | Go importer (CSV, JSON, Overpass, PBF, OSRM enrich) |
| `web/` | Vite + React site ([marmaradar.com](https://www.marmaradar.com)) |

## Stack

| Component | Technology |
|-----------|------------|
| Mobile | Flutter, Riverpod, Drift, geolocator, Google Maps |
| Website | Vite, React, React Router (Vercel SPA rewrites in `web/vercel.json`) |
| Backend | Go, Chi, pgx, PostGIS |
| API gateway | KrakenD (image `krakend:2.13`) |
| Email | Resend |
| Data pipeline | Go CLI, Overpass, Geofabrik PBF, OSRM |

`docker compose up` Postgres (`docker-compose.yml`): user/password/db **`radar` / `radar` / `radar_alert`**, host port **5433**.

```
postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable
```

The API reads this as `DATABASE_URL`. Some importer defaults and `.env.example` still use older `radar:radar` / `radar_alert` values — prefer the compose URL when the stack is running.

## Quick start

### Database + API (via KrakenD)

```bash
docker compose up -d
```

- Gateway: http://localhost:8081/health
- Port **8081** is KrakenD. The Go API is `api:8080` on the Docker network only.
- Host Postgres: **5433**.

Copy [`.env.example`](.env.example) to `.env` for local overrides. Production secrets stay on the VM.

### Import data

```bash
docker compose up -d
export DATABASE_URL=postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable
# Windows:
.\scripts\seed-bursa.ps1
# macOS/Linux:
./scripts/seed-bursa.sh
```

Or:

```bash
cd data-pipeline
go run ./cmd/importer -mode csv -file data/seed/bursa_cameras.csv
go run ./cmd/importer -mode json -file data/seed/bursa_corridors.json
go run ./cmd/importer -mode overpass -region bursa
```

### Turkey-wide import (Geofabrik PBF)

```bash
.\scripts\import-turkey.ps1   # Windows
./scripts/import-turkey.sh    # macOS/Linux
```

Importer `-mode` values: `overpass`, `overpass-tiles`, `csv`, `poi-csv`, `json`, `pbf`, `enrich-routes`.

```bash
cd data-pipeline
go run ./cmd/importer -mode pbf -file data/turkey-latest.osm.pbf -region ""
go run ./cmd/importer -mode enrich-routes
go run ./cmd/importer -mode enrich-routes -force -osrm https://router.project-osrm.org
```

### Backend (without Docker API)

```bash
cd backend
export DATABASE_URL=postgres://radar:radar@127.0.0.1:5433/radar_alert?sslmode=disable
go run ./cmd/api
```

### Website

```bash
cd web
npm install
cp .env.example .env   # VITE_API_BASE_URL=http://localhost:8081
npm run dev
```

Dev server: http://localhost:5173

Routes: `/`, `/changelog`, `/reset-password`, `/gizlilik`, `/kullanim-sartlari`.  
Beta APK: `web/public/downloads/marmaradar-beta.apk`.

### Mobile

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=dart_defines.oauth.json
```

Copy the gitignored runner from the example:

```bash
cp scripts/run-local-mobile.sh.example scripts/run-local-mobile.sh
chmod +x scripts/run-local-mobile.sh
./scripts/run-local-mobile.sh
```

Default mode: local gateway + API with `LIVE_DATABASE_URL` from `.env.local` (see `.env.local.example`). Overlay file: `docker-compose.live-db.yml`.

```bash
./scripts/run-local-mobile.sh                 # local + live DB (default)
./scripts/run-local-mobile.sh --local         # compose Postgres
./scripts/run-local-mobile.sh --live          # production gateway
./scripts/run-local-mobile.sh -d emulator-5554
```

Debug/profile API (`RADAR_API_URL`): Android emulator `http://10.0.2.2:8081`, iOS/desktop `http://127.0.0.1:8081`. Release builds use `_productionBaseUrl` in `mobile/lib/data/api/radar_api_client.dart`.

Release builds (Web client ID from `mobile/dart_defines.oauth.json`):

```bash
./scripts/build-release-mobile.sh appbundle
./scripts/build-release-mobile.sh apk
./scripts/build-release-mobile.sh ipa
```

Publish a site beta by copying the APK to `web/public/downloads/marmaradar-beta.apk`.

## API (gateway → Go)

Call **KrakenD on 8081**, not port 8080.

| Method | Path | Notes |
|--------|------|--------|
| GET | `/health` | Liveness |
| GET | `/v1/cameras/nearby` | `lat`, `lon`, `radius_m`, `region` |
| GET | `/v1/corridors/nearby` | `lat`, `lon`, `region` |
| GET | `/v1/sync` | `region`, `bbox`, `since` |
| GET | `/v1/live-reports/active` | Crowd reports |
| POST | `/v1/auth/register` `/login` `/refresh` `/oauth` | Accounts |
| POST | `/v1/auth/forgot-password` `/reset-password` | Email reset |

JWT: `/v1/drives`, `GET /v1/users/me/stats`, `/v1/reports`, `/v1/live-reports`, `POST /v1/eta/cameras`, `POST /v1/amenities/cells`, `/v1/tts/speak`, `/v1/tts/catalog`.

Reset emails use `EMAIL_APP_BASE_URL` (default `https://marmaradar.com`) + `/reset-password?token=…`. The site posts to `POST /v1/auth/reset-password`.

Gateway: [`gateway/config/krakend.tmpl`](gateway/config/krakend.tmpl).

## Production

- **Website:** https://www.marmaradar.com (Vite `web/`, Vercel).
- **API:** GCP VM + Docker Compose. Release apps use `_productionBaseUrl` in `radar_api_client.dart`. Do not expose API 8080.
- **CI:** `.github/workflows/ci.yml`. Deploy: `.github/workflows/deploy.yml`.
- **Render:** `render.yaml` is an alternate blueprint; current production is the GCP VM.

Reserve a **static** external IP. Set `JWT_SECRET` on the VM or tokens can be forged with the published dev default:

```bash
printf 'JWT_SECRET=%s\n' "$(openssl rand -base64 48)" >> .env
```

```bash
echo 'GOOGLE_OAUTH_CLIENT_IDS=WEB_CLIENT_ID,IOS_CLIENT_ID,ANDROID_CLIENT_ID' >> .env
echo 'APPLE_OAUTH_CLIENT_IDS=com.radaralert.radarAlert' >> .env
```

App IDs: Android `com.radaralert.radar_alert`, iOS `com.radaralert.radarAlert`.

### Google / Apple Sign-In

**Google Cloud:** OAuth consent screen; Web + Android (`com.radaralert.radar_alert` + SHA-1/256) + iOS (`com.radaralert.radarAlert`) client IDs; all in `GOOGLE_OAUTH_CLIENT_IDS`. Flutter Web client ID: `GOOGLE_SERVER_CLIENT_ID` in `mobile/dart_defines.oauth.json`.

```bash
flutter run --dart-define-from-file=dart_defines.oauth.json
```

iOS also needs `GOOGLE_IOS_CLIENT_ID` and `mobile/ios/Flutter/GoogleSignInSecrets.xcconfig`.

**Apple:** App ID `com.radaralert.radarAlert` → Sign In with Apple; `APPLE_OAUTH_CLIENT_IDS=com.radaralert.radarAlert`.

Open **TCP 8081**. `GEO_RESTRICT_COUNTRIES=TR` rejects public IPs outside Turkey (`/health` stays open). Use Cloud Armor on an HTTP(S) load balancer for packet-level geo blocking.

## Background location

[`mobile/docs/BACKGROUND_LOCATION.md`](mobile/docs/BACKGROUND_LOCATION.md).

## Backend env (`backend/internal/config`)

`DATABASE_URL`, `PORT`, `MIGRATIONS_DIR`, `JWT_SECRET`, `GOOGLE_OAUTH_CLIENT_IDS`, `APPLE_OAUTH_CLIENT_IDS`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_TTS_API_KEY`, `RESEND_API_KEY`, `RESEND_FROM`, `RESEND_REPLY_TO`, `EMAIL_APP_BASE_URL`, `GEO_RESTRICT_COUNTRIES`, TTS cache/voice flags.
