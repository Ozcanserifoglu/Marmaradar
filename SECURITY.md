# Security

## What is safe in this public repo

| Item | Status |
|------|--------|
| Public gateway address in the Flutter client | OK — every installed app contains it |
| Local Docker DB password (`radar` / `radar` in `docker-compose.yml`) | OK — local only |
| Camera/corridor seed data | OK — public road data |
| Overpass / Geofabrik endpoints | OK — public OSM |
| Marketing site, legal pages, beta APK path | OK — public by design |
| Google Sign-In **Web** client ID in `mobile/dart_defines.oauth.json` | OK — OAuth client IDs are not secrets; restrict the client in Google Cloud |

## What must NEVER be committed

| Secret | Where it belongs |
|--------|------------------|
| `DATABASE_URL` with a real password | GCP VM env |
| `JWT_SECRET` | GCP VM env |
| `GOOGLE_OAUTH_CLIENT_IDS` / `APPLE_OAUTH_CLIENT_IDS` | VM env |
| `GOOGLE_MAPS_API_KEY` / `GOOGLE_TTS_API_KEY` | VM env; restrict keys in Google Cloud |
| `RESEND_API_KEY` | VM env |
| Android signing keystore (`.jks` / `.keystore`, `key.properties`) | Local / CI secrets |
| `MapsSecrets.xcconfig` / `GoogleSignInSecrets.xcconfig` with real values | Gitignored local files (use the `.example` copies) |
| Any `.env` / `.env.local` with real credentials | Local only |
| Firebase `google-services.json` | Not used; keep out of git if added |

Use [`.env.example`](.env.example) as a template. Never push `.env`.

## If a secret was ever committed

1. **Rotate immediately** (DB password, JWT secret, API keys, Resend).
2. Remove from git history (`git filter-repo` or BFG); a later delete is not enough.
3. Enable GitHub **secret scanning**.

## Production exposure

- Publish only the gateway (TCP 8081). Keep the Go API on the Docker network.
- `GEO_RESTRICT_COUNTRIES=TR` is an application filter, not Cloud Armor.
- Do not put unrestricted API keys in the Flutter or web binaries. OAuth client IDs are expected in the app; Maps keys must be package/bundle restricted.
- Gateway traffic is still **plain HTTP**. Android cleartext and iOS arbitrary loads are enabled. Tokens and drive uploads are readable on hostile networks. Terminate TLS in front of the gateway and drop cleartext before a store release.
- The public beta APK is a sideload, not a Play Store build. Users accept that risk in [Kullanım Şartları](https://www.marmaradar.com/kullanim-sartlari). Host only builds you produced.

## Privacy / data

Location, accounts, and trip uploads are described at [Gizlilik](https://www.marmaradar.com/gizlilik). There is no in-app account-deletion API yet; deletion is by email ([marmaradar@gmail.com](mailto:marmaradar@gmail.com)).

## Report issues

Open a **private** GitHub security advisory or email [marmaradar@gmail.com](mailto:marmaradar@gmail.com). Do not post credentials in public issues.
