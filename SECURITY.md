# Security

## What is safe in this public repo

| Item | Status |
|------|--------|
| Public gateway address in the Flutter client | OK — every installed app contains it; an open port is discoverable anyway |
| Local dev DB password (`radar` / `radar` in `docker-compose.yml`) | OK — local Docker only, not production |
| Camera/corridor seed data | OK — public road infrastructure data |
| Overpass API endpoints | OK — public OSM services |

## What must NEVER be committed

| Secret | Where it belongs |
|--------|------------------|
| Neon `DATABASE_URL` (with real password) | GCP VM / Cloud Run env, never git |
| `JWT_SECRET` (signs access tokens) | GCP VM / Cloud Run env, never git |
| `GOOGLE_MAPS_API_KEY` (Roads snap-to-road on the API) | GCP VM / Cloud Run env, never git |
| `GOOGLE_TTS_API_KEY` (Cloud Text-to-Speech proxy; falls back to Maps key) | GCP VM / Cloud Run env, never git |
| Render deploy keys / API tokens | Render dashboard only (legacy) |
| Android signing keystore (`.jks`, `key.properties`) | Local machine / CI secrets |
| Firebase `google-services.json` | Not used yet; keep out of git if added |
| Any `.env` file with real credentials | Local only, gitignored |

Use [`.env.example`](.env.example) as a template. Copy to `.env` locally; never push `.env`.

## If a secret was ever committed

1. **Rotate immediately** — change the DB password and update `DATABASE_URL` on the VM
2. Remove from git history (`git filter-repo` or BFG) — deleting a file in a new commit is not enough; bots scan history
3. Enable GitHub **secret scanning** (Settings → Code security) on the repo

## Production exposure

- Publish only the gateway (TCP 8081) on the GCP VM. Keep the Go API on the Docker network.
- `GEO_RESTRICT_COUNTRIES=TR` rejects public IPs outside Turkey at the API. For packet-level geo blocking, use Cloud Armor on an HTTP(S) Load Balancer (see DEVELOPMENT.md).
- Do not put API keys or auth tokens in the Flutter app — anything in the mobile binary can be extracted.
- Traffic to the gateway is plain HTTP, so the app allows cleartext (`usesCleartextTraffic` on Android, `NSAllowsArbitraryLoads` on iOS). Tokens and drive uploads are therefore readable on hostile networks. Terminate TLS in front of the gateway and remove both flags before a store release.

## Report issues

If you find a vulnerability, open a private GitHub security advisory or contact the maintainer directly. Do not post credentials in public issues.
