# Perf & Sync Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the tracker list and tracker screen load instantly by replacing the per-page request cascade with one bootstrap request, a unified in-memory store, a disk snapshot, and silent revalidation — while fixing the bugs found in the audit.

**Architecture:** Backend gains additive endpoints (`/api/bootstrap`, `/api/stats/days`, `/api/pages/reorder`, profile in `/refresh`) plus index-only migration and validation fixes. Flutter gains a persistent HTTP client with single-flight refresh, immutable `YearCells` store entries inside the existing providers (public API preserved), and a `SyncService` that owns loading, snapshotting and revalidation. Screens only change where they used to trigger fetches.

**Tech Stack:** Express 4 + Drizzle (postgres-js) + zod + ws; Flutter 3.47 / Dart 3.11, provider, http, web_socket_channel, path_provider, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-14-perf-sync-architecture-design.md`

## Global Constraints

- Every existing HTTP route, payload shape and WS event stays byte-compatible for clients ≤ 1.2.0. New fields/events are additive only.
- DB migration 0012 is index-only (`CREATE INDEX IF NOT EXISTS`), declared in `schema.ts` so drizzle snapshots stay in sync.
- `month` is 1-based (1..12) everywhere; `day` 1..31 and ≤ days in month for PUT.
- Compact cell tuple: `[month, day, "#RRGGBB"]` or `[month, day, "#RRGGBB", "comment"]`.
- Store key for a year of cells: `'$pageId:$year'`; cell key inside a year: `month * 32 + day`.
- Snapshot file: `<application support dir>/snapshot_v1.json`, `{ v: 1, userId, year, savedAt, data }`.
- Only an explicit 401/403 from `/api/auth/refresh` logs the user out. Network errors keep the session.
- HTTP request timeout: 20 s. WS heartbeat: 30 s.
- Flutter public provider API used by dialogs (`getCell`, `setCell`, `deleteCell`, `recolorCells`, `cells`, `legends`, `createLegend`, `updateLegend`, `deleteLegend`, `reorderLegends`, `currentPageId`) keeps its signatures.
- App version bumps to `1.3.0+7`.

## Review Focus

1. Access token expires while the list fires several requests → exactly one refresh, every request retried, no logout. (Task 9 test `single-flight refresh`.)
2. App launched in airplane mode with a stored refresh token → cached data shown, no login screen; once online, first request recovers via refresh. (Task 9 `offline outcome` test + Task 13 manual.)
3. A cell saved on 31 December → 200, and 30 February → 400 with the `Invalid day for month` message. (Task 2 smoke assertions.)
4. Legend reorder/recolor on device A → device B's sidebar and cards update without reload. (Task 11 WS tests `legends:reordered` / `legends:recolored`.)
5. Revalidation returning an identical body on resume → no notify, no card repaint. (Task 12 test `unchanged body is skipped`.)

---

## File map

**Backend (create)**
- `backend/src/routes/bootstrap.ts` — `GET /api/bootstrap`
- `backend/src/routes/stats.ts` — `GET /api/stats/days`
- `backend/src/lib/dates.ts` — `daysInMonth`
- `backend/drizzle/0012_*.sql` — generated indexes
- `backend/scripts/smoke.ts` — end-to-end smoke test against a running backend

**Backend (modify)**
- `backend/src/db/schema.ts` — indexes
- `backend/src/routes/cells.ts` — month/day validation, transactional recolor
- `backend/src/routes/legends.ts` — transactional recolor
- `backend/src/routes/auth.ts` — profile in `/refresh`
- `backend/src/routes/pages.ts` — `PUT /reorder`
- `backend/src/lib/ws.ts` — heartbeat
- `backend/src/index.ts` — mount routes, hourly purge

**Flutter (create)**
- `flutter_app/lib/models/year_cells.dart`
- `flutter_app/lib/services/token_store.dart` — `TokenStore` interface
- `flutter_app/lib/services/snapshot_store.dart` — file IO for the snapshot
- `flutter_app/lib/services/sync_service.dart`
- `flutter_app/test/year_cells_test.dart`, `test/api_service_test.dart`, `test/cells_provider_test.dart`, `test/legends_provider_test.dart`, `test/sync_service_test.dart`

**Flutter (modify)**
- `lib/models/cell_model.dart` — `fromCompact`, `toCompact`, `key`
- `lib/services/api_service.dart` — client, timeout, single-flight, tri-state
- `lib/services/storage_service.dart` — implements `TokenStore`, `userId`
- `lib/services/ws_service.dart` — `ensureConnected`, `onReconnected`
- `lib/services/audio_service.dart` — lazy players (testability)
- `lib/providers/cells_provider.dart`, `legends_provider.dart`, `pages_provider.dart`, `auth_provider.dart`
- `lib/main.dart`, `lib/screens/page_list_screen.dart`, `lib/screens/tracker_screen.dart`, `lib/widgets/global_stats_dialog.dart`
- `pubspec.yaml` — `path_provider`, version

---

### Task 1: Backend indexes + hourly token purge

**Files:**
- Modify: `backend/src/db/schema.ts`
- Create: `backend/drizzle/0012_<name>.sql` (generated)
- Modify: `backend/src/index.ts`

**Interfaces:** none consumed; produces indexes only.

- [ ] **Step 1: Declare indexes in `schema.ts`**

Add `index` to the drizzle import and a third-argument callback on each table:

```ts
import { pgTable, uuid, text, smallint, integer, boolean, timestamp, primaryKey, index } from 'drizzle-orm/pg-core';

export const oauthAccounts = pgTable('oauth_accounts', { ... }, (t) => [
  primaryKey({ columns: [t.provider, t.subject] }),
  index('oauth_accounts_user_id_idx').on(t.userId),
]);
export const passwordResetTokens = pgTable('password_reset_tokens', { ... }, (t) => [
  index('password_reset_tokens_user_id_idx').on(t.userId),
]);
export const refreshTokens = pgTable('refresh_tokens', { ... }, (t) => [
  index('refresh_tokens_token_hash_idx').on(t.tokenHash),
  index('refresh_tokens_expires_at_idx').on(t.expiresAt),
]);
export const subscriptions = pgTable('subscriptions', { ... }, (t) => [
  index('subscriptions_user_id_idx').on(t.userId),
]);
export const pages = pgTable('pages', { ... }, (t) => [
  index('pages_user_id_idx').on(t.userId),
]);
export const legends = pgTable('legends', { ... }, (t) => [
  index('legends_page_id_idx').on(t.pageId),
]);
```

- [ ] **Step 2: Generate the migration and inspect it**

Run: `cd backend && npx drizzle-kit generate --name perf_indexes`
Expected: a new `drizzle/0012_perf_indexes.sql` containing only `CREATE INDEX` statements (7 of them). If anything else appears (ALTER/DROP), stop and fix the schema diff.

- [ ] **Step 3: Hourly purge in `index.ts`**

```ts
import { lt } from 'drizzle-orm';
import { refreshTokens, passwordResetTokens } from './db/schema.js';

async function purgeExpiredTokens() {
  const now = new Date();
  try {
    await db.delete(refreshTokens).where(lt(refreshTokens.expiresAt, now));
    await db.delete(passwordResetTokens).where(lt(passwordResetTokens.expiresAt, now));
  } catch (err) {
    console.error('Token purge failed:', err);
  }
}
purgeExpiredTokens();
setInterval(purgeExpiredTokens, 60 * 60 * 1000).unref();
```

- [ ] **Step 4: Type-check, apply locally, commit**

Run: `cd backend && npx tsc --noEmit && npx drizzle-kit migrate` (needs `make db` first)
Expected: no errors; migration applied.

```bash
git add backend/src/db/schema.ts backend/drizzle backend/src/index.ts
git commit -m "Backend: add lookup indexes (refresh_tokens.token_hash, pages.user_id, legends.page_id…) + hourly expired-token purge"
```

---

### Task 2: Cells validation fix (December!) + transactional recolor + smoke script

**Files:**
- Create: `backend/src/lib/dates.ts`
- Modify: `backend/src/routes/cells.ts`, `backend/src/routes/legends.ts`
- Create: `backend/scripts/smoke.ts`

**Interfaces:**
- Produces `daysInMonth(month: number, year: number): number` (1-based month).

- [ ] **Step 1: Write the smoke test first (`backend/scripts/smoke.ts`)**

Runs against a live backend (`SMOKE_BASE`, default `http://localhost:3001`), registers a throwaway user, exercises the routes, deletes the user. Uses `node:assert`.

