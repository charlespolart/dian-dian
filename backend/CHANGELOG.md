# Changelog — backend

Notable changes to the API, newest first. Versions are cut by
`./release-backend.sh` and tagged `backend-vX.Y.Z`; the mobile app has its
own version in `flutter_app/pubspec.yaml` and is released separately.

Rules: a version never removes or renames what the previous one needs (the
database keeps the newer migrations after a rollback), and installed apps keep
working against the new backend.

## [Unreleased]

### Added
- `POST /api/pages` accepts `legends: [{color, label}]` (≤ 12, created in the same transaction, positions in array order) and `replaces: <pageId>` (an empty page of the account — no legend, no cell — deleted in that transaction, the new page taking its position; 404 if it is not the caller's, 409 if it is not empty, nothing written in both cases). The response and the `page:created` WebSocket event carry `legends` and `replaced`; `page:deleted` is sent for the replaced page, then one `legend:created` per legend so apps ≤ 1.3.0 see them too. The page being replaced is row-locked (`FOR UPDATE`) so the emptiness check and the delete are atomic.
- `GET /api/bootstrap` returns `activated`: the account has at least one cell, on any page, any year.
- `cells.created_at` (migration 0013, backfilled from `updated_at`), returned as `createdAt` by the cell routes.
- `scripts/prod-activation.sql`: activation by weekly signup cohort (first cell within 24 h / 7 days, never).
- `POST /api/events` `{ name }` (auth, 120 / 15 min per IP) and table `events` (migration 0014): the app reports each paywall gate it shows (`paywall.tracker_limit`, …) so the free limit's real pull can be read with `scripts/prod-events.sql`.

- `POST /api/pages` accepts `clientId` (uuid, `pages.client_id`, migration 0016): the same key sent again returns the page already created (200) instead of a twin — the app's first-tracker flow retries with it after a lost response.
- The website's contact page (`/contact`) is a form posting to `POST /api/contact`, with the address kept as a fallback.
- `PUT /api/pages/keep` `{ ids }` (≤ 3) and `pages.keep_free` (migration 0015): which trackers a free account keeps open once it is over the limit, chosen by the user and shared by every device; WebSocket `pages:kept`. The bootstrap also gives each page `recentCells` (cells touched in the last 90 days) and `lastCellAt`, so the app can default to the most active trackers.

### Changed
- `POST /api/pages` refuses a 4th tracker for a free account (403), VIP and active subscriptions excepted; replacing an empty page still works at the limit. Apps ≤ 1.3.0 never send that request (they gate the + button).
- Cell writes (`PUT` / `DELETE /api/cells/:pageId`, recolor, reset) are refused (403) on a tracker the free tier locks — the same set the app shows closed (`src/lib/trackerLock.ts`, unit-tested). Reads stay open. An app ≤ 1.3.0 that still opens such a tracker sees its taps reverted.
- No "My Tracker" page is created at signup (email or OAuth) any more: the app's first-tracker flow (1.4.0) creates the first page with its legends.

### Compatibility
- Apps ≤ 1.3.0 keep working (a new account shows an empty list with the + button). App 1.4.0 requires this version.

## [1.1.1] - 2026-10-15

### Added
- Landing: visitors arriving with `utm_source` / `utm_campaign` get store buttons carrying the campaign (Play `referrer`, App Store `pt`/`ct` when `APPLE_CAMPAIGN_PT` is set) — attribution for Pinterest and other channels.

### Changed
- Contact address is now `contact@diandian.overridedev.com` everywhere: legal pages (privacy, terms, contact, delete-account, all locales), contact form recipient, and the sender of transactional mail (Resend domain `diandian.overridedev.com`). The old `diandian@overridedev.com` keeps being routed for a while.

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
