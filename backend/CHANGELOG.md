# Changelog — backend

Notable changes to the API, newest first. Versions are cut by
`./release-backend.sh` and tagged `backend-vX.Y.Z`; the mobile app has its
own version in `flutter_app/pubspec.yaml` and is released separately.

Rules: a version never removes or renames what the previous one needs (the
database keeps the newer migrations after a rollback), and installed apps keep
working against the new backend.

## [Unreleased]

### Added
- Landing: visitors arriving with `utm_source` / `utm_campaign` get store buttons carrying the campaign (Play `referrer`, App Store `pt`/`ct` when `APPLE_CAMPAIGN_PT` is set) — attribution for Pinterest and other channels.

### Changed
- Contact address is now `contact@diandian.overridedev.com` on every legal page (privacy, terms, contact, delete-account, all locales) and for the contact form; the old `diandian@overridedev.com` keeps being routed for a while. Transactional mail still goes out from `diandian@overridedev.com` until the subdomain is verified in Resend.

## [1.1.0] - 2026-10-14

### Added
- `GET /api/bootstrap?year=` — pages + legends + compact cells of one year in a single round-trip.
- `GET /api/stats/days` — every filled date per page, for all-time stats.
- `PUT /api/pages/reorder` (one transaction) + WebSocket event `pages:reordered`.
- `POST /api/auth/refresh` also returns the user profile (no `/me` round-trip on cold start).
- `/api/health` reports the running version.
- Lookup indexes (migration 0012), hourly purge of expired refresh / reset tokens, WebSocket heartbeat.
- `scripts/smoke.ts` end-to-end suite, run by the Release workflow against a throwaway Postgres.

### Fixed
- Cells in December were rejected with 400 (month validated 0..11, the app sends 1..12).
- Day-in-month validation (30 February was accepted).
- Legend and cell recolor run in one transaction.

### Compatibility
- Apps ≤ 1.2.0 keep working unchanged. App 1.3.0 requires this version.

## [1.0.0] - 2026-03-26
- First production backend (deployed by commit SHA, before versioned releases).