```ts
import assert from 'node:assert/strict';

const BASE = process.env.SMOKE_BASE ?? 'http://localhost:3001';
const email = `smoke-${Date.now()}@example.com`;
const password = 'smoke-password-123';
let access = '';
let refresh = '';

async function call(method: string, path: string, body?: unknown, auth = true) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(auth && access ? { Authorization: `Bearer ${access}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json: any = null;
  try { json = JSON.parse(text); } catch { /* non-JSON */ }
  return { status: res.status, json };
}

async function main() {
  // register
  let r = await call('POST', '/api/auth/register', { email, password }, false);
  assert.equal(r.status, 201, `register: ${JSON.stringify(r.json)}`);
  access = r.json.accessToken; refresh = r.json.refreshToken;
  const userId: string = r.json.userId;

  // refresh returns the profile (new) and still the tokens (legacy)
  r = await call('POST', '/api/auth/refresh', { refreshToken: refresh }, false);
  assert.equal(r.status, 200);
  assert.ok(r.json.accessToken && r.json.refreshToken, 'refresh tokens');
  assert.equal(r.json.userId, userId, 'refresh returns userId');
  assert.equal(typeof r.json.premium, 'boolean', 'refresh returns premium');
  access = r.json.accessToken; refresh = r.json.refreshToken;

  // default page exists
  r = await call('GET', '/api/pages');
  assert.equal(r.status, 200);
  const pageId: string = r.json[0].id;

  // second page + reorder
  r = await call('POST', '/api/pages', { title: 'Second', position: 1 });
  assert.equal(r.status, 201);
  const page2: string = r.json.id;
  r = await call('PUT', '/api/pages/reorder', { ids: [page2, pageId] });
  assert.equal(r.status, 200, 'reorder');
  r = await call('GET', '/api/pages');
  assert.deepEqual(r.json.map((p: any) => p.id), [page2, pageId], 'reorder applied');

  // December is saveable, invalid dates are not
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 12, day: 31, color: '#FF0000' });
  assert.equal(r.status, 200, `december: ${JSON.stringify(r.json)}`);
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 2, day: 30, color: '#FF0000' });
  assert.equal(r.status, 400, 'feb 30 rejected');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2024, month: 2, day: 29, color: '#00FF00', comment: 'leap' });
  assert.equal(r.status, 200, 'leap day 2024 accepted');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 13, day: 1, color: '#FF0000' });
  assert.equal(r.status, 400, 'month 13 rejected');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 0, day: 1, color: '#FF0000' });
  assert.equal(r.status, 400, 'month 0 rejected');

  // legend
  r = await call('POST', `/api/legends/${pageId}`, { color: '#FF0000', label: 'Red', position: 0 });
  assert.equal(r.status, 201);

  // bootstrap
  r = await call('GET', '/api/bootstrap?year=2026');
  assert.equal(r.status, 200);
  assert.equal(r.json.year, 2026);
  assert.deepEqual(r.json.pages.map((p: any) => p.id), [page2, pageId]);
  assert.deepEqual(r.json.cells[pageId], [[12, 31, '#FF0000']], 'compact cells for 2026');
  assert.deepEqual(r.json.cells[page2], [], 'empty page present');
  assert.equal(r.json.legends[pageId].length, 1);
  assert.deepEqual(r.json.legends[page2], []);
  r = await call('GET', '/api/bootstrap?year=2024');
  assert.deepEqual(r.json.cells[pageId], [[2, 29, '#00FF00', 'leap']], 'comment as 4th element');

  // stats/days
  r = await call('GET', '/api/stats/days');
  assert.equal(r.status, 200);
  assert.deepEqual(
    [...r.json[pageId]].sort((a: number[], b: number[]) => a[0] - b[0]),
    [[2024, 2, 29], [2026, 12, 31]],
  );

  // legacy endpoints unchanged
  r = await call('GET', `/api/cells/${pageId}?year=2026`);
  assert.equal(r.status, 200);
  assert.equal(r.json[0].month, 12);

  // cleanup
  r = await call('DELETE', '/api/auth/account');
  assert.equal(r.status, 200);
  console.log('smoke: OK');
}

main().catch((err) => { console.error('smoke: FAILED', err); process.exit(1); });
```

- [ ] **Step 2: Run it against the current backend to confirm the December failure**

Run: `cd backend && npm run dev` (other terminal) then `npx tsx scripts/smoke.ts`
Expected: FAIL at `refresh returns userId` (not implemented yet) — comment that block temporarily if you want to see `december` fail with status 400. Either way the script fails before `smoke: OK`.

- [ ] **Step 3: `backend/src/lib/dates.ts`**

```ts
/** Days in a 1-based month, leap-aware. */
export function daysInMonth(month: number, year: number): number {
  if (month === 2) {
    const leap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
    return leap ? 29 : 28;
  }
  return [4, 6, 9, 11].includes(month) ? 30 : 31;
}
```

- [ ] **Step 4: Fix validation in `cells.ts`**

```ts
import { daysInMonth } from '../lib/dates.js';

const upsertCellSchema = z.object({
  year: z.number().int().min(2000).max(2100).optional(),
  month: z.number().int().min(1).max(12),   // was 0..11 — December was unsaveable
  day: z.number().int().min(1).max(31),
  color: ...,
  comment: ...,
});
// in PUT, after `const year = pickYear(...)`:
if (day > daysInMonth(month, year)) {
  res.status(400).json({ error: 'Invalid day for month' });
  return;
}
const deleteCellSchema = z.object({ year: ..., month: z.number().int().min(1).max(12), day: z.number().int().min(1).max(31) });
```

Recolor in a transaction:

```ts
await db.transaction(async (tx) => {
  for (const [oldColor, newColor] of Object.entries(colorMap)) {
    await tx.update(cells).set({ color: newColor as string, updatedAt: new Date() })
      .where(and(eq(cells.pageId, pageId), eq(cells.color, oldColor)));
  }
});
```
Same pattern in `legends.ts` recolor.

- [ ] **Step 5: Type-check and commit** (smoke stays red until Tasks 3–5)

```bash
cd backend && npx tsc --noEmit
git add backend/src/lib/dates.ts backend/src/routes/cells.ts backend/src/routes/legends.ts backend/scripts/smoke.ts
git commit -m "Backend: fix month validation (December was rejected), validate day-in-month, transactional recolor, add smoke script"
```

---

### Task 3: `GET /api/bootstrap` + `GET /api/stats/days`

**Files:**
- Create: `backend/src/routes/bootstrap.ts`, `backend/src/routes/stats.ts`
- Modify: `backend/src/index.ts`

**Interfaces:**
- Produces the JSON shapes in the spec (`year, pages, legends{}, cells{}` and `{pageId: [[y,m,d]]}`).

- [ ] **Step 1: `bootstrap.ts`**

```ts
import { Router } from 'express';
import { db } from '../db/index.js';
import { pages, cells, legends } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { eq, and, asc } from 'drizzle-orm';

const router = Router();
router.use(requireAuth);

function parseYear(input: unknown): number | null {
  if (typeof input !== 'string') return null;
  const n = parseInt(input, 10);
  return Number.isInteger(n) && n >= 2000 && n <= 2100 ? n : null;
}

type CompactCell = [number, number, string] | [number, number, string, string];

