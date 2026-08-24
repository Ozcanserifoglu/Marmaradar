# Marmaradar Web

Vite + React site for [www.marmaradar.com](https://www.marmaradar.com): marketing, changelog, password reset, legal pages, and the Android **beta APK**. Hosted as a SPA (`vercel.json` rewrites).

## Setup

```bash
cd web
npm install
cp .env.example .env   # VITE_API_BASE_URL=http://localhost:8081
npm run dev
```

Dev server: `http://localhost:5173`

## Routes

| Path | Purpose |
|------|---------|
| `/` | Landing (APK download CTAs) |
| `/changelog` | Product updates |
| `/reset-password?token=…` | Password reset → `POST {VITE_API_BASE_URL}/v1/auth/reset-password` |
| `/gizlilik` | Privacy / KVKK ([`Privacy.jsx`](src/pages/Privacy.jsx)) |
| `/kullanim-sartlari` | Terms of use ([`TermsOfUse.jsx`](src/pages/TermsOfUse.jsx)), including APK sideload risk |

Static files: `public/sitemap.xml`, `public/downloads/marmaradar-beta.apk`.

## Env

- `VITE_API_BASE_URL` — KrakenD / API gateway (see `.env.example`; code fallback is `http://localhost:8081`)

## Scripts

- `npm run dev` — local development
- `npm run build` — production build to `dist/`
- `npm run preview` — preview production build
- `npm run lint` — oxlint
