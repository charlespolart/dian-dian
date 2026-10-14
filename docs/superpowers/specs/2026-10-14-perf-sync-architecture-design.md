# Perf & sync architecture — design (2026-10-14)

## Goal

Make tracker list and tracker screens feel instant. Today every screen waits
on a cascade of network round-trips (each on a fresh TLS connection). The
fix is architectural: one bootstrap request, a unified in-memory store, a
disk snapshot for instant first paint, and silent revalidation. Bugs found
during the audit are fixed in the same release.

Non-goals: offline mutation queue, server-side stats aggregation,
CustomPainter tracker grid (phase 2).

## Diagnosis (measured by reading the code)

| Symptom | Cause |
|---|---|
| Every request ~150–400 ms on mobile | `api_service.dart` uses top-level `http.get()` → new client, new TCP+TLS per call |
| Page list slow | 1 + 2N requests (cells + legends per page), each `notifyListeners` repaints every card (`shouldRepaint` compares fresh maps) |
| Tracker opens with empty grid then pops | `setContext` wipes cells and refetches what the preview cache already holds; same for legends |
| Cold start slow | 4 sequential RTT: refresh → `/me` → `/pages` → cells ∥ legends |
| Global stats slow | N sequential requests |
| Rendering | `firstWhere` lookups × 372 cells + streak recomputed every build |

## Audit findings (fixed here)

1. **December unsaveable** — `cells.ts` validates `month` in 0..11; client sends 1..12. PUT/DELETE for month 12 → 400. Time bomb for 2026-12-01.
2. **Spurious logout** — expired access token + N parallel requests → N concurrent refreshes; rotation makes all but the first fail → `onAuthExpired`.
3. **Offline launch shows login** — network failure on refresh treated as invalid token.
4. **Legend reorder/recolor never sync across devices** — server sends `{pageId, ids}` / `{pageId, colorMap}`, client expects `legends` list.
5. **`refresh_tokens` unindexed on `token_hash`, never purged.**
6. No day-in-month validation (Feb 31 accepted); no WS heartbeat; no HTTP timeout in app; recolor not transactional; events missed while backgrounded are never resynced.

## Backend

All changes are additive. Existing endpoints and payloads are untouched so
installed clients (≤ 1.2.0) keep working. Deploy backend before the app.

### `GET /api/bootstrap?year=YYYY`
Auth required. `year` optional (default: current year), 2000..2100.

Three queries in `Promise.all`, all joined on `pages.user_id`:
- pages ordered by position (palette parsed, same shape as `/api/pages`)
- legends of those pages ordered by position
- cells of those pages for `year`

```json
{
  "year": 2026,
  "pages": [ { "id", "userId", "title", "year", "position", "palette", "createdAt" } ],
  "legends": { "<pageId>": [ { "id", "pageId", "color", "label", "position", "createdAt" } ] },
  "cells":   { "<pageId>": [ [month, day, "#RRGGBB"], [month, day, "#RRGGBB", "comment"] ] }
}
```
Every page id appears as a key in `legends` and `cells` (possibly `[]`).
`Cache-Control: no-store`.

### `GET /api/stats/days`
All-time dates for every page of the user, for the global stats dialog:
`{ "<pageId>": [ [year, month, day], ... ] }`. Year-scoped stats come from the
client store, no request.

### `POST /api/auth/refresh`
Response gains the user profile fields already returned by `/me`:
`userId, email, vip, premium, theme, language, cursorId, cursorEnabled`.
New clients skip `/me`.

### `PUT /api/pages/reorder` `{ ids: uuid[] }`
Transaction; updates `position` for ids owned by the caller. Broadcasts
`pages:reordered { ids }`. Old clients keep using PATCH per page.

### Validation fixes (`cells.ts`)
`month` 1..12, `day` 1..31, and `day ≤ daysInMonth(month, year)` after the
year is resolved (leap-aware). DELETE stays lenient on leap day.

### Indexes (migration 0012, additive)
`refresh_tokens(token_hash)`, `refresh_tokens(expires_at)`, `pages(user_id)`,
`legends(page_id)`, `subscriptions(user_id)`, `password_reset_tokens(user_id)`,
`oauth_accounts(user_id)`. Declared in `schema.ts` so drizzle snapshots stay
in sync.

### Housekeeping
- Hourly `setInterval`: delete expired `refresh_tokens` and `password_reset_tokens`.
- WS heartbeat: ping every 30 s, terminate sockets that did not pong.
- `PATCH /api/cells/:id/recolor` and `PATCH /api/legends/:id/recolor` run in a transaction.

## Flutter

### `ApiService`
- One persistent `http.Client` for every request (keep-alive).
- 20 s timeout on every request.
- Single-flight refresh: concurrent 401s share one in-flight refresh future.
- Refresh outcome is tri-state: `ok` / `invalid` (server 401/403) / `offline`
  (network, timeout, 5xx). Only `invalid` triggers `onAuthExpired`.