// One round-trip for everything the app needs to paint the page list and
// open any tracker on `year`: pages, their legends, and the cells of that
// year in a compact tuple form.
router.get('/', async (req, res) => {
  try {
    const userId = req.userId!;
    const year = parseYear(req.query.year) ?? new Date().getFullYear();

    const [pageRows, legendRows, cellRows] = await Promise.all([
      db.select().from(pages).where(eq(pages.userId, userId)).orderBy(asc(pages.position)),
      db.select({
        id: legends.id, pageId: legends.pageId, color: legends.color,
        label: legends.label, position: legends.position, createdAt: legends.createdAt,
      }).from(legends)
        .innerJoin(pages, eq(pages.id, legends.pageId))
        .where(eq(pages.userId, userId))
        .orderBy(asc(legends.position)),
      db.select({
        pageId: cells.pageId, month: cells.month, day: cells.day,
        color: cells.color, comment: cells.comment,
      }).from(cells)
        .innerJoin(pages, eq(pages.id, cells.pageId))
        .where(and(eq(pages.userId, userId), eq(cells.year, year))),
    ]);

    const legendsByPage: Record<string, typeof legendRows> = {};
    const cellsByPage: Record<string, CompactCell[]> = {};
    for (const p of pageRows) { legendsByPage[p.id] = []; cellsByPage[p.id] = []; }
    for (const l of legendRows) legendsByPage[l.pageId]?.push(l);
    for (const c of cellRows) {
      cellsByPage[c.pageId]?.push(c.comment ? [c.month, c.day, c.color, c.comment] : [c.month, c.day, c.color]);
    }

    res.set('Cache-Control', 'no-store');
    res.json({
      year,
      pages: pageRows.map((p) => ({ ...p, palette: p.palette ? JSON.parse(p.palette) : null })),
      legends: legendsByPage,
      cells: cellsByPage,
    });
  } catch (err) {
    console.error('Bootstrap error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
```

- [ ] **Step 2: `stats.ts`**

```ts
// All-time dates per page for the global stats dialog: { pageId: [[y,m,d], ...] }.
router.get('/days', async (req, res) => {
  try {
    const rows = await db.select({ pageId: cells.pageId, year: cells.year, month: cells.month, day: cells.day })
      .from(cells)
      .innerJoin(pages, eq(pages.id, cells.pageId))
      .where(eq(pages.userId, req.userId!));
    const byPage: Record<string, [number, number, number][]> = {};
    for (const r of rows) (byPage[r.pageId] ??= []).push([r.year, r.month, r.day]);
    res.set('Cache-Control', 'no-store');
    res.json(byPage);
  } catch (err) { console.error('Stats days error:', err); res.status(500).json({ error: 'Server error' }); }
});
```

- [ ] **Step 3: Mount in `index.ts`** after `/api/purchase`:

```ts
app.use('/api/bootstrap', bootstrapRoutes);
app.use('/api/stats', statsRoutes);
```

- [ ] **Step 4: Type-check, commit**

```bash
cd backend && npx tsc --noEmit
git add backend/src/routes/bootstrap.ts backend/src/routes/stats.ts backend/src/index.ts
git commit -m "Backend: GET /api/bootstrap (pages+legends+compact cells in one round-trip) and GET /api/stats/days"
```

---

### Task 4: Profile in `/api/auth/refresh`

**Files:** Modify `backend/src/routes/auth.ts`

- [ ] **Step 1: Extract the profile builder** (used by `issueSession`, `/me`, `/refresh`)

```ts
type ProfileUser = { id: string; email: string; vip: boolean; theme: string; language: string | null; cursorId: string; cursorEnabled: boolean };

async function profileOf(user: ProfileUser) {
  return {
    userId: user.id, email: user.email, vip: user.vip,
    premium: await hasActiveSubscription(user.id),
    theme: user.theme, language: user.language,
    cursorId: user.cursorId, cursorEnabled: user.cursorEnabled,
  };
}
```
`issueSession` returns `{ accessToken, refreshToken, ...(await profileOf(user)) }` (adds `email` — additive).

- [ ] **Step 2: In `/refresh`, load the user after validating the stored token**

```ts
const [user] = await db.select().from(users).where(eq(users.id, stored.userId)).limit(1);
if (!user) { res.status(401).json({ error: 'Invalid or expired refresh token' }); return; }
// ...rotation unchanged...
res.json({ accessToken, refreshToken: newRefreshToken, ...(await profileOf(user)) });
```

- [ ] **Step 3: Type-check, commit**

```bash
cd backend && npx tsc --noEmit
git add backend/src/routes/auth.ts
git commit -m "Backend: /api/auth/refresh returns the user profile (saves the /me round-trip on cold start)"
```

---

### Task 5: `PUT /api/pages/reorder` + WS heartbeat

**Files:** Modify `backend/src/routes/pages.ts`, `backend/src/lib/ws.ts`

- [ ] **Step 1: Reorder route** (declare before `/:id` handlers is not required — different method — but keep it near the top for readability)

```ts
const reorderPagesSchema = z.object({ ids: z.array(z.string().uuid()).max(500) });

router.put('/reorder', validate(reorderPagesSchema), async (req, res) => {
  try {
    const { ids } = req.body as { ids: string[] };
    await db.transaction(async (tx) => {
      for (let i = 0; i < ids.length; i++) {
        await tx.update(pages).set({ position: i })
          .where(and(eq(pages.id, ids[i]), eq(pages.userId, req.userId!)));
      }
    });
    broadcast(req.userId!, 'pages:reordered', { ids });
    res.json({ ok: true });
  } catch (err) { console.error('Reorder pages error:', err); res.status(500).json({ error: 'Server error' }); }
});
```

- [ ] **Step 2: Heartbeat in `ws.ts`**

```ts
const HEARTBEAT_MS = 30_000;
const alive = new WeakSet<WebSocket>();
// in setupWebSocket, after creating wss:
const heartbeat = setInterval(() => {
  for (const ws of wss.clients) {
    if (!alive.has(ws)) { ws.terminate(); continue; }
    alive.delete(ws);
    ws.ping();
  }
}, HEARTBEAT_MS);
heartbeat.unref();
wss.on('close', () => clearInterval(heartbeat));
// in 'connection':
alive.add(ws);
ws.on('pong', () => alive.add(ws));
```

- [ ] **Step 3: Run the smoke test end to end**

Run: `cd backend && npx tsc --noEmit && npx tsx scripts/smoke.ts`
Expected: `smoke: OK`

- [ ] **Step 4: Commit**

```bash
git add backend/src/routes/pages.ts backend/src/lib/ws.ts
git commit -m "Backend: PUT /api/pages/reorder (one transaction instead of N PATCH) + WS heartbeat"
```

---

### Task 6: `YearCells` model + compact cell parsing

**Files:**
- Create: `flutter_app/lib/models/year_cells.dart`, `flutter_app/test/year_cells_test.dart`
- Modify: `flutter_app/lib/models/cell_model.dart`, `flutter_app/lib/services/audio_service.dart`

**Interfaces (produces):**
```dart
class CellModel { static int keyOf(int month, int day); int get key; factory CellModel.fromCompact(String pageId, int year, List<dynamic> row); List<dynamic> toCompact(); }
class YearCells {
  final String pageId; final int year;
  factory YearCells.empty(String pageId, int year);
  factory YearCells.fromCompact(String pageId, int year, List<dynamic> rows);
  factory YearCells.fromList(String pageId, int year, Iterable<CellModel> cells);
  CellModel? get(int month, int day); int get length; bool get isEmpty; Iterable<CellModel> get values;
  YearCells upsert(CellModel cell); YearCells remove(int month, int day); YearCells recolor(Map<String, String> colorMap);
  List<List<dynamic>> toCompact();
}
```

- [ ] **Step 1: Write `test/year_cells_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dian_dian/models/cell_model.dart';
import 'package:dian_dian/models/year_cells.dart';

void main() {
  group('CellModel compact', () {
    test('parses 3-tuple and 4-tuple', () {
      final a = CellModel.fromCompact('p', 2026, [12, 31, '#FF0000']);
      expect(a.month, 12); expect(a.day, 31); expect(a.color, '#FF0000'); expect(a.comment, isNull);
      expect(a.pageId, 'p'); expect(a.year, 2026);
      final b = CellModel.fromCompact('p', 2026, [2, 29, '#00FF00', 'leap']);
      expect(b.comment, 'leap');
      expect(b.toCompact(), [2, 29, '#00FF00', 'leap']);
      expect(a.toCompact(), [12, 31, '#FF0000']);
    });
    test('key is unique per month/day', () {
      expect(CellModel.keyOf(1, 31), isNot(CellModel.keyOf(2, 1)));
      expect(CellModel.keyOf(12, 31), 12 * 32 + 31);
    });
  });

  group('YearCells', () {
    final base = YearCells.fromCompact('p', 2026, [[1, 1, '#AAAAAA'], [1, 2, '#BBBBBB', 'hi']]);

    test('get / length / values', () {
      expect(base.length, 2);
      expect(base.get(1, 2)?.comment, 'hi');
      expect(base.get(3, 3), isNull);
      expect(base.values.map((c) => c.day), containsAll([1, 2]));
    });
    test('upsert returns a new instance and leaves the old untouched', () {
      final next = base.upsert(CellModel.fromCompact('p', 2026, [1, 1, '#CCCCCC']));
      expect(identical(next, base), isFalse);
      expect(base.get(1, 1)!.color, '#AAAAAA');
      expect(next.get(1, 1)!.color, '#CCCCCC');
      expect(next.length, 2);
    });
    test('remove', () {
      final next = base.remove(1, 2);
      expect(next.length, 1); expect(next.get(1, 2), isNull); expect(base.length, 2);
    });
    test('recolor maps only matching colors', () {
      final next = base.recolor({'#AAAAAA': '#111111'});
      expect(next.get(1, 1)!.color, '#111111');
      expect(next.get(1, 2)!.color, '#BBBBBB');
    });
    test('toCompact round-trips', () {
      final rows = base.toCompact();
      final again = YearCells.fromCompact('p', 2026, rows);
      expect(again.length, 2); expect(again.get(1, 2)!.comment, 'hi');
    });
    test('empty', () {
      expect(YearCells.empty('p', 2026).isEmpty, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run, expect compile failure**

Run: `cd flutter_app && flutter test test/year_cells_test.dart`
Expected: FAIL (`year_cells.dart` not found).

- [ ] **Step 3: Implement**

`cell_model.dart` additions:
```dart
  static int keyOf(int month, int day) => month * 32 + day;
  int get key => keyOf(month, day);

  /// Bootstrap tuple: `[month, day, color]` or `[month, day, color, comment]`.
  factory CellModel.fromCompact(String pageId, int year, List<dynamic> row) {
    return CellModel(
      pageId: pageId, year: year,
      month: row[0] as int, day: row[1] as int, color: row[2] as String,
      comment: row.length > 3 ? row[3] as String? : null,
      updatedAt: '',
    );
  }

  List<dynamic> toCompact() =>
      comment != null && comment!.isNotEmpty ? [month, day, color, comment] : [month, day, color];
```

`year_cells.dart`:
```dart
import 'cell_model.dart';

/// Immutable set of cells for one (page, year). Every mutation returns a new
/// instance, so `identical(a, b)` answers "did anything change?" — painters
/// rely on that for cheap `shouldRepaint`.
class YearCells {
  final String pageId;
  final int year;
  final Map<int, CellModel> _byKey;

  const YearCells._(this.pageId, this.year, this._byKey);

  factory YearCells.empty(String pageId, int year) => YearCells._(pageId, year, const {});

  factory YearCells.fromList(String pageId, int year, Iterable<CellModel> cells) =>
      YearCells._(pageId, year, {for (final c in cells) c.key: c});

  factory YearCells.fromCompact(String pageId, int year, List<dynamic> rows) =>
      YearCells.fromList(pageId, year, rows.map((r) => CellModel.fromCompact(pageId, year, r as List<dynamic>)));

  CellModel? get(int month, int day) => _byKey[CellModel.keyOf(month, day)];
  int get length => _byKey.length;
  bool get isEmpty => _byKey.isEmpty;
  Iterable<CellModel> get values => _byKey.values;

  YearCells upsert(CellModel cell) => YearCells._(pageId, year, {..._byKey, cell.key: cell});

  YearCells remove(int month, int day) {
    final key = CellModel.keyOf(month, day);
    if (!_byKey.containsKey(key)) return this;
    final copy = Map<int, CellModel>.of(_byKey)..remove(key);
    return YearCells._(pageId, year, copy);
  }

  YearCells recolor(Map<String, String> colorMap) {
    var changed = false;
    final copy = <int, CellModel>{};
    for (final e in _byKey.entries) {
      final next = colorMap[e.value.color];
      if (next != null && next != e.value.color) { copy[e.key] = e.value.copyWith(color: next); changed = true; }
      else { copy[e.key] = e.value; }
    }
    return changed ? YearCells._(pageId, year, copy) : this;
  }

  List<List<dynamic>> toCompact() => [for (final c in _byKey.values) c.toCompact()];
}
```

`audio_service.dart`: make players lazy so unit tests can construct providers:
```dart
  AudioPlayer? _tap, _erase;
  AudioPlayer get _tapPlayer => _tap ??= AudioPlayer();
  AudioPlayer get _erasePlayer => _erase ??= AudioPlayer();
```

- [ ] **Step 4: Run tests, commit**

Run: `flutter test test/year_cells_test.dart` → PASS.
```bash
git add flutter_app/lib/models flutter_app/lib/services/audio_service.dart flutter_app/test/year_cells_test.dart
git commit -m "Flutter: YearCells immutable store entry + compact cell tuples"
```

---

### Task 7: `ApiService` — persistent client, timeout, single-flight tri-state refresh

**Files:**
- Create: `flutter_app/lib/services/token_store.dart`, `flutter_app/test/api_service_test.dart`
- Modify: `flutter_app/lib/services/api_service.dart`, `flutter_app/lib/services/storage_service.dart`

**Interfaces (produces):**
```dart
abstract class TokenStore { Future<String?> getRefreshToken(); Future<void> setRefreshToken(String); Future<void> deleteRefreshToken(); Future<String?> getUserId(); Future<void> setUserId(String); Future<void> deleteUserId(); }
enum RefreshOutcome { ok, invalid, offline }
class RestoreResult { final RefreshOutcome outcome; final Map<String, dynamic>? profile; }
class ApiService {
  factory ApiService();                                  // singleton
  @visibleForTesting ApiService.custom({http.Client? client, TokenStore? tokens});
  Future<http.Response> apiFetch(String path, {String method, Map<String,dynamic>? body, Map<String,String>? headers});
  Future<RestoreResult> tryRestoreSession();
  void Function(Map<String, dynamic> profile)? onTokensRefreshed;
  VoidCallback? onAuthExpired;
}
```

- [ ] **Step 1: `test/api_service_test.dart`**

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/token_store.dart';

class FakeTokens implements TokenStore {
  String? refresh; String? userId;
  FakeTokens({this.refresh});
  @override Future<String?> getRefreshToken() async => refresh;
  @override Future<void> setRefreshToken(String t) async => refresh = t;
  @override Future<void> deleteRefreshToken() async => refresh = null;
  @override Future<String?> getUserId() async => userId;
  @override Future<void> setUserId(String id) async => userId = id;
  @override Future<void> deleteUserId() async => userId = null;
}

void main() {
  test('single-flight refresh: concurrent 401s trigger one refresh and all retry', () async {
    var refreshCalls = 0;
    var token = 'old';
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        token = 'new';
        return http.Response(jsonEncode({'accessToken': 'new', 'refreshToken': 'r2', 'userId': 'u1'}), 200);
      }
      final auth = req.headers['Authorization'];
      if (auth != 'Bearer $token') return http.Response('{"error":"expired"}', 401);
      return http.Response('{"ok":true}', 200);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens(refresh: 'r1'));
    // No access token yet → every call 401s first.
    final results = await Future.wait(List.generate(5, (_) => api.apiFetch('/api/pages')));
    expect(results.map((r) => r.statusCode), everyElement(200));
    expect(refreshCalls, 1);
  });

  test('invalid refresh (401) fires onAuthExpired and clears the refresh token', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') return http.Response('{"error":"bad"}', 401);
      return http.Response('{}', 401);
    });
    final tokens = FakeTokens(refresh: 'r1');
    final api = ApiService.custom(client: client, tokens: tokens);
    var expired = false;
    api.onAuthExpired = () => expired = true;
    final r = await api.apiFetch('/api/pages');
    expect(r.statusCode, 401);
    expect(expired, isTrue);
    expect(tokens.refresh, isNull);
  });

  test('offline refresh keeps the refresh token and does not expire the session', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') throw http.ClientException('no network');
      return http.Response('{}', 401);
    });
    final tokens = FakeTokens(refresh: 'r1');
    final api = ApiService.custom(client: client, tokens: tokens);
    var expired = false;
    api.onAuthExpired = () => expired = true;
    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.offline);
    final r = await api.apiFetch('/api/pages');
    expect(r.statusCode, 401);
    expect(expired, isFalse);
    expect(tokens.refresh, 'r1');
  });

  test('tryRestoreSession returns the profile on success', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'accessToken': 'a', 'refreshToken': 'r2', 'userId': 'u1', 'vip': true}), 200));
    final tokens = FakeTokens(refresh: 'r1');
    final api = ApiService.custom(client: client, tokens: tokens);
    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.ok);
    expect(restore.profile!['userId'], 'u1');
    expect(tokens.refresh, 'r2');
  });
}
```

- [ ] **Step 2: Run → FAIL** (`token_store.dart` missing, `ApiService.custom` undefined).

- [ ] **Step 3: Implement**

`token_store.dart`: the abstract class above. `storage_service.dart`: `class StorageService implements TokenStore` + `_userIdKey = 'user_id'` with get/set/delete.

`api_service.dart` core changes:
```dart
class ApiService {
  static final ApiService _instance = ApiService.custom();
  factory ApiService() => _instance;

