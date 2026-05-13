# Dian Dian (点点)

A visual year tracker where you color-code each day of the year on a 12-month × 31-day grid. Built with a pixel art aesthetic and a cozy book-style design.

**Live:** [mydiandian.app](https://mydiandian.app)

## Features

- **Year grid** — 12 months × 31 days, color each day with a pastel palette + custom colors
- **Multi-year trackers** — One tracker carries from year to year; swipe to navigate years without recreating anything
- **Legends** — Label colors with custom descriptions, drag-to-reorder
- **Quick fill** — Select a legend from the sidebar, then tap cells to fill instantly
- **Cell editor** — Tap a cell to assign a legend color and add a comment
- **Today highlight** — The current day gets a subtle accent ring on the grid
- **Resume where you left off** — App reopens on the last viewed tracker after kill/relaunch
- **Stats** — Days filled, best streak, yearly percentage, distribution, monthly progress, day-of-week breakdown
- **Global stats** — Cross-tracker overview with "this year / all time" toggle
- **Export** — Share any tracker as a PNG image
- **Themes** — 7 themes including Sakura, Forest, Midnight dark mode, and more
- **Animated cursors** — Fun cursor companions (premium)
- **Premium** — Custom pixel-art paywall backed by RevenueCat (monthly / yearly / lifetime + free trial), AdMob banner for free users
- **Onboarding** — Interactive walkthrough for new users
- **Real-time sync** — WebSocket-based, changes sync instantly across devices
- **Multi-language** — French, English, Simplified Chinese, Traditional Chinese (auto-detects device language)
- **Cross-platform** — iOS, Android, web via Flutter
- **Responsive** — Adapts to phone, tablet, and desktop in portrait and landscape

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter (Dart) |
| Backend | Express, TypeScript |
| Database | PostgreSQL, Drizzle ORM |
| Auth | JWT (access + refresh rotation), argon2id, Sign in with Apple/Google |
| Real-time | WebSocket (ws) |
| In-app purchases | RevenueCat (`purchases_flutter` + webhook → backend) |
| Email | Resend (transactional, `noreply@diandian.overridedev.com`) |
| Fonts | Silkscreen, DotGothic16 (bundled) |
| Container runtime | Docker Compose (postgres + backend + Caddy reverse proxy) |
| CI / Deploy | GitHub Actions → GHCR image → SSH pull (manual trigger via `gh workflow run`) |
| TLS | Caddy (automatic Let's Encrypt) |

## Project Structure

```
dian-dian/
├── backend/
│   ├── src/
│   │   ├── db/          # Drizzle schema + connection
│   │   ├── lib/         # JWT, env, OAuth verifiers, WebSocket, email
│   │   ├── middleware/  # Auth, validation
│   │   └── routes/      # auth, pages, cells, legends, purchase (RC webhook), legal
│   ├── drizzle/         # Generated SQL migrations
│   └── Dockerfile       # Multi-stage: builder / runtime / development
├── flutter_app/
│   ├── lib/
│   │   ├── models/      # PageModel, CellModel, LegendModel
│   │   ├── providers/   # Auth, Pages, Cells, Legends, Language, Premium, Theme
│   │   ├── screens/     # Login, Register, PageList, Tracker, Settings
│   │   ├── services/    # API, WebSocket, Purchase (RC), StoreLinks, Storage
│   │   ├── theme/       # Colors, fonts, theme
│   │   └── widgets/     # Grid, custom paywall, dialogs, shared components
│   ├── ios/             # Apple-specific config (Profile.xcconfig, Podfile…)
│   ├── android/
│   └── pubspec.yaml
├── ops/
│   ├── docker-compose.yml          # Env-neutral base (services, healthchecks)
│   ├── docker-compose.dev.yml      # Local overlay (build target=development, ports)
│   ├── docker-compose.prod.yml     # Prod overlay (GHCR image, /srv bind mounts)
│   ├── Caddyfile                   # Reverse proxy + cache headers
│   ├── scripts/deploy.sh           # `gh workflow run` wrapper
│   └── VPS_MIGRATION_RUNBOOK.md    # One-time legacy-to-/srv migration
├── .github/workflows/deploy.yml    # Manual deploy (build GHCR + ssh pull)
├── Makefile                        # `make app/back/db/ipa/deploy`
└── MULTIYEAR_REFACTOR_PLAN.md      # Plan for the year-agnostic tracker refactor
```

## Development

### Prerequisites

- Node.js 22+
- Flutter SDK
- Docker (for Postgres)

### Quick start

```bash
make db        # Start Postgres in Docker (port 127.0.0.1:5433)
make back      # Run backend with tsx watch on http://localhost:3001
make app       # Run Flutter (prompts device if multiple)
make help      # List all targets
```

First time on the backend:

```bash
cd backend
cp .env.example .env   # Fill in DATABASE_URL, JWT_SECRET, etc.
npm install
npx drizzle-kit migrate
```

### Environment Variables

Listed in `backend/.env.example`. Required:

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Secret for signing access tokens |
| `RESEND_API_KEY` | Resend API key (transactional email) |
| `APP_URL` | Public origin used in verification email links |
| `CORS_ORIGIN` | Allowed frontend origin |
| `APPLE_BUNDLE_IDS` | Comma-separated bundle ids accepted as Apple identity-token `aud` |
| `GOOGLE_CLIENT_IDS` | Comma-separated Google OAuth client ids accepted as ID-token `aud` |
| `REVENUECAT_WEBHOOK_SECRET` | Static value RC echoes in the `Authorization` header for webhook calls |

## Deployment

Single VPS running Docker Compose. Backend image is built by GitHub Actions and pushed to GHCR; the VPS only pulls. Deploys are **manual** — `git push` doesn't trigger anything.

### Trigger a deploy (from your laptop)

```bash
make deploy            # latest HEAD → ./ops/scripts/deploy.sh
# or with a specific SHA to roll back:
./ops/scripts/deploy.sh abc1234
```

This calls `gh workflow run deploy.yml`. The workflow:
1. Builds `backend/Dockerfile --target runtime` and pushes `ghcr.io/charlespolart/dian-dian-backend:<sha>` + `:latest`.
2. Rsyncs compose files + Caddyfile to `/srv/dian-dian/` on the VPS (Caddyfile via `cat >` to preserve the bind-mount inode).
3. `docker compose pull backend`, `up -d --wait postgres`, then runs migrations with 3× retry, then `up -d --wait` everything.
4. Validates + reloads Caddy.

### First-time VPS setup

See [`ops/VPS_MIGRATION_RUNBOOK.md`](ops/VPS_MIGRATION_RUNBOOK.md) — covers GHCR PAT, `/srv/dian-dian/` layout, postgres bind-mount UID, secrets in `.env`.

### Rollback

```bash
./ops/scripts/deploy.sh <previous-short-sha>
```

The image must still exist on GHCR. Available tags: <https://github.com/charlespolart/dian-dian/pkgs/container/dian-dian-backend>.

Drizzle migrations are forward-only — if the rollback target contains a destructive DDL (`DROP COLUMN`…), restoring the DB from a `pg_dump` is required in addition.

## License

All rights reserved.