- `tryRestoreSession()` returns the refresh payload (user profile) or the
  tri-state.

### `AuthProvider`
- Consumes the profile from refresh; no `/me` call.
- `offline` + stored refresh token → stays authenticated; `userId` comes from
  secure storage (saved at login alongside email). First API call will 401 →
  refresh → recover when the network is back.
- Logout / expiry → `SyncService.clear()`.

### Store model
`YearCells` (new, immutable): `pageId`, `year`, `Map<int, CellModel>` keyed by
`month * 32 + day`. `get(m, d)`, `length`, `values`, and copy-on-write
`upsert / remove / recolor` returning a new instance. Identity change ⇔ data
change, so painters compare by identity.

`CellModel.fromCompact(pageId, year, row)` parses the bootstrap tuple.

### `CellsProvider` (rewrite, same public API for screens)
- `Map<String, YearCells> _store` keyed `'$pageId:$year'`; `Set<int> _loadedYears`.
- `cellsFor(pageId, year)`, `current`, `isYearLoaded(year)`.
- `setContext` / `setYear` are synchronous state changes (no fetch).
- `getCell / getCellColor / setCell / deleteCell / recolorCells` operate on
  `current`; optimistic with revert.
- `filledDays`, `currentStreak` memoized on the `current` instance.
- `applyBootstrap(year, cellsByPage)`: replaces every `(page, year)` entry for
  that year, marks the year loaded.
- WS: `cell:updated` / `cell:deleted` apply when the year is loaded (creating
  the entry if missing); `cells:reset` empties the entry; `cells:recolored`
  recolors every cached year of that page (no refetch).

### `LegendsProvider` (rewrite, same public API)
- `Map<String, List<LegendModel>> _byPage`; `legends` = current page's list.
- `legendsFor(pageId)`, `setPageId` synchronous, `applyBootstrap`.
- WS events apply to any page (not only the current one); `legends:reordered`
  uses `ids`, `legends:recolored` uses `colorMap`.

### `PagesProvider`
- `applyBootstrap(pages)`; `fetchPages` removed (SyncService owns loading).
- `reorderPages` → one `PUT /api/pages/reorder`; handles `pages:reordered`.

### `SyncService` (new, `services/sync_service.dart`)
Orchestrates loading; providers hold state only.
- `start(userId, year)`: hydrate from disk snapshot (if `userId` matches),
  then kick `ensureYear(year)`.
- `ensureYear(year)`: no-op if loaded; otherwise `GET /api/bootstrap?year=`
  (in-flight deduped per year), `apply*` on the three providers, persist
  snapshot. Skips apply + notify when the body equals the last one for that
  year.
- `revalidate()`: re-fetch the active year (always). Triggered on app resume
  and on WS reconnection (`WsService.onReconnected`, fired on `auth:ok` after
  the first session connect).
- Snapshot: `<app support dir>/snapshot_v1.json` =
  `{ v, userId, year, savedAt, data: <bootstrap json> }`, written after each
  successful bootstrap and on `paused`, serialized from the store. Hydration
  applies pages + legends always, cells only when `year` matches.
- `clear()`: wipe providers, delete snapshot.
- Registered as `WidgetsBindingObserver`.

### `WsService`
- `ensureConnected()`; no double connect; `onReconnected` callback.

### Screens
- `PageListScreen`: no fetch loops; cards read `cellsFor` / `legendsFor`;
  year change → `sync.ensureYear`; `_MiniGrid` takes `YearCells?`, repaints on
  identity change only.
- `TrackerScreen`: stats from provider memo; year change → `setYear` +
  `sync.ensureYear`.
- `AppShell`: on auth → `sync.start(userId, yearToShow)`; restore last tracker
  from hydrated pages (awaits bootstrap only when nothing is hydrated); on
  logout → `sync.clear()`.
- `GlobalStatsDialog`: year mode from store (0 requests); all-time from
  `/api/stats/days` (1 request).

### Dependencies
`path_provider` (snapshot file).

## Backward compatibility
- Old app ↔ new backend: unchanged routes, additive payload fields, unknown
  WS events ignored by old clients.
- New app requires the new backend: deploy backend, then publish app 1.3.0.
- DB migration is index-only; rollback-safe.

## Expected outcome
Cold start: first paint from snapshot (0 RTT), then refresh + bootstrap
(2 RTT on a reused connection). List ↔ tracker ↔ year navigation on loaded
years: 0 requests. Global stats "this year": 0 requests.

## Testing (local)
1. `make db`, `npx drizzle-kit migrate`, seed demo account, `make back`.
2. curl: bootstrap shape; PUT month 12 fails before / succeeds after; refresh
   returns profile; `stats/days`.
3. `flutter analyze` clean; unit tests for `YearCells`, compact parsing,
   bootstrap apply, single-flight refresh.
4. Simulator: watch backend logs — one bootstrap per year, zero requests when
   opening trackers; kill + relaunch → instant paint; airplane mode launch →
   cached data, no login screen; second device sync for legends reorder.