  @visibleForTesting
  ApiService.custom({http.Client? client, TokenStore? tokens})
      : _client = client ?? http.Client(),
        _tokens = tokens ?? StorageService();

  final http.Client _client;          // one keep-alive client for the whole app
  final TokenStore _tokens;
  static const _timeout = Duration(seconds: 20);
  String? _accessToken;
  Future<RefreshOutcome>? _refreshInFlight;
  void Function(Map<String, dynamic> profile)? onTokensRefreshed;
  VoidCallback? onAuthExpired;

  Future<http.Response> apiFetch(path, {method, body, headers}) async {
    final usedToken = _accessToken;
    final response = await _send(...);
    if (response.statusCode != 401) return response;
    // Someone else already rotated the token while this request was in flight.
    if (usedToken != _accessToken) return _send(...);
    switch (await _refreshTokens()) {
      case RefreshOutcome.ok: return _send(...);
      case RefreshOutcome.invalid: _handleAuthExpired(); return response;
      case RefreshOutcome.offline: return response;
    }
  }

  Future<http.Response> _send(...) → _client.get/post/put/patch/delete(...).timeout(_timeout)

  Future<RefreshOutcome> _refreshTokens() =>
      _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);

  Future<RefreshOutcome> _doRefresh() async {
    final refreshToken = await _tokens.getRefreshToken();
    if (refreshToken == null) return RefreshOutcome.invalid;
    try {
      final response = await _client.post(Uri.parse('$baseUrl/api/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken})).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['accessToken'] as String;
        await _tokens.setRefreshToken(data['refreshToken'] as String);
        final userId = data['userId'];
        if (userId is String) await _tokens.setUserId(userId);
        _lastProfile = data;
        onTokensRefreshed?.call(data);
        return RefreshOutcome.ok;
      }
      if (response.statusCode == 401 || response.statusCode == 403) return RefreshOutcome.invalid;
      return RefreshOutcome.offline;         // 5xx / 429: transient
    } catch (e) {
      debugPrint('Token refresh failed (transient): $e');
      return RefreshOutcome.offline;
    }
  }

  Future<RestoreResult> tryRestoreSession() async {
    final outcome = await _refreshTokens();
    return RestoreResult(outcome, outcome == RefreshOutcome.ok ? _lastProfile : null);
  }

  void _handleAuthExpired() { _accessToken = null; _tokens.deleteRefreshToken(); _tokens.deleteUserId(); onAuthExpired?.call(); }
```
`login`/`register`/`oauthSignIn` use `_client.post(...).timeout(_timeout)` and call `_tokens.setUserId(data['userId'])`. `logout` deletes both.

- [ ] **Step 4: Run tests → PASS. `flutter analyze` clean. Commit.**

```bash
git add flutter_app/lib/services flutter_app/test/api_service_test.dart
git commit -m "Flutter: persistent keep-alive HTTP client, 20s timeout, single-flight refresh, offline-aware auth outcome"
```

---

### Task 8: `WsService` reconnect hook

**Files:** Modify `flutter_app/lib/services/ws_service.dart`

**Interfaces (produces):** `void ensureConnected()`, `VoidCallback? onReconnected` (fires on `auth:ok` for every connect after the first of the session).

- [ ] **Step 1: Implement**

```dart
  bool _hadSessionConnect = false;
  VoidCallback? onReconnected;

  void connect() { _intentionalDisconnect = false; _hadSessionConnect = false; _connectInternal(); }
  void ensureConnected() { if (_channel != null) return; _intentionalDisconnect = false; _connectInternal(); }
  void disconnect() { ...existing...; _hadSessionConnect = false; }

  void _connectInternal() {
    if (_channel != null) return;         // never double-connect
    ...
  }

  void _onMessage(dynamic raw) {
    ... parse ...
    if (message.event == 'auth:ok') {
      if (_hadSessionConnect) onReconnected?.call();
      _hadSessionConnect = true;
    }
    ... dispatch to listeners ...
  }
```

- [ ] **Step 2: `flutter analyze`, commit**

```bash
git add flutter_app/lib/services/ws_service.dart
git commit -m "Flutter: WsService.ensureConnected + onReconnected hook (resync after a dropped socket)"
```

---

### Task 9: `CellsProvider` on the `YearCells` store

**Files:**
- Modify: `flutter_app/lib/providers/cells_provider.dart`
- Create: `flutter_app/test/cells_provider_test.dart`

**Interfaces (produces):**
```dart
class CellsProvider extends ChangeNotifier {
  CellsProvider({ApiService? api});
  String? get currentPageId; int get currentYear;
  YearCells? cellsFor(String pageId, int year); YearCells? get current; List<CellModel> get cells;
  bool isYearLoaded(int year);
  void setContext({required String? pageId, required int year}); void setYear(int year);
  void applyBootstrap(int year, Map<String, dynamic> cellsByPage); void clear();
  CellModel? getCell(int month, int day); String? getCellColor(int month, int day);
  int get filledDays; int get currentStreak;
  Future<void> setCell(int month, int day, String color, {String? comment});
  Future<void> deleteCell(int month, int day); Future<void> recolorCells(Map<String, String> colorMap);
}
```
Notes: `setContext`/`setYear` are synchronous and never fetch. WS events for years not loaded are ignored. `recolorCells` recolors every cached year of the page locally (no refetch).

- [ ] **Step 1: `test/cells_provider_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/services/ws_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CellsProvider loaded() {
    final p = CellsProvider();
    p.applyBootstrap(2026, {
      'a': [[1, 1, '#AAAAAA'], [1, 2, '#BBBBBB', 'hi']],
      'b': <dynamic>[],
    });
    return p;
  }

  test('applyBootstrap loads every page and marks the year loaded', () {
    final p = loaded();
    expect(p.isYearLoaded(2026), isTrue);
    expect(p.isYearLoaded(2025), isFalse);
    expect(p.cellsFor('a', 2026)!.length, 2);
    expect(p.cellsFor('b', 2026)!.isEmpty, isTrue);
    expect(p.cellsFor('a', 2025), isNull);
  });

  test('setContext is synchronous and exposes current cells', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    expect(p.getCell(1, 2)?.comment, 'hi');
    expect(p.getCellColor(1, 1), '#AAAAAA');
    expect(p.cells.length, 2);
    expect(p.filledDays, 2);
  });

  test('currentStreak counts consecutive days ending today', () {
    final p = CellsProvider();
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = d0.subtract(const Duration(days: 1));
    final d2 = d0.subtract(const Duration(days: 2));
    p.applyBootstrap(now.year, {
      'a': [[d0.month, d0.day, '#AAAAAA'], [d1.month, d1.day, '#AAAAAA'], [d2.month, d2.day, '#AAAAAA']]
          .where((r) => DateTime(now.year, r[0] as int, r[1] as int).year == now.year).toList(),
    });
    p.setContext(pageId: 'a', year: now.year);
    expect(p.currentStreak, greaterThanOrEqualTo(1));
  });

  test('WS cell:updated applies only to loaded years', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    var notified = 0;
    p.addListener(() => notified++);
    // Simulate the WS layer by calling the handler through the public test hook.
    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': ''}));
    expect(p.getCell(3, 3)?.color, '#CCCCCC');
    expect(notified, 1);
    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2025, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': ''}));
    expect(p.cellsFor('a', 2025), isNull);
  });

  test('WS cells:recolored recolors every cached year of the page without refetch', () {
    final p = loaded();
    p.applyBootstrap(2025, {'a': [[5, 5, '#AAAAAA']], 'b': <dynamic>[]});
    p.debugHandleWs(const WsMessage(event: 'cells:recolored', data: {'pageId': 'a', 'colorMap': {'#AAAAAA': '#111111'}}));
    expect(p.cellsFor('a', 2026)!.get(1, 1)!.color, '#111111');
    expect(p.cellsFor('a', 2025)!.get(5, 5)!.color, '#111111');
    expect(p.cellsFor('a', 2026)!.get(1, 2)!.color, '#BBBBBB');
  });

  test('identity only changes for the touched (page, year)', () {
    final p = loaded();
    final a = p.cellsFor('a', 2026);
    final b = p.cellsFor('b', 2026);
    p.debugHandleWs(const WsMessage(event: 'cell:deleted', data: {'pageId': 'a', 'year': 2026, 'month': 1, 'day': 1}));
    expect(identical(p.cellsFor('a', 2026), a), isFalse);
    expect(identical(p.cellsFor('b', 2026), b), isTrue);
  });

  test('clear forgets everything', () {
    final p = loaded();
    p.clear();
    expect(p.isYearLoaded(2026), isFalse);
    expect(p.cellsFor('a', 2026), isNull);
  });
}
```
`debugHandleWs(WsMessage)` is a `@visibleForTesting` passthrough to the private WS handler.

- [ ] **Step 2: Run → FAIL.** Then rewrite `cells_provider.dart` per the interface (streak logic moved from `TrackerScreen._calculateStreak`, using `current?.get`; stats memoized on `identical(current, _statsSource)` and the calendar day).

Key implementation fragments:
```dart
  static String _key(String pageId, int year) => '$pageId:$year';
  YearCells _entry(String pageId, int year) => _store[_key(pageId, year)] ?? YearCells.empty(pageId, year);
  void _put(YearCells yc) => _store[_key(yc.pageId, yc.year)] = yc;

  void applyBootstrap(int year, Map<String, dynamic> cellsByPage) {
    _store.removeWhere((_, yc) => yc.year == year);
    cellsByPage.forEach((pageId, rows) => _put(YearCells.fromCompact(pageId, year, rows as List<dynamic>)));
    _loadedYears.add(year);
    notifyListeners();
  }

  Future<void> setCell(int month, int day, String color, {String? comment}) async {
    final pageId = _currentPageId; if (pageId == null) return;
    final year = _currentYear;
    final previous = getCell(month, day);
    // Server semantics: an absent comment clears it. Mirror that optimistically.
    final optimistic = CellModel(pageId: pageId, year: year, month: month, day: day, color: color,
        comment: comment, updatedAt: DateTime.now().toIso8601String());
    _put(_entry(pageId, year).upsert(optimistic));
    notifyListeners(); _audio.playTap();
    try {
      final response = await _api.apiFetch('/api/cells/$pageId', method: 'PUT',
          body: {'year': year, 'month': month, 'day': day, 'color': color, 'comment': ?comment});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final confirmed = CellModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _put(_entry(confirmed.pageId, confirmed.year).upsert(confirmed));
      } else { _revert(pageId, year, month, day, previous); }
    } catch (e) { debugPrint(...); _revert(pageId, year, month, day, previous); }
    notifyListeners();
  }
