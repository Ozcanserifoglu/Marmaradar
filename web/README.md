# Marmaradar Web

Vite + React app for [marmaradar.com](https://marmaradar.com): marketing home page and password-reset flow.

## Setup

```bash
cd web
npm install
cp .env.example .env   # if needed
npm run dev
```

Dev server: `http://localhost:5173`

## Routes

| Path | Purpose |
|------|---------|
| `/` | Landing page (APK beta CTA) |
| `/reset-password?token=…` | Password reset form → `POST {VITE_API_BASE_URL}/v1/auth/reset-password` |

## Env

- `VITE_API_BASE_URL` — KrakenD / API gateway base (default `http://localhost:8081`)

## Scripts

- `npm run dev` — local development
- `npm run build` — production build to `dist/`
- `npm run preview` — preview production build
