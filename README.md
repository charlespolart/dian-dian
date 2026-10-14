# Dian Dian (点点)

A visual year tracker where you color-code each day of the year on a 12-month × 31-day grid. Built with a pixel art aesthetic and a cozy book-style design.

**Live:** [App Store](https://apps.apple.com/app/id6761432329) · [diandian.overridedev.com](https://diandian.overridedev.com) (landing + legal pages)

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
│   │   ├── lib/         # JWT, env, OAuth verifiers, WebSocket (heartbeat), email, dates
│   │   ├── middleware/  # Auth, validation
│   │   └── routes/      # auth, bootstrap (one-shot app state), pages, cells, legends,
│   │                    # stats (all-time days), purchase (RC webhook), legal
│   ├── drizzle/         # Generated SQL migrations
│   ├── scripts/         # seed-demo-local, smoke (end-to-end against a running backend)
│   └── Dockerfile       # Multi-stage: builder / runtime / development
├── flutter_app/
│   ├── lib/
│   │   ├── models/      # PageModel, CellModel, LegendModel, YearCells (immutable store entry)
│   │   ├── providers/   # Auth, Pages, Cells, Legends (state only), Language, Premium, Theme
│   │   ├── screens/     # Login, Register, PageList, Tracker, Settings
│   │   ├── services/    # API (keep-alive client, single-flight refresh), Sync (bootstrap,
│   │   │                # disk snapshot, resume/reconnect resync), WebSocket, Purchase (RC),
│   │   │                # StoreLinks, Storage
│   │   ├── theme/       # Colors, fonts, theme
│   │   └── widgets/     # Grid, custom paywall, dialogs, shared components
│   ├── test/            # Unit tests (hermetic, MockClient)
│   └── integration/     # backend_e2e_test.dart — real data layer vs a running local backend
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
make db        # Start Postgres in Docker (port 127.0.0.1:5433) — or any local Postgres on 5433
make back      # Run backend with tsx watch on http://localhost:3001
make app       # Run Flutter (prompts device if multiple)
make help      # List all targets
```

### Tests

```bash
cd flutter_app && flutter analyze && flutter test            # hermetic unit tests
cd backend && npx tsx scripts/smoke.ts                        # backend end-to-end (needs `make back`)
cd flutter_app && flutter test integration/backend_e2e_test.dart   # real client data layer vs local backend
cd backend && npx tsx scripts/seed-demo-local.ts              # demo@diandian.app / password with 9 trackers
```

In development the backend logs one line per `/api` call (method, path,
status, duration, size) — the quickest way to see what a screen costs.

### Data loading (1.3.0+)

The app makes **one** `GET /api/bootstrap?year=` per year (pages + legends +
compact cells for every page) instead of a request per tracker. Providers
hold immutable per-year stores; `SyncService` owns loading, keeps a disk
snapshot for an instant first paint, and silently re-fetches on app resume
and WebSocket reconnection. Opening a tracker or switching to a loaded year
costs zero requests.

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

Single VPS running Docker Compose (`/srv/dian-dian`). The backend is released
in versions, like the app, and **nothing deploys automatically**: GitHub only
tests and builds; production changes only through a script you run, which asks
twice.

### Versions

| | Backend | Mobile app |
|---|---|---|
| Source of truth | `backend/package.json` | `flutter_app/pubspec.yaml` |
| Changelog | `backend/CHANGELOG.md` | store release notes |
| Git tag | `backend-vX.Y.Z` | — |
| Delivered by | `make deploy` | App Store / Play submission |

The two move independently; the only rule between them is compatibility: the
backend keeps working for every installed app, and an app version states the
backend version it needs in the changelog.

### Release, deploy, roll back

```bash
make release BUMP=minor   # on a clean, pushed master: bumps backend/package.json,
                          # dates CHANGELOG "Unreleased", tags backend-vX.Y.Z, pushes
make deploy               # latest released tag → production (SSH), asks twice
make rollback             # one version back, asks twice
```

1. `make release` (ops/scripts/release.sh) refuses to run unless master is
   clean and identical to origin, the changelog has notes under
   `## [Unreleased]` and the typecheck passes. It then commits
   "Release backend-vX.Y.Z", tags and pushes atomically.
2. The tag push runs the **Release (backend)** workflow: checks the tag
   against `backend/package.json` and master, `npm ci`, typecheck, build,
   migrations on a throwaway Postgres, the smoke suite against the built
   server, then the image `ghcr.io/charlespolart/dian-dian-backend:backend-vX.Y.Z`
   and a GitHub Release with the changelog section. It never touches the VPS.
3. `make deploy` (ops/scripts/deploy-prod.sh) takes the newest tag, refuses it
   unless its workflow is green and the GitHub Release exists, shows
   "production: vA → vB", asks for `y` then for the version typed back. Over
   SSH it syncs `ops/` as of the tag (compose files, Caddyfile by `cat >` to
   keep the bind-mount inode, pgBackRest context, host scripts), pins
   `IMAGE_TAG` in `/srv/dian-dian/.env` (the previous one goes to
   `PREVIOUS_IMAGE_TAG`), pulls, brings postgres up, runs the migrations with
   3 attempts, brings the stack up, validates and reloads Caddy, appends to
   `deploy.log`, then waits for `/api/health` to report the new version.
4. `make rollback` (ops/scripts/rollback-prod.sh) goes back to
   `PREVIOUS_IMAGE_TAG` — one step, never two in a row — with the same
   confirmations and health check. Migrations are forward-only: a version must
   never drop or rename what the previous one needs.

Needs the GitHub CLI logged in and SSH as root to the VPS
(`DIAN_DIAN_PROD_HOST`, default `root@45.76.44.34`).

### First-time VPS setup

See [`ops/VPS_MIGRATION_RUNBOOK.md`](ops/VPS_MIGRATION_RUNBOOK.md) — covers GHCR PAT, `/srv/dian-dian/` layout, postgres bind-mount UID, secrets in `.env`.

## License

All rights reserved.