```

- [ ] **Step 3: Run tests → PASS; `flutter analyze` (expect errors in screens still calling removed `fetchPreviewCells` — they are fixed in Task 13; proceed). Commit.**

```bash
git add flutter_app/lib/providers/cells_provider.dart flutter_app/test/cells_provider_test.dart
git commit -m "Flutter: CellsProvider becomes a YearCells store (O(1) lookups, memoized stats, no refetch on navigation)"
```

---

### Task 10: `LegendsProvider` + `PagesProvider` on the store

**Files:**
- Modify: `flutter_app/lib/providers/legends_provider.dart`, `flutter_app/lib/providers/pages_provider.dart`
- Create: `flutter_app/test/legends_provider_test.dart`

**Interfaces (produces):**
```dart
class LegendsProvider { List<LegendModel> get legends; List<LegendModel> legendsFor(String pageId); void setPageId(String? id); void applyBootstrap(Map<String, dynamic> byPage); void clear(); @visibleForTesting void debugHandleWs(WsMessage m); /* CRUD unchanged */ }
class PagesProvider { void applyBootstrap(List<dynamic> pages); void clear(); Future<void> reorderPages(List<String> ids); /* rest unchanged, fetchPages removed */ }
```

- [ ] **Step 1: `test/legends_provider_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/services/ws_service.dart';

