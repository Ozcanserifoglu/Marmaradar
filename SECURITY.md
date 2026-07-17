# Security

## What is safe in this public repo

| Item | Status |
|------|--------|
| Public API URLs (`marmaradar.onrender.com`, `marmaradar-gateway.onrender.com`) | OK — clients need these |
| Local dev DB password (`radar` / `radar` in `docker-compose.yml`) | OK — local Docker only, not production |
| Camera/corridor seed data | OK — public road infrastructure data |
| Overpass API endpoints | OK — public OSM services |

## What must NEVER be committed

| Secret | Where it belongs |
|--------|------------------|
| Neon `DATABASE_URL` (with real password) | Render → API service → Environment |
| `JWT_SECRET` (signs access tokens) | Render → API service → Environment |
| Render deploy keys / API tokens | Render dashboard only |
| Android signing keystore (`.jks`, `key.properties`) | Local machine / CI secrets |
| Firebase `google-services.json` | Not used yet; keep out of git if added |
| Any `.env` file with real credentials | Local only, gitignored |

Use [`.env.example`](.env.example) as a template. Copy to `.env` locally; never push `.env`.

## If a secret was ever committed

1. **Rotate immediately** — change the Neon DB password in Neon dashboard, update Render `DATABASE_URL`
2. Remove from git history (`git filter-repo` or BFG) — deleting a file in a new commit is not enough; bots scan history
3. Enable GitHub **secret scanning** (Settings → Code security) on the repo

## Production exposure

- The Go API (`marmaradar.onrender.com`) is still publicly reachable. KrakenD rate-limits traffic through the gateway but does not block direct API access.
- Do not put API keys or auth tokens in the Flutter app — anything in the mobile binary can be extracted.

## Report issues

If you find a vulnerability, open a private GitHub security advisory or contact the maintainer directly. Do not post credentials in public issues.