Map<String, dynamic> legend(String id, String pageId, String color, int pos) =>
    {'id': id, 'pageId': pageId, 'color': color, 'label': id, 'position': pos, 'createdAt': ''};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LegendsProvider loaded() => LegendsProvider()
    ..applyBootstrap({'a': [legend('l1', 'a', '#AAAAAA', 0), legend('l2', 'a', '#BBBBBB', 1)], 'b': <dynamic>[]});

  test('legendsFor / legends follow the current page', () {
    final p = loaded();
    expect(p.legendsFor('a').length, 2);
    expect(p.legends, isEmpty);
    p.setPageId('a');
    expect(p.legends.map((l) => l.id), ['l1', 'l2']);
  });

  test('legends:reordered uses ids (bug fix: previously ignored)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(const WsMessage(event: 'legends:reordered', data: {'pageId': 'a', 'ids': ['l2', 'l1']}));
    expect(p.legends.map((l) => l.id), ['l2', 'l1']);
  });

  test('legends:recolored uses colorMap (bug fix)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(const WsMessage(event: 'legends:recolored', data: {'pageId': 'a', 'colorMap': {'#AAAAAA': '#111111'}}));
    expect(p.legends.first.color, '#111111');
  });

  test('legend events apply to non-current pages too (card previews stay fresh)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(WsMessage(event: 'legend:created', data: legend('l3', 'b', '#CCCCCC', 0)));
    expect(p.legendsFor('b').length, 1);
    p.debugHandleWs(const WsMessage(event: 'legend:deleted', data: {'id': 'l3', 'pageId': 'b'}));
    expect(p.legendsFor('b'), isEmpty);
  });
}
```

- [ ] **Step 2: Run → FAIL. Implement `LegendsProvider`** (copy-on-write lists per page; CRUD operate on `_currentPageId`; `_fetchLegends`, `fetchPreviewLegends`, `getPreviewLegends` removed).

- [ ] **Step 3: `PagesProvider`**: replace `fetchPages` with `applyBootstrap(List<dynamic>)` + `clear()`; `reorderPages` sends one `PUT /api/pages/reorder {ids}` (revert to the previous order on failure); handle WS `pages:reordered {ids}` by re-assigning positions in `ids` order.

- [ ] **Step 4: Tests PASS, commit.**

```bash
git add flutter_app/lib/providers/legends_provider.dart flutter_app/lib/providers/pages_provider.dart flutter_app/test/legends_provider_test.dart
git commit -m "Flutter: LegendsProvider keyed by page (fixes reorder/recolor sync), PagesProvider single reorder request"
```

---

### Task 11: `SnapshotStore` + `SyncService`

**Files:**
- Create: `flutter_app/lib/services/snapshot_store.dart`, `flutter_app/lib/services/sync_service.dart`, `flutter_app/test/sync_service_test.dart`
- Modify: `flutter_app/pubspec.yaml` (`path_provider: ^2.1.5`)

**Interfaces (produces):**
```dart
abstract class SnapshotStore { Future<String?> read(); Future<void> write(String json); Future<void> delete(); }
class FileSnapshotStore implements SnapshotStore { /* <app support dir>/snapshot_v1.json, temp+rename, errors swallowed */ }
class SyncService with WidgetsBindingObserver {
  SyncService({required ApiService api, required PagesProvider pages, required CellsProvider cells, required LegendsProvider legends, required WsService ws, SnapshotStore? snapshots, bool observeLifecycle = true});
  int get activeYear;
  Future<bool> start({required String userId, required int year});   // true when pages were hydrated from disk
  Future<void> ensureYear(int year);
  Future<void> revalidate();
  Future<void> persistSnapshot();
  Future<void> clear();
  void dispose();
}
```

- [ ] **Step 1: `test/sync_service_test.dart`**

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/snapshot_store.dart';
import 'package:dian_dian/services/sync_service.dart';
import 'package:dian_dian/services/token_store.dart';
import 'package:dian_dian/services/ws_service.dart';

class MemorySnapshots implements SnapshotStore {
  String? data;
  @override Future<String?> read() async => data;
  @override Future<void> write(String json) async => data = json;
  @override Future<void> delete() async => data = null;
}

class FakeTokens implements TokenStore {
  @override Future<String?> getRefreshToken() async => 'r';
  @override Future<void> setRefreshToken(String t) async {}
  @override Future<void> deleteRefreshToken() async {}
  @override Future<String?> getUserId() async => 'u1';
  @override Future<void> setUserId(String id) async {}
  @override Future<void> deleteUserId() async {}
}

Map<String, dynamic> bootstrapBody(int year, {String color = '#AAAAAA'}) => {
  'year': year,
  'pages': [{'id': 'a', 'userId': 'u1', 'title': 'A', 'position': 0, 'palette': null, 'createdAt': '', 'year': year}],
  'legends': {'a': [{'id': 'l1', 'pageId': 'a', 'color': color, 'label': 'L', 'position': 0, 'createdAt': ''}]},
  'cells': {'a': [[1, 1, color]]},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int bootstrapCalls;
  late MemorySnapshots snapshots;
  late PagesProvider pages; late CellsProvider cells; late LegendsProvider legends;

  SyncService build({Map<String, dynamic> Function(int year)? body}) {
    bootstrapCalls = 0;
    final client = MockClient((req) async {
      if (req.url.path == '/api/bootstrap') {
        bootstrapCalls++;
        final year = int.parse(req.url.queryParameters['year']!);
        return http.Response(jsonEncode((body ?? bootstrapBody)(year)), 200);
      }
      return http.Response('{}', 404);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    snapshots = MemorySnapshots();
    pages = PagesProvider(); cells = CellsProvider(); legends = LegendsProvider();
    return SyncService(api: api, pages: pages, cells: cells, legends: legends, ws: WsService(),
        snapshots: snapshots, observeLifecycle: false);
  }

  test('ensureYear fetches once per year and applies to all providers', () async {
    final sync = build();
    await Future.wait([sync.ensureYear(2026), sync.ensureYear(2026)]);
    await sync.ensureYear(2026);
    expect(bootstrapCalls, 1);
    expect(pages.pages.single.id, 'a');
    expect(legends.legendsFor('a').single.id, 'l1');
    expect(cells.cellsFor('a', 2026)!.get(1, 1)!.color, '#AAAAAA');
    expect(snapshots.data, isNotNull);
  });

  test('start hydrates from a matching snapshot before the network', () async {
    final first = build();
    await first.ensureYear(2026);
    final saved = snapshots.data!;
    final sync = build();
    snapshots.data = saved;
    final hydrated = await sync.start(userId: 'u1', year: 2026);
    expect(hydrated, isTrue);
    expect(pages.pages.single.id, 'a');
    expect(cells.cellsFor('a', 2026)!.length, 1);
  });

  test('snapshot of another user is ignored', () async {
    final first = build();
    await first.ensureYear(2026);
    final saved = snapshots.data!;
    final sync = build();
    snapshots.data = saved;
    final hydrated = await sync.start(userId: 'someone-else', year: 2026);
    expect(hydrated, isFalse);
    expect(pages.pages, isEmpty);
  });

  test('revalidate with an unchanged body does not notify', () async {
    final sync = build();
    await sync.ensureYear(2026);
    var notified = 0;
    cells.addListener(() => notified++);
    await sync.revalidate();
    expect(bootstrapCalls, 2);
    expect(notified, 0);
  });

  test('revalidate with a changed body applies it', () async {
    var color = '#AAAAAA';
    final sync = build(body: (y) => bootstrapBody(y, color: color));
    await sync.ensureYear(2026);
    color = '#222222';
    await sync.revalidate();
    expect(cells.cellsFor('a', 2026)!.get(1, 1)!.color, '#222222');
  });

  test('clear wipes providers and snapshot', () async {
    final sync = build();
    await sync.ensureYear(2026);
    await sync.clear();
    expect(pages.pages, isEmpty);
    expect(cells.isYearLoaded(2026), isFalse);
    expect(snapshots.data, isNull);
  });
}
```

- [ ] **Step 2: Run → FAIL. Implement.**

`snapshot_store.dart`:
```dart
class FileSnapshotStore implements SnapshotStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/snapshot_v1.json');
  @override Future<String?> read() async { try { final f = await _file(); return await f.exists() ? await f.readAsString() : null; } catch (e) { debugPrint('Snapshot read failed: $e'); return null; } }
  @override Future<void> write(String json) async { try { final f = await _file(); final tmp = File('${f.path}.tmp'); await tmp.writeAsString(json, flush: true); await tmp.rename(f.path); } catch (e) { debugPrint('Snapshot write failed: $e'); } }
  @override Future<void> delete() async { try { final f = await _file(); if (await f.exists()) await f.delete(); } catch (_) {} }
}
```

`sync_service.dart` core:
```dart
class SyncService with WidgetsBindingObserver {
  static const _snapshotVersion = 1;
  String? _userId; int _activeYear = DateTime.now().year;
  final Map<int, Future<void>> _inflight = {};
  final Map<int, String> _lastBody = {};

  SyncService({...}) { if (observeLifecycle) WidgetsBinding.instance.addObserver(this); _ws.onReconnected = () => revalidate(); }

  Future<bool> start({required String userId, required int year}) async {
    _userId = userId; _activeYear = year;
    final hydrated = await _hydrate(userId, year);
    unawaited(ensureYear(year));
    return hydrated;
  }

  Future<void> ensureYear(int year) { _activeYear = year; if (_cells.isYearLoaded(year)) return Future.value(); return _bootstrap(year); }
  Future<void> revalidate() { if (_userId == null) return Future.value(); return _bootstrap(_activeYear); }

  Future<void> _bootstrap(int year) => _inflight[year] ??= _fetch(year).whenComplete(() => _inflight.remove(year));

  Future<void> _fetch(int year) async {
    final res = await _api.apiFetch('/api/bootstrap?year=$year');
    if (res.statusCode != 200) return;              // keep what we have (cache / previous)
    if (_lastBody[year] == res.body) return;        // nothing changed → no notify, no repaint
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _apply(data, applyCells: true);
    _lastBody[year] = res.body;
    await persistSnapshot();
  }

  void _apply(Map<String, dynamic> data, {required bool applyCells}) {
    _pages.applyBootstrap(data['pages'] as List<dynamic>);
    _legends.applyBootstrap(data['legends'] as Map<String, dynamic>);
    if (applyCells) _cells.applyBootstrap(data['year'] as int, data['cells'] as Map<String, dynamic>);
  }

  Future<bool> _hydrate(String userId, int year) async {
    final raw = await _snapshots.read(); if (raw == null) return false;
    try {
      final snap = jsonDecode(raw) as Map<String, dynamic>;
      if (snap['v'] != _snapshotVersion || snap['userId'] != userId) return false;
      final data = snap['data'] as Map<String, dynamic>;
      _apply(data, applyCells: data['year'] == year);
      return (data['pages'] as List).isNotEmpty;
    } catch (e) { debugPrint('Snapshot hydrate failed: $e'); return false; }
  }

  Map<String, dynamic> _serialize(int year) => {
    'year': year,
    'pages': _pages.pages.map((p) => p.toJson()).toList(),
    'legends': {for (final p in _pages.pages) p.id: _legends.legendsFor(p.id).map((l) => l.toJson()).toList()},
    'cells': {for (final p in _pages.pages) p.id: _cells.cellsFor(p.id, year)?.toCompact() ?? const []},
  };

  Future<void> persistSnapshot() async {
    final userId = _userId; if (userId == null) return;
    if (!_cells.isYearLoaded(_activeYear) && _pages.pages.isEmpty) return;
    await _snapshots.write(jsonEncode({'v': _snapshotVersion, 'userId': userId, 'year': _activeYear,
        'savedAt': DateTime.now().toIso8601String(), 'data': _serialize(_activeYear)}));
  }

  Future<void> clear() async { _userId = null; _inflight.clear(); _lastBody.clear(); _pages.clear(); _legends.clear(); _cells.clear(); await _snapshots.delete(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_userId == null) return;
    switch (state) {
      case AppLifecycleState.resumed: _ws.ensureConnected(); revalidate(); break;
      case AppLifecycleState.paused: case AppLifecycleState.hidden: persistSnapshot(); break;
      default: break;
    }
  }
}
```
Note on `persistSnapshot` after hydration-only: `_serialize` emits cells only if the year is loaded — when not loaded it writes `[]` for every page, which would overwrite a good snapshot with an empty one. Guard: `if (!_cells.isYearLoaded(_activeYear)) return;` in `persistSnapshot` (pages/legends alone are not worth a write; they are rewritten with the next bootstrap).

- [ ] **Step 3: Add `path_provider: ^2.1.5` to `pubspec.yaml`, `flutter pub get`, tests PASS, commit.**

```bash
git add flutter_app/pubspec.yaml flutter_app/pubspec.lock flutter_app/lib/services/snapshot_store.dart flutter_app/lib/services/sync_service.dart flutter_app/test/sync_service_test.dart
git commit -m "Flutter: SyncService (bootstrap, disk snapshot, resume/reconnect revalidation)"
```

---

### Task 12: `AuthProvider` — profile from refresh, offline session

**Files:** Modify `flutter_app/lib/providers/auth_provider.dart`

- [ ] **Step 1: Implement**

```dart
  Future<void> tryRestoreSession() async {
    _isLoading = true; notifyListeners();
    final result = await _api.tryRestoreSession();
    switch (result.outcome) {
      case RefreshOutcome.ok:
        _applyProfile(result.profile!);
        _isAuthenticated = true;
        _ws.connect();
      case RefreshOutcome.invalid:
        _isAuthenticated = false;
      case RefreshOutcome.offline:
        // A stored session exists but the network does not: keep the user in,
        // show cached data, recover on the first successful request.
        final userId = await _storage.getUserId();
        if (userId != null) {
          _userId = userId; _email = await _storage.getEmail();
          _isVip = (await SharedPreferences.getInstance()).getBool(_vipKey) ?? false;
          _isAuthenticated = true;
        } else { _isAuthenticated = false; }
    }
    _isLoading = false; notifyListeners();
  }

  void _applyProfile(Map<String, dynamic> data) {
    _userId = data['userId'] as String? ?? _userId;
    _email = data['email'] as String? ?? _email;
    _isVip = data['vip'] == true;
    _serverSettings = {'theme': data['theme'], 'language': data['language'], 'cursorId': data['cursorId'], 'cursorEnabled': data['cursorEnabled'], 'premium': data['premium']};
    SharedPreferences.getInstance().then((p) => p.setBool(_vipKey, _isVip));
  }
```
Constructor: `_api.onTokensRefreshed = (profile) { _applyProfile(profile); _ws.ensureConnected(); notifyListeners(); };`
`login/register/oauthSignIn` use `_applyProfile(data)` and `_storage.setUserId(_userId!)`. `logout` deletes userId.

- [ ] **Step 2: `flutter analyze` on the file, commit.**

```bash
git add flutter_app/lib/providers/auth_provider.dart
git commit -m "Flutter: AuthProvider reads the profile from /refresh, keeps the session when offline"
```

---

### Task 13: Screens — AppShell, PageList, Tracker, GlobalStats

**Files:** Modify `lib/main.dart`, `lib/screens/page_list_screen.dart`, `lib/screens/tracker_screen.dart`, `lib/widgets/global_stats_dialog.dart`, `pubspec.yaml` (version `1.3.0+7`)

- [ ] **Step 1: `main.dart`** — provide `SyncService`; replace `_restoreAttempted`/`_restoreLastTracker` with a session start:

```dart
Provider<SyncService>(
  create: (ctx) => SyncService(api: ApiService(), pages: ctx.read<PagesProvider>(), cells: ctx.read<CellsProvider>(),
      legends: ctx.read<LegendsProvider>(), ws: WsService()),
  dispose: (_, s) => s.dispose(),
  lazy: false,
),
```
In `_AppShellState`:
```dart
  bool _sessionStarted = false;

  Future<void> _startSession(AuthProvider auth) async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastTrackerIdKey);
    final year = lastId != null ? (prefs.getInt(_lastTrackerYearKey) ?? DateTime.now().year) : DateTime.now().year;
    if (!mounted) return;
    final sync = context.read<SyncService>();
    final hydrated = await sync.start(userId: auth.userId!, year: year);
    if (!mounted) return;
    if (await OnboardingScreen.shouldShow()) { setState(() { _screen = AppScreen.onboarding; _restoreInProgress = false; }); return; }
    if (!hydrated) await sync.ensureYear(year);     // first launch: nothing on disk, wait for the network once
    if (!mounted) return;
    final pagesProv = context.read<PagesProvider>();
    if (lastId != null && pagesProv.pages.any((p) => p.id == lastId)) {
      context.read<CellsProvider>().setContext(pageId: lastId, year: year);
      context.read<LegendsProvider>().setPageId(lastId);
      setState(() { _screen = AppScreen.tracker; _activePageId = lastId; _selectedYear = year; _restoreInProgress = false; });
    } else {
      if (lastId != null) { await prefs.remove(_lastTrackerIdKey); await prefs.remove(_lastTrackerYearKey); }
      if (mounted) setState(() { _screen = AppScreen.pageList; _restoreInProgress = false; });
    }
  }
```
`_onAuthChange`: keep the VIP/settings/ads blocks, then `if (auth.isAuthenticated && auth.userId != null && !_sessionStarted) { _sessionStarted = true; await _startSession(auth); }`; on logout branch: `_sessionStarted = false; context.read<SyncService>().clear();`.

- [ ] **Step 2: `page_list_screen.dart`**
  - `initState`: post-frame → `context.read<SyncService>().ensureYear(_selectedYear)`; remove `_fetchPreviews`.
  - `_changeYear`: `setState`, `widget.onYearChanged`, `context.read<SyncService>().ensureYear(_selectedYear)`.
  - `_openTracker`: after `setContext`/`setPageId`, `context.read<SyncService>().ensureYear(_selectedYear)`.
  - Card: `cells: cellsProv.cellsFor(page.id, _selectedYear)`, `legends: legendsProv.legendsFor(page.id)`.
  - `_PageCard.cells` and `_MiniGrid.cells` become `YearCells?`; `_MiniGridPainter(this.cells, this.year)` reads `cells?.get(month, day)?.color`; `shouldRepaint => !identical(old.cells, cells) || old.year != year`.

- [ ] **Step 3: `tracker_screen.dart`**
  - `_changeYear`: `cellsProv.setYear(newYear); context.read<SyncService>().ensureYear(newYear);`
  - Stats: `final filledDays = cellsProv.filledDays; final streak = cellsProv.currentStreak;` — delete `_calculateStreak`.

- [ ] **Step 4: `global_stats_dialog.dart`**
  - Keep per-page data as `Map<String, List<DateTime>> _daysPerPage`.
  - Year mode: built synchronously from `context.read<CellsProvider>().cellsFor(page.id, year)?.values` (no spinner, no request).
  - All-time: one `GET /api/stats/days` → `(json[pageId] as List).map((r) => DateTime(r[0], r[1], r[2]))` (wrap in try/catch per row).
  - Stats loops use `days.length` and the streak over sorted unique dates (same algorithm as today).

- [ ] **Step 5: Version bump** `version: 1.3.0+7`.

- [ ] **Step 6: `flutter analyze` clean, all tests green, commit.**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!` and all tests pass (delete the stale default `test/widget_test.dart` if it fails for unrelated reasons — it tests a counter app that does not exist).

```bash
git add flutter_app
git commit -m "Flutter: screens read from the store via SyncService; global stats from store / one request; bump 1.3.0+7"
```

---

### Task 14: Local end-to-end verification

- [ ] **Step 1: Backend up with data**

```bash
make db
cd backend && npx drizzle-kit migrate && npx tsx scripts/seed-demo-local.ts && npm run dev
```

- [ ] **Step 2: Smoke** — `cd backend && npx tsx scripts/smoke.ts` → `smoke: OK`.

- [ ] **Step 3: App on the simulator** — `cd flutter_app && flutter run -d "iPhone 18 Pro"`, login `demo@diandian.app / password`. Watch the backend terminal (add a one-line request logger behind `NODE_ENV !== 'production'` if needed):
  - cold login → exactly one `GET /api/bootstrap?year=2026`;
  - open tracker, back, open another, change year back and forth on loaded years → zero cell/legend requests;
  - year not yet loaded → one bootstrap for it;
  - kill the app, relaunch → tracker paints immediately, one bootstrap follows;
  - airplane mode, relaunch → cached data, no login screen; network back + resume → data refreshes;
  - global stats "this year" → no request; "all time" → one `/api/stats/days`;
  - December cell save works.

- [ ] **Step 4: Handoff** — summarize what to test on a real device (second device sync for legends reorder/recolor), then deploy backend first, then ship 1.3.0.
