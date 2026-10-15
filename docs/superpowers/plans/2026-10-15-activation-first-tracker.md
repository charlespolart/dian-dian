# Activation: first tracker flow — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three explanatory onboarding cards with a guided flow that creates a ready-made tracker (title + legends) and sets today's cell, add a "Today" button to the tracker, and measure activation by signup cohort.

**Architecture:** Backend 1.2.0 extends `POST /api/pages` (legends + replaces in one transaction), adds `activated` to the bootstrap, stops creating "My Tracker" at signup and adds `cells.created_at`. App 1.4.0 adds a `FirstTrackerScreen` (two screens) driven by `SyncService.activated`, a `PagesProvider.createFirstTracker` call, template data, and the Today button. Everything is additive; backend ships before the app.

**Tech Stack:** Express + TypeScript + Drizzle (Postgres), zod; Flutter 3 (provider, shared_preferences, http MockClient in tests); psql scripts.

**Spec:** `docs/superpowers/specs/2026-10-15-activation-first-tracker-design.md`

## Global Constraints

- Never touch the `vip` flag; VIP accounts are excluded from every stat.
- No automatic deploy: production only changes through `./release-backend.sh`, `./deploy-prod.sh`, `./release-app.sh` run by hand by Charles (Task 13 is his).
- Run `git branch --show-current` before every commit; must print `master`.
- Backend 1.2.0 before app 1.4.0. Apps ≤ 1.3.0 must keep working against 1.2.0.
- Server limits: page title 1–35 chars, legend label 1–30 chars, ≤ 12 legends per page, colors `#RRGGBB`.
- French UI strings use "vous" (never "tu"). Four locales: fr, en, zh-Hans (`Language.zhCN`), zh-Hant (`Language.zhTW`).
- No new Flutter dependency (no `intl`): dates are spelled with keys in `language_provider.dart`.
- Template colors exactly as in the spec table; Sport has its own palette.
- Changelogs: `backend/CHANGELOG.md` and `flutter_app/CHANGELOG.md` under `## [Unreleased]`; store notes `flutter_app/docs/changelogs/1.4.0.md`, four locales, ≤ 500 chars per block.
- Local dev DB is Postgres.app on `127.0.0.1:5433` (`backend/.env` `DATABASE_URL`); `make db` port conflict is expected, ignore it.
- `flutter analyze` must report no issue at all (infos included) and `flutter test` must pass; backend `npx tsc --noEmit` must pass.

## Review Focus

1. Midnight while screen 2 is open: the cell must be written for the day of the tap, not the day the screen opened (Task 9 test "the date is read at tap time").
2. A template label over 30 characters or a title over 35 in any language would make the server answer 400 and the whole flow fail (Task 5 test on limits in every language).
3. A free account at the 3-tracker limit with no empty page must get the normal app, never a locked fourth tracker (Task 8 test "respects the free limit").
4. `replaces` refused by the server (404 gone, 409 not empty since another device changed it): create without replacing, never an error for the user (Task 6 test "retries once without replaces").
5. Cell write fails after the page was created: Retry replays only the cell and never creates a second tracker (Task 9 test "Retry only replays the cell").

---

## Task map

| # | Side | Deliverable |
|---|---|---|
| 1 | backend | migration 0013 `cells.created_at` |
| 2 | backend | no default page at signup, `bootstrap.activated` |
| 3 | backend | `POST /api/pages` with `legends` and `replaces` |
| 4 | backend | `scripts/prod-activation.sql`, CHANGELOG |
| 5 | app | templates, strings, `formatLongDate` |
| 6 | app | `PagesProvider.createFirstTracker`, `LegendsProvider.setLegends`, WS |
| 7 | app | `SyncService.activated` |
| 8 | app | trigger decision (pure functions) |
| 9 | app | `FirstTrackerScreen` + widget tests |
| 10 | app | wiring in `main.dart`, old onboarding removed |
| 11 | app | "Today" button in the tracker |
| 12 | docs | app changelogs, README, ROADMAP |
| 13 | release | backend 1.2.0 then app 1.4.0 (Charles) |

Local backend for the smoke suite (Tasks 1–3): Postgres.app running, then

```bash
cd backend && npx drizzle-kit migrate          # applies new migrations to the local DB
cd backend && npm run dev                        # or `make back`; leave it running in another terminal
curl -fsS http://localhost:3001/api/ready        # ready → run the suite:
cd backend && npx tsx scripts/smoke.ts           # prints "smoke: OK"
```

---

### Task 1: Migration 0013 — `cells.created_at`

**Files:**
- Modify: `backend/src/db/schema.ts:101-110` (table `cells`)
- Create: `backend/drizzle/0013_cells_created_at.sql` (+ `drizzle/meta/0013_snapshot.json`, `drizzle/meta/_journal.json` entry, both generated)
- Test: `backend/scripts/smoke.ts` (assert after the December PUT)

**Interfaces:**
- Produces: column `cells.created_at timestamptz NOT NULL DEFAULT now()`, present in every cell row the API returns (`createdAt`). The cell upsert (`backend/src/routes/cells.ts` `onConflictDoUpdate`) only sets `color`, `comment`, `updatedAt`, so `created_at` keeps the first write.

- [ ] **Step 1: Write the failing smoke assertion**

In `backend/scripts/smoke.ts`, right after the line `assert.equal(r.status, 200, \`december: ${JSON.stringify(r.json)}\`);` add:

```ts
  assert.equal(typeof r.json.createdAt, 'string', 'cells carry createdAt (backend 1.2.0)');
```

- [ ] **Step 2: Run the suite to see it fail**

Run: `cd backend && npx tsx scripts/smoke.ts` (backend running, see Task map)
Expected: FAIL with `cells carry createdAt (backend 1.2.0)`.

- [ ] **Step 3: Declare the column**

In `backend/src/db/schema.ts`, table `cells`, add after `comment`:

```ts
  // Set once at the first write (1.2.0, backfilled from updated_at);
  // the upsert never touches it. Activation stats read it.
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
```

- [ ] **Step 4: Generate the migration and append the backfill**

Run: `cd backend && npx drizzle-kit generate --name cells_created_at`
Expected: `drizzle/0013_cells_created_at.sql` containing

```sql
ALTER TABLE "cells" ADD COLUMN "created_at" timestamp with time zone DEFAULT now() NOT NULL;
```

Append to that file so it reads:

```sql
ALTER TABLE "cells" ADD COLUMN "created_at" timestamp with time zone DEFAULT now() NOT NULL;--> statement-breakpoint
UPDATE "cells" SET "created_at" = "updated_at";
```

Check `drizzle/meta/_journal.json` gained an entry with `"tag": "0013_cells_created_at"`.

- [ ] **Step 5: Migrate locally, typecheck, run the suite**

Run: `cd backend && npx drizzle-kit migrate && npx tsc --noEmit` then restart the dev server if it does not reload, then `npx tsx scripts/smoke.ts`
Expected: `smoke: OK`.

- [ ] **Step 6: Commit**

```bash
git branch --show-current   # master
git add backend/src/db/schema.ts backend/drizzle backend/scripts/smoke.ts
git commit -m "Backend: cells.created_at (migration 0013, backfilled from updated_at)"
```

---

### Task 2: No default page at signup, `bootstrap.activated`

**Files:**
- Modify: `backend/src/routes/auth.ts:5` (import), `:89-90` (register), `:191-192` (OAuth)
- Modify: `backend/src/routes/bootstrap.ts:5` (import), `:36-81` (handler)
- Modify: `backend/scripts/smoke.ts` ("default page exists" block, bootstrap block)
- Modify: `flutter_app/integration/backend_e2e_test.dart:81-84`

**Interfaces:**
- Produces: `GET /api/bootstrap` body gains `activated: boolean` (true iff at least one row of `cells` joins a page of the user, any year). Register and OAuth first login create no page.

- [ ] **Step 1: Rewrite the smoke expectations**

In `backend/scripts/smoke.ts` replace the block

```ts
  // --- default page exists ----------------------------------------------
  r = await call('GET', '/api/pages');
  assert.equal(r.status, 200);
  assert.equal(r.json.length, 1, 'one default page');
  const pageId: string = r.json[0].id;
```

with

```ts
  // --- no default page since 1.2.0: the app creates the first tracker -------
  r = await call('GET', '/api/pages');
  assert.equal(r.status, 200);
  assert.deepEqual(r.json, [], 'no default page at register');
  r = await call('GET', '/api/bootstrap');
  assert.equal(r.json.activated, false, 'activated: no cell yet');
  r = await call('POST', '/api/pages', { title: 'First', position: 0 });
  assert.equal(r.status, 201);
  const pageId: string = r.json.id;
```

and in the `// --- bootstrap ---` block, after `assert.equal(r.json.year, 2026);` add:

```ts
  assert.equal(r.json.activated, true, 'activated once a cell exists');
```

- [ ] **Step 2: Run the suite to see it fail**

Run: `cd backend && npx tsx scripts/smoke.ts`
Expected: FAIL at `no default page at register`.

- [ ] **Step 3: Stop creating "My Tracker"**

In `backend/src/routes/auth.ts` delete the two statements (and their `// Create default page` / `plus default page` comments):

```ts
    await db.insert(pages).values({ userId: user.id, title: 'My Tracker', position: 0 });
```
```ts
    await db.insert(pages).values({ userId: created.id, title: 'My Tracker', position: 0 });
```

Change the OAuth comment `// 3) Brand-new account — create user (no password) + link, plus default page.` to `// 3) Brand-new account — create user (no password) + link. No default page since 1.2.0: the app's first-tracker flow creates it.` and remove `pages` from the schema import on line 5:

```ts
import { users, refreshTokens, passwordResetTokens, subscriptions, oauthAccounts } from '../db/schema.js';
```

- [ ] **Step 4: Add `activated` to the bootstrap**

In `backend/src/routes/bootstrap.ts` change the drizzle import to `import { eq, and, asc, sql } from 'drizzle-orm';`, add a fourth query to the `Promise.all` and the field to the response:

```ts
    const [pageRows, legendRows, cellRows, anyCell] = await Promise.all([
      // ... the three existing queries unchanged ...
      // Any cell at all for this account (any page, any year): drives the
      // first-tracker flow in app ≥ 1.4.0. Index pages_user_id_idx + the
      // cells primary key (page_id first) make it a lookup.
      db.select({ one: sql<number>`1` })
        .from(cells)
        .innerJoin(pages, eq(pages.id, cells.pageId))
        .where(eq(pages.userId, userId))
        .limit(1),
    ]);
```

```ts
    res.json({
      year,
      activated: anyCell.length > 0,
      pages: pageRows.map((p) => ({ ...p, palette: p.palette ? JSON.parse(p.palette) : null })),
      legends: legendsByPage,
      cells: cellsByPage,
    });
```

Update the route comment above the handler: add a line `// \`activated\`: the account has at least one cell (any page, any year).`

- [ ] **Step 5: Typecheck and run the suite**

Run: `cd backend && npx tsc --noEmit && npx tsx scripts/smoke.ts`
Expected: `smoke: OK`.

- [ ] **Step 6: Fix the integration test that assumed the default page**

In `flutter_app/integration/backend_e2e_test.dart` replace

```dart
    expect(pages.pages.length, 1, reason: 'default tracker created at register');
    final pageId = pages.pages.single.id;
    expect(cells.isYearLoaded(year), isTrue);
    expect(cells.cellsFor(pageId, year)!.isEmpty, isTrue);
```

with

```dart
    expect(pages.pages, isEmpty, reason: 'no default tracker since backend 1.2.0');
    final first = await pages.createPage('First');
    expect(first, isNotNull, reason: 'the app creates the first tracker');
    final pageId = first!.id;
    // The new page has no cells entry until a bootstrap sees it.
    await sync.ensureYear(year);
    expect(cells.isYearLoaded(year), isTrue);
    expect(cells.cellsFor(pageId, year)!.isEmpty, isTrue);
```

Run: `cd flutter_app && flutter test integration/backend_e2e_test.dart` (backend running)
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git branch --show-current   # master
git add backend/src/routes/auth.ts backend/src/routes/bootstrap.ts backend/scripts/smoke.ts flutter_app/integration/backend_e2e_test.dart
git commit -m "Backend: no default page at signup, bootstrap reports activated (any cell on the account)"
```

---

### Task 3: `POST /api/pages` with `legends` and `replaces`

**Files:**
- Modify: `backend/src/routes/pages.ts:27-48` (schema + create handler)
- Test: `backend/scripts/smoke.ts` (new section before `// --- cleanup`)

**Interfaces:**
- Consumes: tables `pages`, `legends`, `cells` from `schema.ts`; `broadcast(userId, event, data)` from `lib/ws.ts`.
- Produces: request body `{ title, position?, year?, legends?: [{color, label}] (≤ 12), replaces?: uuid }`. Response 201 `{ ...page, palette, legends: Legend[], replaced: string | null }`. 404 `{ error: 'Page not found' }` when `replaces` is not the caller's page; 409 `{ error: 'Page is not empty' }` when it has a legend or a cell; nothing written in both cases. WS `page:deleted { id }` (if replaced) then `page:created` with the response body.

- [ ] **Step 1: Write the failing smoke section**

In `backend/scripts/smoke.ts`, before `// --- cleanup ---`, add:

```ts
  // --- first tracker (app 1.4.0): page + legends in one transaction ---------
  {
    r = await call('POST', '/api/pages', {
      title: 'Humeur',
      legends: [
        { color: '#FFEC99', label: 'Génial' }, { color: '#FFD43B', label: 'Super' },
        { color: '#8CE99A', label: 'Bien' }, { color: '#74C0FC', label: 'Bof' }, { color: '#E599F7', label: 'Mou' },
      ],
    });
    assert.equal(r.status, 201, `create with legends: ${JSON.stringify(r.json)}`);
    const mood: string = r.json.id;
    assert.equal(r.json.position, 0, 'position defaults to 0 when omitted');
    assert.deepEqual(
      r.json.legends.map((l: Json) => [l.label, l.position]),
      [['Génial', 0], ['Super', 1], ['Bien', 2], ['Bof', 3], ['Mou', 4]],
      'legends created in order',
    );
    assert.equal(r.json.replaced, null, 'nothing replaced');
    r = await call('GET', `/api/legends/${mood}`);
    assert.equal(r.json.length, 5, 'legends persisted');

    r = await call('POST', '/api/pages', { title: 'Empty', position: 7 });
    assert.equal(r.status, 201);
    const empty: string = r.json.id;
    assert.deepEqual(r.json.legends, [], 'legends key always present');
    r = await call('POST', '/api/pages', {
      title: 'Sommeil', replaces: empty, legends: [{ color: '#1864AB', label: '8 h+' }],
    });
    assert.equal(r.status, 201, `replace: ${JSON.stringify(r.json)}`);
    const sleep: string = r.json.id;
    assert.equal(r.json.replaced, empty, 'reports the replaced page');
    assert.equal(r.json.position, 7, 'takes the position of the replaced page');
    r = await call('GET', '/api/pages');
    const ids: string[] = r.json.map((p: Json) => p.id);
    assert.ok(!ids.includes(empty) && ids.includes(sleep), 'replaced page is gone, new one is there');

    const before = ids.length;
    r = await call('POST', '/api/pages', { title: 'Nope', replaces: mood });
    assert.equal(r.status, 409, 'a page with legends cannot be replaced');
    r = await call('POST', '/api/pages', { title: 'Nope', replaces: '00000000-0000-4000-8000-000000000000' });
    assert.equal(r.status, 404, 'an unknown page cannot be replaced');
    r = await call('POST', '/api/pages', {
      title: 'Nope', legends: Array.from({ length: 13 }, (_, i) => ({ color: '#000000', label: `L${i}` })),
    });
    assert.equal(r.status, 400, '13 legends rejected');
    r = await call('GET', '/api/pages');
    assert.equal(r.json.length, before, 'refused creations wrote nothing');
  }
```

- [ ] **Step 2: Run the suite to see it fail**

Run: `cd backend && npx tsx scripts/smoke.ts`
Expected: FAIL at `legends created in order` (the current route ignores `legends`).

- [ ] **Step 3: Replace the schema and the create handler**

In `backend/src/routes/pages.ts` replace everything from `const createPageSchema` to the end of the `router.post('/', ...)` handler with:

```ts
const legendInputSchema = z.object({
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  label: z.string().min(1).max(30),
});

const createPageSchema = z.object({
  title: z.string().min(1).max(35).default('New Tracker'),
  // Omitted by the 1.4.0 first-tracker flow when `replaces` is set: the new
  // page then takes the replaced page's position.
  position: z.number().int().min(0).optional(),
  // Optional: only sent by legacy clients (≤ 1.1.0). The field is kept on the
  // table but new clients ignore it.
  year: z.number().int().min(2000).max(2100).optional(),
  // 1.4.0 first-tracker flow: legends created with the page, in one
  // transaction, positions = array index.
  legends: z.array(legendInputSchema).max(12).default([]),
  // 1.4.0: an empty page of the caller (no legend, no cell) deleted in the
  // same transaction — a dormant account's "My Tracker" is reused, not doubled.
  replaces: z.string().uuid().optional(),
});
type CreatePageBody = z.infer<typeof createPageSchema>;

// Create page (+ its legends, − an empty page it replaces)
router.post('/', validate(createPageSchema), async (req, res) => {
  try {
    const userId = req.userId!;
    const { title, position, year, legends: legendInputs, replaces } = req.body as CreatePageBody;

    const result = await db.transaction(async (tx) => {
      let replaced: string | null = null;
      let resolvedPosition = position ?? 0;
      if (replaces) {
        const [old] = await tx.select({ id: pages.id, position: pages.position })
          .from(pages)
          .where(and(eq(pages.id, replaces), eq(pages.userId, userId)))
          .limit(1);
        if (!old) return { status: 404 as const, error: 'Page not found' };
        const [legendRow] = await tx.select({ id: legends.id })
          .from(legends).where(eq(legends.pageId, replaces)).limit(1);
        const [cellRow] = await tx.select({ pageId: cells.pageId })
          .from(cells).where(eq(cells.pageId, replaces)).limit(1);
        if (legendRow || cellRow) return { status: 409 as const, error: 'Page is not empty' };
        await tx.delete(pages).where(eq(pages.id, replaces));
        replaced = old.id;
        if (position === undefined) resolvedPosition = old.position;
      }
      const [page] = await tx.insert(pages)
        .values({ userId, title, position: resolvedPosition, ...(year !== undefined ? { year } : {}) })
        .returning();
      const created = legendInputs.length === 0
        ? []
        : await tx.insert(legends)
            .values(legendInputs.map((l, i) => ({ pageId: page.id, color: l.color, label: l.label, position: i })))
            .returning();
      return { status: 201 as const, page, legends: created, replaced };
    });

    if (result.status !== 201) {
      res.status(result.status).json({ error: result.error });
      return;
    }
    const body = {
      ...result.page,
      palette: result.page.palette ? JSON.parse(result.page.palette) : null,
      legends: result.legends,
      replaced: result.replaced,
    };
    // Other devices of the account: drop the replaced page, then add the new
    // one with its legends (clients ≤ 1.3.0 ignore the extra keys).
    if (result.replaced) broadcast(userId, 'page:deleted', { id: result.replaced });
    broadcast(userId, 'page:created', body);
    res.status(201).json(body);
  } catch (err) {
    console.error('Create page error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});
```

- [ ] **Step 4: Typecheck and run the suite**

Run: `cd backend && npx tsc --noEmit && npx tsx scripts/smoke.ts`
Expected: `smoke: OK`. If `tsc` complains about the union returned by `db.transaction`, give the callback an explicit return type:
`type CreateResult = { status: 404 | 409; error: string } | { status: 201; page: typeof pages.$inferSelect; legends: (typeof legends.$inferSelect)[]; replaced: string | null };` and write `db.transaction(async (tx): Promise<CreateResult> => { ... })`.

- [ ] **Step 5: Commit**

```bash
git branch --show-current   # master
git add backend/src/routes/pages.ts backend/scripts/smoke.ts
git commit -m "Backend: POST /api/pages creates legends in the same transaction and can replace an empty page"
```

---

### Task 4: `prod-activation.sql` and backend changelog

**Files:**
- Create: `backend/scripts/prod-activation.sql`
- Modify: `backend/CHANGELOG.md` (`## [Unreleased]`)

**Interfaces:**
- Produces: a read-only psql script printing one row per weekly signup cohort (`semaine, comptes, j1_pct, j7_pct, jamais_pct`) plus a total row.

- [ ] **Step 1: Write the script**

Create `backend/scripts/prod-activation.sql`:

```sql
-- Activation by weekly signup cohort. Read-only. Run against prod from your laptop:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-activation.sql
--
-- Same exclusions as prod-stats.sql: smoke/e2e accounts (@example.com),
-- seed-test accounts (@overridedev.com), the demo account, VIP accounts.
--
-- Columns: comptes = signups that week; j1_pct / j7_pct = share with a first
-- cell within 24 h / 7 days of signup; jamais_pct = share with no cell to date.
-- j7 only means something for cohorts older than 7 days.
--
-- Caveat: cells.created_at exists since backend 1.2.0 and was backfilled
-- from updated_at (last edit). For cells written before that, "first cell"
-- is really "last edit of the oldest surviving cell", so j1 / j7 are
-- UNDER-estimated for older cohorts. Cohorts after the backfill are exact.

\pset format aligned

\echo === Activation par cohorte hebdomadaire d'inscription (16 dernières semaines) ===
WITH real AS (
  SELECT id, created_at
  FROM users
  WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app')
    AND created_at >= date_trunc('week', now()) - interval '15 weeks'),
first_cell AS (
  SELECT p.user_id, min(c.created_at) AS at
  FROM cells c JOIN pages p ON p.id = c.page_id
  GROUP BY p.user_id),
cohort AS (
  SELECT date_trunc('week', r.created_at)::date                          AS semaine,
         r.id,
         f.at IS NOT NULL                                               AS ever,
         f.at IS NOT NULL AND f.at < r.created_at + interval '1 day'    AS j1,
         f.at IS NOT NULL AND f.at < r.created_at + interval '7 days'   AS j7
  FROM real r LEFT JOIN first_cell f ON f.user_id = r.id)
SELECT coalesce(semaine::text, 'total')                                  AS semaine,
       count(*)                                                           AS comptes,
       round(100.0 * count(*) FILTER (WHERE j1) / count(*))               AS j1_pct,
       round(100.0 * count(*) FILTER (WHERE j7) / count(*))               AS j7_pct,
       round(100.0 * count(*) FILTER (WHERE NOT ever) / count(*))         AS jamais_pct
FROM cohort
GROUP BY ROLLUP (semaine)
ORDER BY semaine NULLS LAST;
```

- [ ] **Step 2: Run it against the local database**

Run: `cd backend && psql "$(sed -n 's/^DATABASE_URL=//p' .env)" -v ON_ERROR_STOP=1 -f scripts/prod-activation.sql`
Expected: a table with at least the `total` row and no error (the smoke accounts are excluded, so counts may be 0; the demo seed is excluded too).

- [ ] **Step 3: Changelog**

In `backend/CHANGELOG.md` under `## [Unreleased]` add:

```markdown
### Added
- `POST /api/pages` accepts `legends: [{color, label}]` (≤ 12, created in the same transaction, positions in array order) and `replaces: <pageId>` (an empty page of the account — no legend, no cell — deleted in that transaction, the new page taking its position; 404 if it is not the caller's, 409 if it is not empty, nothing written in both cases). The response and the `page:created` WebSocket event carry `legends` and `replaced`; `page:deleted` is sent for the replaced page.
- `GET /api/bootstrap` returns `activated`: the account has at least one cell, on any page, any year.
- `cells.created_at` (migration 0013, backfilled from `updated_at`), returned as `createdAt` by the cell routes.
- `scripts/prod-activation.sql`: activation by weekly signup cohort (first cell within 24 h / 7 days, never).

### Changed
- No "My Tracker" page is created at signup (email or OAuth) any more: the app's first-tracker flow (1.4.0) creates the first page with its legends.

### Compatibility
- Apps ≤ 1.3.0 keep working (a new account shows an empty list with the + button). App 1.4.0 requires this version.
```

- [ ] **Step 4: Commit**

```bash
git branch --show-current   # master
git add backend/scripts/prod-activation.sql backend/CHANGELOG.md
git commit -m "Backend: prod-activation.sql (weekly signup cohorts, J+1 / J+7 / never) and 1.2.0 changelog"
```

---

### Task 5: Templates, strings, `formatLongDate`

**Files:**
- Create: `flutter_app/lib/data/first_tracker_templates.dart`
- Modify: `flutter_app/lib/providers/language_provider.dart` (`t()` area for two static helpers; the four locale maps)
- Test: `flutter_app/test/first_tracker_templates_test.dart`

**Interfaces:**
- Produces: `class FirstTrackerTemplate { String id; List<String> colors; bool customTitle; String get titleKey; int get legendCount; String labelKey(int i); List<({String color, String label})> legends(LanguageProvider lang); }`, `const firstTrackerTemplates` (6 entries, ids `mood sleep exercise reading habits other`), `LanguageProvider.translationFor(Language, String) → String?` (test-only raw lookup), `LanguageProvider.formatLongDate(Language, DateTime) → String`, `LanguageProvider.longDate(DateTime) → String`, keys `firstTracker.*`, `tracker.today`, `date.weekday.1..7`, `date.month.1..12` in every locale.

- [ ] **Step 1: Write the failing tests**

Create `flutter_app/test/first_tracker_templates_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/first_tracker_templates.dart';
import 'package:dian_dian/providers/language_provider.dart';

void main() {
  final hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  test('six templates, each with 3 to 12 distinct valid colors', () {
    expect(firstTrackerTemplates.map((t) => t.id), ['mood', 'sleep', 'exercise', 'reading', 'habits', 'other']);
    for (final t in firstTrackerTemplates) {
      expect(t.legendCount, inInclusiveRange(3, 12), reason: t.id);
      for (final c in t.colors) {
        expect(hex.hasMatch(c), isTrue, reason: '${t.id} $c');
      }
      expect(t.colors.toSet().length, t.colors.length, reason: '${t.id}: duplicate color');
    }
    expect(firstTrackerTemplates.where((t) => t.customTitle).single.id, 'other');
  });

  test('every title and label exists in every language and fits the server limits', () {
    for (final lang in Language.values) {
      for (final t in firstTrackerTemplates) {
        final title = LanguageProvider.translationFor(lang, t.titleKey);
        expect(title, isNotNull, reason: '$lang ${t.titleKey}');
        expect(title!.length, inInclusiveRange(1, 35), reason: '$lang ${t.titleKey}');
        for (var i = 0; i < t.legendCount; i++) {
          final label = LanguageProvider.translationFor(lang, t.labelKey(i));
          expect(label, isNotNull, reason: '$lang ${t.labelKey(i)}');
          expect(label!.length, inInclusiveRange(1, 30), reason: '$lang ${t.labelKey(i)}');
        }
        expect(LanguageProvider.translationFor(lang, t.labelKey(t.legendCount)), isNull,
            reason: '${t.id}: a label beyond legendCount would never be shown');
      }
    }
  });

  test('flow, Today and date strings exist in every language', () {
    const keys = [
      'firstTracker.title', 'firstTracker.subtitle', 'firstTracker.later', 'firstTracker.titleField',
      'firstTracker.continue', 'firstTracker.today', 'firstTracker.notToday', 'firstTracker.open',
      'firstTracker.error', 'firstTracker.retry', 'tracker.today',
    ];
    for (final lang in Language.values) {
      for (final k in keys) {
        expect(LanguageProvider.translationFor(lang, k), isNotNull, reason: '$lang $k');
      }
      for (var i = 1; i <= 7; i++) {
        expect(LanguageProvider.translationFor(lang, 'date.weekday.$i'), isNotNull, reason: '$lang weekday $i');
      }
      for (var i = 1; i <= 12; i++) {
        expect(LanguageProvider.translationFor(lang, 'date.month.$i'), isNotNull, reason: '$lang month $i');
      }
    }
  });

  test('French strings say vous, never tu', () {
    final tu = RegExp(r"\b(tu|ton|ta|tes|toi)\b", caseSensitive: false);
    for (final k in ['firstTracker.title', 'firstTracker.subtitle', 'firstTracker.error']) {
      expect(tu.hasMatch(LanguageProvider.translationFor(Language.fr, k)!), isFalse, reason: k);
    }
  });

  test('formatLongDate spells the date per language', () {
    final d = DateTime(2026, 10, 15); // a Thursday
    expect(LanguageProvider.formatLongDate(Language.fr, d), 'jeudi 15 octobre');
    expect(LanguageProvider.formatLongDate(Language.en, d), 'Thursday, October 15');
    expect(LanguageProvider.formatLongDate(Language.zhCN, d), '10月15日 星期四');
    expect(LanguageProvider.formatLongDate(Language.zhTW, d), '10月15日 星期四');
  });

  test('legends() resolves labels in order with the template colors', () {
    final mood = firstTrackerTemplates.first;
    final labels = [for (var i = 0; i < mood.legendCount; i++) LanguageProvider.translationFor(Language.en, mood.labelKey(i))];
    expect(labels, ['Great', 'Good', 'Okay', 'Meh', 'Low']);
  });
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd flutter_app && flutter test test/first_tracker_templates_test.dart`
Expected: FAIL to compile (`first_tracker_templates.dart` and `translationFor` do not exist).

- [ ] **Step 3: Create the templates file**

Create `flutter_app/lib/data/first_tracker_templates.dart`:

```dart
import '../providers/language_provider.dart';

/// Ready-made trackers offered by the first-tracker flow (app 1.4.0).
///
/// Colors come from the Pinterest pin palettes (`marketing/common.py`) so the
/// app looks like what we show there. Labels are translation keys resolved
/// through [LanguageProvider.t]; the server stores the resolved strings.
class FirstTrackerTemplate {
  final String id;
  final List<String> colors;

  /// "Other…": the user types the title; legends are Yes / A little / No.
  final bool customTitle;

  const FirstTrackerTemplate({
    required this.id,
    required this.colors,
    this.customTitle = false,
  });

  /// Tracker title, also the tile label (≤ 35 characters in every language).
  String get titleKey => 'firstTracker.tpl.$id.title';

  int get legendCount => colors.length;

  /// Legend label at [index] (≤ 30 characters in every language).
  String labelKey(int index) => 'firstTracker.tpl.$id.$index';

  /// The legends to send to the server, resolved in the current language.
  List<({String color, String label})> legends(LanguageProvider lang) => [
        for (var i = 0; i < colors.length; i++)
          (color: colors[i], label: lang.t(labelKey(i))),
      ];
}

const firstTrackerTemplates = <FirstTrackerTemplate>[
  FirstTrackerTemplate(id: 'mood', colors: ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7']),
  FirstTrackerTemplate(id: 'sleep', colors: ['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF']),
  FirstTrackerTemplate(id: 'exercise', colors: ['#51CF66', '#8CE99A', '#FFD8A8', '#74C0FC', '#FFA8A8']),
  FirstTrackerTemplate(id: 'reading', colors: ['#FA5252', '#FF8787', '#FFA8A8', '#FFC9C9']),
  FirstTrackerTemplate(id: 'habits', colors: ['#20C997', '#63E6BE', '#C3FAE8', '#FFD8A8', '#FFA94D']),
  FirstTrackerTemplate(id: 'other', colors: ['#8CE99A', '#FFEC99', '#FFA8A8'], customTitle: true),
];
```

- [ ] **Step 4: Add the two static helpers to `LanguageProvider`**

In `flutter_app/lib/providers/language_provider.dart`, right after the `t()` method, add:

```dart
  /// Raw lookup without fallback (tests check every locale has a key).
  @visibleForTesting
  static String? translationFor(Language lang, String key) => _translations[lang]?[key];

  /// The date in words: fr "jeudi 15 octobre", en "Thursday, October 15",
  /// zh "10月15日 星期四". No `intl` dependency: names live in the maps.
  static String formatLongDate(Language lang, DateTime d) {
    final weekday = _translations[lang]!['date.weekday.${d.weekday}']!;
    final month = _translations[lang]!['date.month.${d.month}']!;
    switch (lang) {
      case Language.fr:
        return '$weekday ${d.day} $month';
      case Language.en:
        return '$weekday, $month ${d.day}';
      case Language.zhCN:
      case Language.zhTW:
        return '$month${d.day}日 $weekday';
    }
  }

  String longDate(DateTime d) => formatLongDate(_lang, d);
```

- [ ] **Step 5: Add the strings to the four maps**

Each block goes at the end of its locale map in `_translations`, just before that map's closing `},` (the maps are `Language.fr`, `Language.en`, `Language.zhCN`, `Language.zhTW`, in that order).

`Language.fr`:

```dart
      // First tracker (1.4.0)
      'firstTracker.title': 'Que voulez-vous suivre ?',
      'firstTracker.subtitle': 'Votre premier tracker. Tout reste modifiable après.',
      'firstTracker.later': 'Plus tard',
      'firstTracker.titleField': 'Titre',
      'firstTracker.continue': 'Continuer',
      'firstTracker.today': "Et aujourd'hui ?",
      'firstTracker.notToday': "Pas aujourd'hui",
      'firstTracker.open': 'Ouvrir mon tracker',
      'firstTracker.error': 'Connexion impossible, réessayez',
      'firstTracker.retry': 'Réessayer',
      'firstTracker.tpl.mood.title': 'Humeur',
      'firstTracker.tpl.mood.0': 'Génial',
      'firstTracker.tpl.mood.1': 'Super',
      'firstTracker.tpl.mood.2': 'Bien',
      'firstTracker.tpl.mood.3': 'Bof',
      'firstTracker.tpl.mood.4': 'Mou',
      'firstTracker.tpl.sleep.title': 'Sommeil',
      'firstTracker.tpl.sleep.0': '8 h+',
      'firstTracker.tpl.sleep.1': '7–8 h',
      'firstTracker.tpl.sleep.2': '6–7 h',
      'firstTracker.tpl.sleep.3': '5–6 h',
      'firstTracker.tpl.sleep.4': '< 5 h',
      'firstTracker.tpl.exercise.title': 'Sport',
      'firstTracker.tpl.exercise.0': 'Fait',
      'firstTracker.tpl.exercise.1': 'Presque',
      'firstTracker.tpl.exercise.2': 'Un peu',
      'firstTracker.tpl.exercise.3': 'Repos',
      'firstTracker.tpl.exercise.4': 'Malade',
      'firstTracker.tpl.reading.title': 'Lecture',
      'firstTracker.tpl.reading.0': '1 h+',
      'firstTracker.tpl.reading.1': '30 min',
      'firstTracker.tpl.reading.2': 'Quelques pages',
      'firstTracker.tpl.reading.3': 'Rien',
      'firstTracker.tpl.habits.title': 'Habitudes',
      'firstTracker.tpl.habits.0': 'Fait',
      'firstTracker.tpl.habits.1': 'Presque',
      'firstTracker.tpl.habits.2': 'Un peu',
      'firstTracker.tpl.habits.3': 'Repos',
      'firstTracker.tpl.habits.4': 'Raté',
      'firstTracker.tpl.other.title': 'Autre…',
      'firstTracker.tpl.other.0': 'Oui',
      'firstTracker.tpl.other.1': 'Un peu',
      'firstTracker.tpl.other.2': 'Non',
      'tracker.today': "Aujourd'hui",
      'date.weekday.1': 'lundi',
      'date.weekday.2': 'mardi',
      'date.weekday.3': 'mercredi',
      'date.weekday.4': 'jeudi',
      'date.weekday.5': 'vendredi',
      'date.weekday.6': 'samedi',
      'date.weekday.7': 'dimanche',
      'date.month.1': 'janvier',
      'date.month.2': 'février',
      'date.month.3': 'mars',
      'date.month.4': 'avril',
      'date.month.5': 'mai',
      'date.month.6': 'juin',
      'date.month.7': 'juillet',
      'date.month.8': 'août',
      'date.month.9': 'septembre',
      'date.month.10': 'octobre',
      'date.month.11': 'novembre',
      'date.month.12': 'décembre',
```

`Language.en`:

```dart
      // First tracker (1.4.0)
      'firstTracker.title': 'What do you want to track?',
      'firstTracker.subtitle': 'Your first tracker. You can change everything later.',
      'firstTracker.later': 'Later',
      'firstTracker.titleField': 'Title',
      'firstTracker.continue': 'Continue',
      'firstTracker.today': 'And today?',
      'firstTracker.notToday': 'Not today',
      'firstTracker.open': 'Open my tracker',
      'firstTracker.error': "Can't reach the server, try again",
      'firstTracker.retry': 'Retry',
      'firstTracker.tpl.mood.title': 'Mood',
      'firstTracker.tpl.mood.0': 'Great',
      'firstTracker.tpl.mood.1': 'Good',
      'firstTracker.tpl.mood.2': 'Okay',
      'firstTracker.tpl.mood.3': 'Meh',
      'firstTracker.tpl.mood.4': 'Low',
      'firstTracker.tpl.sleep.title': 'Sleep',
      'firstTracker.tpl.sleep.0': '8 h+',
      'firstTracker.tpl.sleep.1': '7–8 h',
      'firstTracker.tpl.sleep.2': '6–7 h',
      'firstTracker.tpl.sleep.3': '5–6 h',
      'firstTracker.tpl.sleep.4': '< 5 h',
      'firstTracker.tpl.exercise.title': 'Exercise',
      'firstTracker.tpl.exercise.0': 'Done',
      'firstTracker.tpl.exercise.1': 'Almost',
      'firstTracker.tpl.exercise.2': 'A little',
      'firstTracker.tpl.exercise.3': 'Rest',
      'firstTracker.tpl.exercise.4': 'Sick',
      'firstTracker.tpl.reading.title': 'Reading',
      'firstTracker.tpl.reading.0': '1 h+',
      'firstTracker.tpl.reading.1': '30 min',
      'firstTracker.tpl.reading.2': 'A few pages',
      'firstTracker.tpl.reading.3': 'None',
      'firstTracker.tpl.habits.title': 'Habits',
      'firstTracker.tpl.habits.0': 'Done',
      'firstTracker.tpl.habits.1': 'Almost',
      'firstTracker.tpl.habits.2': 'A little',
      'firstTracker.tpl.habits.3': 'Rest',
      'firstTracker.tpl.habits.4': 'Missed',
      'firstTracker.tpl.other.title': 'Other…',
      'firstTracker.tpl.other.0': 'Yes',
      'firstTracker.tpl.other.1': 'A little',
      'firstTracker.tpl.other.2': 'No',
      'tracker.today': 'Today',
      'date.weekday.1': 'Monday',
      'date.weekday.2': 'Tuesday',
      'date.weekday.3': 'Wednesday',
      'date.weekday.4': 'Thursday',
      'date.weekday.5': 'Friday',
      'date.weekday.6': 'Saturday',
      'date.weekday.7': 'Sunday',
      'date.month.1': 'January',
      'date.month.2': 'February',
      'date.month.3': 'March',
      'date.month.4': 'April',
      'date.month.5': 'May',
      'date.month.6': 'June',
      'date.month.7': 'July',
      'date.month.8': 'August',
      'date.month.9': 'September',
      'date.month.10': 'October',
      'date.month.11': 'November',
      'date.month.12': 'December',
```

`Language.zhCN`:

```dart
      // First tracker (1.4.0)
      'firstTracker.title': '你想追踪什么？',
      'firstTracker.subtitle': '你的第一个追踪器，之后都可以修改。',
      'firstTracker.later': '稍后',
      'firstTracker.titleField': '标题',
      'firstTracker.continue': '继续',
      'firstTracker.today': '那今天呢？',
      'firstTracker.notToday': '今天不填',
      'firstTracker.open': '打开我的追踪器',
      'firstTracker.error': '无法连接，请重试',
      'firstTracker.retry': '重试',
      'firstTracker.tpl.mood.title': '心情',
      'firstTracker.tpl.mood.0': '超棒',
      'firstTracker.tpl.mood.1': '很好',
      'firstTracker.tpl.mood.2': '还行',
      'firstTracker.tpl.mood.3': '一般',
      'firstTracker.tpl.mood.4': '低落',
      'firstTracker.tpl.sleep.title': '睡眠',
      'firstTracker.tpl.sleep.0': '8 小时+',
      'firstTracker.tpl.sleep.1': '7–8 小时',
      'firstTracker.tpl.sleep.2': '6–7 小时',
      'firstTracker.tpl.sleep.3': '5–6 小时',
      'firstTracker.tpl.sleep.4': '< 5 小时',
      'firstTracker.tpl.exercise.title': '运动',
      'firstTracker.tpl.exercise.0': '完成',
      'firstTracker.tpl.exercise.1': '差一点',
      'firstTracker.tpl.exercise.2': '一点点',
      'firstTracker.tpl.exercise.3': '休息',
      'firstTracker.tpl.exercise.4': '生病',
      'firstTracker.tpl.reading.title': '阅读',
      'firstTracker.tpl.reading.0': '1 小时+',
      'firstTracker.tpl.reading.1': '30 分钟',
      'firstTracker.tpl.reading.2': '几页',
      'firstTracker.tpl.reading.3': '没读',
      'firstTracker.tpl.habits.title': '习惯',
      'firstTracker.tpl.habits.0': '完成',
      'firstTracker.tpl.habits.1': '差一点',
      'firstTracker.tpl.habits.2': '一点点',
      'firstTracker.tpl.habits.3': '休息',
      'firstTracker.tpl.habits.4': '错过',
      'firstTracker.tpl.other.title': '其他…',
      'firstTracker.tpl.other.0': '是',
      'firstTracker.tpl.other.1': '一点',
      'firstTracker.tpl.other.2': '否',
      'tracker.today': '今天',
      'date.weekday.1': '星期一',
      'date.weekday.2': '星期二',
      'date.weekday.3': '星期三',
      'date.weekday.4': '星期四',
      'date.weekday.5': '星期五',
      'date.weekday.6': '星期六',
      'date.weekday.7': '星期日',
      'date.month.1': '1月',
      'date.month.2': '2月',
      'date.month.3': '3月',
      'date.month.4': '4月',
      'date.month.5': '5月',
      'date.month.6': '6月',
      'date.month.7': '7月',
      'date.month.8': '8月',
      'date.month.9': '9月',
      'date.month.10': '10月',
      'date.month.11': '11月',
      'date.month.12': '12月',
```

`Language.zhTW`:

```dart
      // First tracker (1.4.0)
      'firstTracker.title': '你想追蹤什麼？',
      'firstTracker.subtitle': '你的第一個追蹤器，之後都可以修改。',
      'firstTracker.later': '稍後',
      'firstTracker.titleField': '標題',
      'firstTracker.continue': '繼續',
      'firstTracker.today': '那今天呢？',
      'firstTracker.notToday': '今天不填',
      'firstTracker.open': '打開我的追蹤器',
      'firstTracker.error': '無法連接，請重試',
      'firstTracker.retry': '重試',
      'firstTracker.tpl.mood.title': '心情',
      'firstTracker.tpl.mood.0': '超棒',
      'firstTracker.tpl.mood.1': '很好',
      'firstTracker.tpl.mood.2': '還行',
      'firstTracker.tpl.mood.3': '一般',
      'firstTracker.tpl.mood.4': '低落',
      'firstTracker.tpl.sleep.title': '睡眠',
      'firstTracker.tpl.sleep.0': '8 小時+',
      'firstTracker.tpl.sleep.1': '7–8 小時',
      'firstTracker.tpl.sleep.2': '6–7 小時',
      'firstTracker.tpl.sleep.3': '5–6 小時',
      'firstTracker.tpl.sleep.4': '< 5 小時',
      'firstTracker.tpl.exercise.title': '運動',
      'firstTracker.tpl.exercise.0': '完成',
      'firstTracker.tpl.exercise.1': '差一點',
      'firstTracker.tpl.exercise.2': '一點點',
      'firstTracker.tpl.exercise.3': '休息',
      'firstTracker.tpl.exercise.4': '生病',
      'firstTracker.tpl.reading.title': '閱讀',
      'firstTracker.tpl.reading.0': '1 小時+',
      'firstTracker.tpl.reading.1': '30 分鐘',
      'firstTracker.tpl.reading.2': '幾頁',
      'firstTracker.tpl.reading.3': '沒讀',
      'firstTracker.tpl.habits.title': '習慣',
      'firstTracker.tpl.habits.0': '完成',
      'firstTracker.tpl.habits.1': '差一點',
      'firstTracker.tpl.habits.2': '一點點',
      'firstTracker.tpl.habits.3': '休息',
      'firstTracker.tpl.habits.4': '錯過',
      'firstTracker.tpl.other.title': '其他…',
      'firstTracker.tpl.other.0': '是',
      'firstTracker.tpl.other.1': '一點',
      'firstTracker.tpl.other.2': '否',
      'tracker.today': '今天',
      'date.weekday.1': '星期一',
      'date.weekday.2': '星期二',
      'date.weekday.3': '星期三',
      'date.weekday.4': '星期四',
      'date.weekday.5': '星期五',
      'date.weekday.6': '星期六',
      'date.weekday.7': '星期日',
      'date.month.1': '1月',
      'date.month.2': '2月',
      'date.month.3': '3月',
      'date.month.4': '4月',
      'date.month.5': '5月',
      'date.month.6': '6月',
      'date.month.7': '7月',
      'date.month.8': '8月',
      'date.month.9': '9月',
      'date.month.10': '10月',
      'date.month.11': '11月',
      'date.month.12': '12月',
```

- [ ] **Step 6: Run the tests and analyze**

Run: `cd flutter_app && flutter analyze && flutter test test/first_tracker_templates_test.dart`
Expected: no analyzer issue, all tests PASS.

- [ ] **Step 7: Commit**

```bash
git branch --show-current   # master
git add flutter_app/lib/data/first_tracker_templates.dart flutter_app/lib/providers/language_provider.dart flutter_app/test/first_tracker_templates_test.dart
git commit -m "App: first-tracker templates, strings in four languages, dates in words"
```

---

### Task 6: `PagesProvider.createFirstTracker`, `LegendsProvider.setLegends`, WS events

**Files:**
- Modify: `flutter_app/lib/providers/pages_provider.dart` (imports, after `createPage`)
- Modify: `flutter_app/lib/providers/legends_provider.dart` (after `applyBootstrap`; `_onWsMessage`)
- Modify: `flutter_app/test/helpers.dart` (add `legendJson`)
- Test: `flutter_app/test/pages_provider_test.dart`, `flutter_app/test/legends_provider_test.dart`

**Interfaces:**
- Consumes: `POST /api/pages` from Task 3 (`legends`, `replaces`, response `legends` + `replaced`).
- Produces:
  - `typedef LegendDraft = ({String color, String label});`
  - `class CreatedPage { PageModel page; List<LegendModel> legends; }`
  - `Future<CreatedPage?> PagesProvider.createFirstTracker({required String title, required List<LegendDraft> legends, String? replaces})` — one request; on 404/409 for `replaces`, one retry without it; `null` on any other failure (nothing created locally).
  - `void LegendsProvider.setLegends(String pageId, List<LegendModel> list)`.
  - `LegendsProvider` handles WS `page:created` (with `legends`) and `page:deleted`.

- [ ] **Step 1: Add a legend JSON helper**

In `flutter_app/test/helpers.dart` append:

```dart
Map<String, dynamic> legendJson(String id, String pageId, String color, int position, {String? label}) => {
      'id': id,
      'pageId': pageId,
      'color': color,
      'label': label ?? id,
      'position': position,
      'createdAt': '',
    };
```

- [ ] **Step 2: Write the failing pages tests**

In `flutter_app/test/pages_provider_test.dart` add `import 'dart:convert';` at the top and these tests inside `main()`:

```dart
  PagesProvider withClient(MockClient client, List<Map<String, dynamic>> pages) =>
      PagesProvider(api: ApiService.custom(client: client, tokens: FakeTokens()))..applyBootstrap(pages);

  test('createFirstTracker sends title, legends and position, stores the page and returns its legends', () async {
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response(jsonEncode({
        ...pageJson('n', position: 2, title: 'Humeur'),
        'legends': [legendJson('l1', 'n', '#FFEC99', 0), legendJson('l2', 'n', '#FFD43B', 1)],
        'replaced': null,
      }), 201);
    });
    final p = withClient(client, [pageJson('a'), pageJson('b', position: 1)]);
    final created = await p.createFirstTracker(
      title: 'Humeur',
      legends: const [(color: '#FFEC99', label: 'Génial'), (color: '#FFD43B', label: 'Super')],
    );
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/pages');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['title'], 'Humeur');
    expect(body['position'], 2);
    expect(body.containsKey('replaces'), isFalse);
    expect(body['legends'], [
      {'color': '#FFEC99', 'label': 'Génial'},
      {'color': '#FFD43B', 'label': 'Super'},
    ]);
    expect(created!.page.id, 'n');
    expect(created.legends.map((l) => l.id), ['l1', 'l2']);
    expect(p.pages.map((x) => x.id), ['a', 'b', 'n']);
  });

  test('createFirstTracker with replaces omits position, drops the replaced page and keeps its slot', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({
        ...pageJson('n', position: 0, title: 'Humeur'), 'legends': <dynamic>[], 'replaced': 'a',
      }), 201);
    });
    final p = withClient(client, [pageJson('a'), pageJson('b', position: 1)]);
    final created = await p.createFirstTracker(title: 'Humeur', legends: const [], replaces: 'a');
    expect(sent['replaces'], 'a');
    expect(sent.containsKey('position'), isFalse);
    expect(created, isNotNull);
    expect(p.pages.map((x) => x.id), ['n', 'b']);
  });

  test('createFirstTracker retries once without replaces when the server says 404 or 409', () async {
    final bodies = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      bodies.add(body);
      if (body.containsKey('replaces')) return http.Response('{"error":"Page is not empty"}', 409);
      return http.Response(jsonEncode({...pageJson('n', position: 1), 'legends': <dynamic>[], 'replaced': null}), 201);
    });
    final p = withClient(client, [pageJson('a')]);
    final created = await p.createFirstTracker(title: 'X', legends: const [], replaces: 'a');
    expect(bodies.length, 2);
    expect(bodies.last.containsKey('replaces'), isFalse);
    expect(bodies.last['position'], 1);
    expect(created!.page.id, 'n');
    expect(p.pages.map((x) => x.id), ['a', 'n'], reason: 'the page that could not be replaced stays');
  });

  test('createFirstTracker returns null and changes nothing on a server error', () async {
    final client = MockClient((req) async => http.Response('{"error":"x"}', 500));
    final p = withClient(client, [pageJson('a')]);
    expect(await p.createFirstTracker(title: 'X', legends: const []), isNull);
    expect(p.pages.map((x) => x.id), ['a']);
  });
```

- [ ] **Step 3: Write the failing legends tests**

In `flutter_app/test/legends_provider_test.dart` add `import 'package:dian_dian/models/legend_model.dart';` and these tests inside `main()`:

```dart
  test('setLegends replaces a page list and bumps the epoch', () {
    final p = loaded();
    final e0 = p.mutationEpoch;
    p.setLegends('b', [LegendModel.fromJson(legend('l9', 'b', '#999999', 0))]);
    expect(p.legendsFor('b').single.id, 'l9');
    expect(p.mutationEpoch, e0 + 1);
  });

  test('page:created carrying legends fills that page (first tracker made on another device)', () {
    final p = loaded();
    p.debugHandleWs(WsMessage(event: 'page:created', data: {
      'id': 'c', 'userId': 'u1', 'title': 'Humeur', 'position': 2, 'palette': null, 'createdAt': '',
      'legends': [legend('l5', 'c', '#FFEC99', 0), legend('l6', 'c', '#FFD43B', 1)],
      'replaced': null,
    }));
    expect(p.legendsFor('c').map((l) => l.id), ['l5', 'l6']);
  });

  test('page:created without legends (backend < 1.2.0) changes nothing', () {
    final p = loaded();
    p.debugHandleWs(const WsMessage(event: 'page:created', data: {
      'id': 'c', 'userId': 'u1', 'title': 'T', 'position': 2, 'palette': null, 'createdAt': '',
    }));
    expect(p.legendsFor('c'), isEmpty);
  });

  test('page:deleted forgets the legends of that page', () {
    final p = loaded();
    p.debugHandleWs(const WsMessage(event: 'page:deleted', data: {'id': 'a'}));
    expect(p.legendsFor('a'), isEmpty);
  });
```

- [ ] **Step 4: Run both files to see them fail**

Run: `cd flutter_app && flutter test test/pages_provider_test.dart test/legends_provider_test.dart`
Expected: FAIL to compile (`createFirstTracker`, `setLegends` missing).

- [ ] **Step 5: Implement `createFirstTracker`**

In `flutter_app/lib/providers/pages_provider.dart` add `import '../models/legend_model.dart';` next to the page model import, then above `class PagesProvider`:

```dart
/// A legend to create along with a page (first-tracker flow).
typedef LegendDraft = ({String color, String label});

/// What [PagesProvider.createFirstTracker] returns: the page and its legends
/// as the server stored them.
class CreatedPage {
  final PageModel page;
  final List<LegendModel> legends;
  const CreatedPage({required this.page, required this.legends});
}
```

and after `createPage`:

```dart
  /// Creates a page with its [legends] in one server transaction (backend
  /// ≥ 1.2.0). With [replaces], an empty page of the user is deleted in that
  /// transaction and the new page takes its slot; if the server refuses it
  /// (404 gone, 409 not empty any more) the page is created without
  /// replacing anything. Returns `null` on failure: nothing was created.
  Future<CreatedPage?> createFirstTracker({
    required String title,
    required List<LegendDraft> legends,
    String? replaces,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'legends': [for (final l in legends) {'color': l.color, 'label': l.label}],
      if (replaces != null) 'replaces': replaces else 'position': _pages.length,
    };
    try {
      var response = await _api.apiFetch('/api/pages', method: 'POST', body: body);
      if (replaces != null && (response.statusCode == 404 || response.statusCode == 409)) {
        body.remove('replaces');
        body['position'] = _pages.length;
        response = await _api.apiFetch('/api/pages', method: 'POST', body: body);
      }
      if (response.statusCode != 201 && response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final page = PageModel.fromJson(_parsePalette(json));
      final legendRows = (json['legends'] as List<dynamic>? ?? const [])
          .map((j) => LegendModel.fromJson(j as Map<String, dynamic>))
          .toList(growable: false);

      // The replaced page leaves; the new one takes its index (or the end).
      var index = _pages.length;
      final replaced = json['replaced'] as String?;
      if (replaced != null) {
        final i = _pages.indexWhere((p) => p.id == replaced);
        if (i != -1) {
          _pages.removeAt(i);
          index = i;
        }
      }
      if (!_pages.any((p) => p.id == page.id)) {
        _pages.insert(index.clamp(0, _pages.length), page);
      }
      _touch();
      notifyListeners();
      return CreatedPage(page: page, legends: legendRows);
    } catch (e) {
      debugPrint('PagesProvider: createFirstTracker failed: $e');
      return null;
    }
  }
```

- [ ] **Step 6: Implement `setLegends` and the two WS cases**

In `flutter_app/lib/providers/legends_provider.dart` after `applyBootstrap`:

```dart
  /// Replaces the legends of [pageId] with [list] — used right after a page
  /// is created together with its legends, without waiting for the WS echo.
  void setLegends(String pageId, List<LegendModel> list) {
    _set(pageId, list);
    notifyListeners();
  }
```

and in `_onWsMessage`, before the closing `}` of the `switch`:

```dart
      case 'page:created':
        // Backend ≥ 1.2.0 sends the legends created with the page.
        final json = message.data as Map<String, dynamic>;
        final rows = json['legends'] as List<dynamic>?;
        final pageId = json['id'] as String?;
        if (rows == null || pageId == null) return;
        _set(pageId, [for (final j in rows) LegendModel.fromJson(j as Map<String, dynamic>)]);
        notifyListeners();

      case 'page:deleted':
        final json = message.data as Map<String, dynamic>;
        final pageId = json['id'] as String?;
        if (pageId != null && _byPage.remove(pageId) != null) {
          _mutationEpoch++;
          notifyListeners();
        }
```

- [ ] **Step 7: Run the tests and analyze**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: no analyzer issue, every test PASS (the whole suite, not only the two files).

- [ ] **Step 8: Commit**

```bash
git branch --show-current   # master
git add flutter_app/lib/providers/pages_provider.dart flutter_app/lib/providers/legends_provider.dart flutter_app/test
git commit -m "App: createFirstTracker (page + legends in one request, replaces with fallback), legends follow page:created / page:deleted"
```

---

### Task 7: `SyncService.activated`

**Files:**
- Modify: `flutter_app/lib/services/sync_service.dart` (fields, `clear`, `_fetch`, `_hydrate`, `_serialize`)
- Test: `flutter_app/test/sync_service_test.dart`

**Interfaces:**
- Consumes: `bootstrap.activated` from Task 2.
- Produces: `bool? SyncService.activated` (from the last successful network bootstrap of this session; `null` until then or when the body lacks the field), `bool? SyncService.snapshotActivated` (from the disk snapshot at `start()`; `null` when absent). The snapshot carries `data.activated` when known.

- [ ] **Step 1: Write the failing tests**

In `flutter_app/test/sync_service_test.dart` add inside `main()`:

```dart
  test('activated comes from the network body, snapshotActivated from the disk snapshot', () async {
    final first = build(body: (y) => {...bootstrapBody(y), 'activated': false});
    expect(first.activated, isNull, reason: 'nothing fetched yet');
    await first.ensureYear(2026);
    expect(first.activated, isFalse);
    final saved = snapshots.data!;

    final sync = build(body: (y) => {...bootstrapBody(y), 'activated': true});
    snapshots.data = saved;
    await sync.start(userId: 'u1', year: 2026);
    expect(sync.snapshotActivated, isFalse, reason: 'written by the previous session');
    await sync.ensureYear(2026);
    expect(sync.activated, isTrue, reason: 'the server has the last word');
  });

  test('activated stays unknown when the body or the snapshot lacks it (backend < 1.2.0, app ≤ 1.3.0)', () async {
    final first = build();
    await first.ensureYear(2026);
    expect(first.activated, isNull);
    final saved = snapshots.data!;

    final sync = build();
    snapshots.data = saved;
    await sync.start(userId: 'u1', year: 2026);
    expect(sync.snapshotActivated, isNull);
  });

  test('clear forgets activated', () async {
    final sync = build(body: (y) => {...bootstrapBody(y), 'activated': true});
    await sync.ensureYear(2026);
    expect(sync.activated, isTrue);
    await sync.clear();
    expect(sync.activated, isNull);
    expect(sync.snapshotActivated, isNull);
  });
```

- [ ] **Step 2: Run to see them fail**

Run: `cd flutter_app && flutter test test/sync_service_test.dart`
Expected: FAIL to compile (`activated` missing).

- [ ] **Step 3: Implement**

In `flutter_app/lib/services/sync_service.dart`:

Fields, after `final Map<int, int> _lastAppliedEpoch = {};`:

```dart
  // `activated` = the account has at least one cell (any page, any year).
  // Network value and snapshot value are kept apart: the first-tracker flow
  // only runs on a network `false`, the snapshot `true` only lets an active
  // user land without waiting for the network.
  bool? _activated;
  bool? _snapshotActivated;
```

Getters, after `int get activeYear => _activeYear;`:

```dart
  /// From the last successful network bootstrap of this session; `null`
  /// until then, or when the server did not send it (backend < 1.2.0).
  bool? get activated => _activated;

  /// From the disk snapshot read by [start]; `null` when absent.
  bool? get snapshotActivated => _snapshotActivated;
```

In `clear()`, after `_lastAppliedEpoch.clear();`:

```dart
    _activated = null;
    _snapshotActivated = null;
```

In `_fetch`, right after `_apply(data, applyCells: true);`:

```dart
      _activated = data['activated'] as bool?;
```

In `_hydrate`, right after `_apply(data, applyCells: data['year'] == year);`:

```dart
      _snapshotActivated = data['activated'] as bool?;
```

In `_serialize`, add to the returned map (after `'year': year,`):

```dart
      if ((_activated ?? _snapshotActivated) != null) 'activated': _activated ?? _snapshotActivated,
```

- [ ] **Step 4: Run the tests and analyze**

Run: `cd flutter_app && flutter analyze && flutter test test/sync_service_test.dart`
Expected: no analyzer issue, all PASS.

- [ ] **Step 5: Commit**

```bash
git branch --show-current   # master
git add flutter_app/lib/services/sync_service.dart flutter_app/test/sync_service_test.dart
git commit -m "App: SyncService exposes activated (network) and snapshotActivated (disk)"
```

---

### Task 8: Trigger decision (pure functions)

**Files:**
- Create: `flutter_app/lib/data/first_tracker_decision.dart`
- Test: `flutter_app/test/first_tracker_decision_test.dart`

**Interfaces:**
- Produces:
  - `String? replaceablePageId(List<PageModel> pages, List<LegendModel> Function(String pageId) legendsFor)` — first page by `position` with no legend, else `null`.
  - `bool shouldShowFirstTracker({required bool? activated, required bool doneOnThisDevice, required int pageCount, required int maxTrackers, required bool hasReplaceablePage})`.

- [ ] **Step 1: Write the failing tests**

Create `flutter_app/test/first_tracker_decision_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/first_tracker_decision.dart';
import 'package:dian_dian/models/legend_model.dart';
import 'package:dian_dian/models/page_model.dart';

PageModel page(String id, int position) =>
    PageModel(id: id, userId: 'u1', title: id, year: 2026, position: position, createdAt: '');

LegendModel legend(String pageId) =>
    LegendModel(id: 'l-$pageId', pageId: pageId, color: '#000000', label: 'x', position: 0, createdAt: '');

void main() {
  group('shouldShowFirstTracker', () {
    bool show({bool? activated = false, bool done = false, int pages = 0, int max = 3, bool replaceable = false}) =>
        shouldShowFirstTracker(
          activated: activated,
          doneOnThisDevice: done,
          pageCount: pages,
          maxTrackers: max,
          hasReplaceablePage: replaceable,
        );

    test('only on a confirmed "no cell at all"', () {
      expect(show(activated: null), isFalse, reason: 'offline, or backend < 1.2.0');
      expect(show(activated: true), isFalse);
      expect(show(activated: false), isTrue);
    });

    test('never twice on the same device for the same account', () {
      expect(show(done: true), isFalse);
    });

    test('respects the free limit unless an empty page can be replaced', () {
      expect(show(pages: 3, max: 3), isFalse, reason: 'would create a locked 4th tracker');
      expect(show(pages: 3, max: 3, replaceable: true), isTrue);
      expect(show(pages: 2, max: 3), isTrue);
      expect(show(pages: 3, max: 999), isTrue, reason: 'premium');
    });
  });

  group('replaceablePageId', () {
    test('first page by position without legends', () {
      final pages = [page('b', 1), page('a', 0), page('c', 2)];
      expect(replaceablePageId(pages, (id) => id == 'a' ? [legend('a')] : const []), 'b');
    });

    test('null when every page has legends or there is no page', () {
      expect(replaceablePageId([page('a', 0)], (id) => [legend(id)]), isNull);
      expect(replaceablePageId(const [], (_) => const []), isNull);
    });
  });
}
```

- [ ] **Step 2: Run to see it fail**

Run: `cd flutter_app && flutter test test/first_tracker_decision_test.dart`
Expected: FAIL to compile.

- [ ] **Step 3: Implement**

Create `flutter_app/lib/data/first_tracker_decision.dart`:

```dart
import '../models/legend_model.dart';
import '../models/page_model.dart';

/// The empty page a dormant account's first tracker should replace: the
/// first page (by position) with no legend. Cells need not be checked: the
/// flow only runs when the server reports no cell at all for the account.
String? replaceablePageId(
  List<PageModel> pages,
  List<LegendModel> Function(String pageId) legendsFor,
) {
  final sorted = [...pages]..sort((a, b) => a.position.compareTo(b.position));
  for (final p in sorted) {
    if (legendsFor(p.id).isEmpty) return p.id;
  }
  return null;
}

/// Whether to show the first-tracker flow instead of the usual landing.
///
/// [activated] is the server's answer for this session: `null` means no
/// answer (offline, or a backend older than 1.2.0) and never shows the flow.
/// [doneOnThisDevice] is the per-device, per-account flag set when the flow
/// was finished or skipped. The free limit is respected: at the limit, the
/// flow only runs if it can replace an empty page.
bool shouldShowFirstTracker({
  required bool? activated,
  required bool doneOnThisDevice,
  required int pageCount,
  required int maxTrackers,
  required bool hasReplaceablePage,
}) {
  if (activated != false) return false;
  if (doneOnThisDevice) return false;
  return pageCount < maxTrackers || hasReplaceablePage;
}
```

- [ ] **Step 4: Run the tests and analyze**

Run: `cd flutter_app && flutter analyze && flutter test test/first_tracker_decision_test.dart`
Expected: no analyzer issue, all PASS.

- [ ] **Step 5: Commit**

```bash
git branch --show-current   # master
git add flutter_app/lib/data/first_tracker_decision.dart flutter_app/test/first_tracker_decision_test.dart
git commit -m "App: first-tracker trigger decision and replaceable page lookup (pure, tested)"
```

---

### Task 9: `FirstTrackerScreen` (two screens) + widget tests

**Files:**
- Create: `flutter_app/lib/screens/first_tracker_screen.dart`
- Test: `flutter_app/test/first_tracker_screen_test.dart` (first widget test of the repo)

**Interfaces:**
- Consumes: `firstTrackerTemplates`, `FirstTrackerTemplate.legends(lang)` (Task 5); `LanguageProvider.t`, `longDate` (Task 5); `PagesProvider.createFirstTracker`, `CreatedPage` (Task 6); `LegendsProvider.setLegends/setPageId/legendsFor`; `CellsProvider.setContext/setCell/getCell`; `replaceablePageId` (Task 8).
- Produces: `class FirstTrackerScreen extends StatefulWidget { FirstTrackerScreen({required String userId, required VoidCallback onLater, required void Function(String pageId, int year) onOpenTracker, DateTime Function() now = DateTime.now}) }`, `static Future<bool> FirstTrackerScreen.isDone(String userId)`, `static Future<void> FirstTrackerScreen.markDone(String userId)` (SharedPreferences key `first_tracker_done_<userId>`).

Behavior (from the spec): screen 1 = title, subtitle, six tiles (2 columns, 3 from 600 px wide), "Other…" unfolds a title field + Continue, "Later" top right. Screen 2 = tracker title, date in words, big dot, one button per legend, "Not today"; tapping a legend creates the page (once) then sets today's cell; success shows the colored dot with the accent ring and "Open my tracker"; failure shows the error line + Retry, which replays only the failed step.

- [ ] **Step 1: Write the failing widget tests**

Create `flutter_app/test/first_tracker_screen_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/screens/first_tracker_screen.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

/// Providers + a fake server around a [FirstTrackerScreen]. The server
/// answers POST /api/pages with the page "n" and the legends it was sent,
/// and PUT /api/cells/n with the cell it was sent.
class Harness {
  final List<http.Request> requests = [];
  int pageStatus = 201;
  int Function() cellStatus = () => 200;
  late final PagesProvider pages;
  late final LegendsProvider legends;
  late final CellsProvider cells;
  late final Widget widget;

  Harness({
    required DateTime Function() now,
    VoidCallback? onLater,
    void Function(String pageId, int year)? onOpen,
    List<Map<String, dynamic>> pageRows = const [],
    Map<String, dynamic> legendRows = const {},
  }) {
    final client = MockClient((req) async {
      requests.add(req);
      if (req.method == 'POST' && req.url.path == '/api/pages') {
        if (pageStatus != 201) return http.Response('{"error":"x"}', pageStatus);
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final sent = body['legends'] as List<dynamic>;
        return http.Response(jsonEncode({
          ...pageJson('n', title: body['title'] as String),
          'legends': [
            for (var i = 0; i < sent.length; i++)
              legendJson('l$i', 'n', sent[i]['color'] as String, i, label: sent[i]['label'] as String),
          ],
          'replaced': body['replaces'],
        }), 201);
      }
      if (req.method == 'PUT' && req.url.path == '/api/cells/n') {
        final status = cellStatus();
        if (status != 200) return http.Response('{"error":"x"}', status);
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'pageId': 'n', ...body, 'updatedAt': ''}), 200);
      }
      return http.Response('{"error":"unexpected ${req.method} ${req.url.path}"}', 404);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    pages = PagesProvider(api: api)..applyBootstrap(pageRows);
    legends = LegendsProvider(api: api)..applyBootstrap(legendRows);
    cells = CellsProvider(api: api, audio: AudioService.silent())
      ..applyBootstrap(now().year, {for (final p in pageRows) p['id'] as String: <dynamic>[]});
    widget = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: pages),
        ChangeNotifierProvider.value(value: legends),
        ChangeNotifierProvider.value(value: cells),
      ],
      child: MaterialApp(
        home: FirstTrackerScreen(
          userId: 'u1',
          now: now,
          onLater: onLater ?? () {},
          onOpenTracker: onOpen ?? (_, __) {},
        ),
      ),
    );
  }

  List<http.Request> get posts => requests.where((r) => r.method == 'POST').toList();
  List<http.Request> get puts => requests.where((r) => r.method == 'PUT').toList();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final oct15 = DateTime(2026, 10, 15, 9);

  testWidgets('Mood → Great creates the page with five legends and sets today\'s cell', (tester) async {
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.pump();
    expect(find.text('What do you want to track?'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, October 15'), findsOneWidget);
    expect(find.text('And today?'), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);
    expect(h.requests, isEmpty, reason: 'nothing is created before a choice');

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();

    final body = jsonDecode(h.posts.single.body) as Map<String, dynamic>;
    expect(body['title'], 'Mood');
    expect(body['position'], 0);
    expect(body.containsKey('replaces'), isFalse);
    expect((body['legends'] as List).map((l) => l['label']), ['Great', 'Good', 'Okay', 'Meh', 'Low']);
    expect(jsonDecode(h.puts.single.body), {'year': 2026, 'month': 10, 'day': 15, 'color': '#FFEC99'});
    expect(h.legends.legendsFor('n').length, 5);
    expect(h.cells.getCell(10, 15)!.color, '#FFEC99');
    expect(find.text('Open my tracker'), findsOneWidget);
    expect(find.text('Not today'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
  });

  testWidgets('Open my tracker hands the created page and the current year to the parent', (tester) async {
    String? opened;
    final h = Harness(now: () => oct15, onOpen: (id, year) => opened = '$id/$year');
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open my tracker'));
    await tester.pump();
    expect(opened, 'n/2026');
  });

  testWidgets('a failed cell shows the error; Retry only replays the cell', (tester) async {
    var failCell = true;
    final h = Harness(now: () => oct15)..cellStatus = () => failCell ? 500 : 200;
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(find.text("Can't reach the server, try again"), findsOneWidget);
    expect(find.text('Open my tracker'), findsNothing);
    expect(h.posts.length, 1);
    expect(h.puts.length, 1);

    failCell = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 1, reason: 'the page is never created twice');
    expect(h.puts.length, 2);
    expect(find.text("Can't reach the server, try again"), findsNothing);
    expect(find.text('Open my tracker'), findsOneWidget);
  });

  testWidgets('a failed page creation shows the error; Retry creates it then sets the cell', (tester) async {
    final h = Harness(now: () => oct15)..pageStatus = 500;
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 h+'));
    await tester.pumpAndSettle();
    expect(find.text("Can't reach the server, try again"), findsOneWidget);
    expect(h.puts, isEmpty);
    expect(h.pages.pages, isEmpty);

    h.pageStatus = 201;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 2);
    expect(h.puts.length, 1);
    expect(find.text('Open my tracker'), findsOneWidget);
  });

  testWidgets('the date is read at tap time (midnight while the screen is open)', (tester) async {
    var clock = DateTime(2026, 10, 15, 23, 59);
    final h = Harness(now: () => clock);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, October 15'), findsOneWidget);

    clock = DateTime(2026, 10, 16, 0, 1);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(jsonDecode(h.puts.single.body), {'year': 2026, 'month': 10, 'day': 16, 'color': '#FFEC99'});
    expect(find.text('Friday, October 16'), findsOneWidget);
  });

  testWidgets('Other… needs a non-blank title before continuing', (tester) async {
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Other…'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('And today?'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Water');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('A little'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect((jsonDecode(h.posts.single.body) as Map)['title'], 'Water');
  });

  testWidgets('Not today creates the tracker without a cell and opens it', (tester) async {
    String? opened;
    final h = Harness(now: () => oct15, onOpen: (id, year) => opened = '$id/$year');
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 1);
    expect(h.puts, isEmpty);
    expect(opened, 'n/2026');
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
  });

  testWidgets('a dormant account\'s empty page is replaced, not doubled', (tester) async {
    final h = Harness(
      now: () => oct15,
      pageRows: [pageJson('old', title: 'My Tracker')],
      legendRows: {'old': <dynamic>[]},
    );
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final body = jsonDecode(h.posts.single.body) as Map<String, dynamic>;
    expect(body['replaces'], 'old');
    expect(body.containsKey('position'), isFalse);
    expect(h.pages.pages.map((p) => p.id), ['n']);
  });

  testWidgets('Later leaves without a request and is remembered for this account on this device', (tester) async {
    var later = false;
    final h = Harness(now: () => oct15, onLater: () => later = true);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(later, isTrue);
    expect(h.requests, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
    expect(await FirstTrackerScreen.isDone('u1'), isTrue);
    expect(await FirstTrackerScreen.isDone('u2'), isFalse);
  });
}
```

If `pumpAndSettle` ever times out because a `MockClient` future does not resolve under the test binding, wrap the body of that test in `await tester.runAsync(() async { ... });` and replace each `pumpAndSettle()` by `await tester.pump(); await Future<void>.delayed(Duration.zero); await tester.pump();`. The repo's provider tests already await `MockClient` calls under `TestWidgetsFlutterBinding`, so this should not be needed.

- [ ] **Step 2: Run to see it fail**

Run: `cd flutter_app && flutter test test/first_tracker_screen_test.dart`
Expected: FAIL to compile (`first_tracker_screen.dart` missing).

- [ ] **Step 3: Create the screen**

Create `flutter_app/lib/screens/first_tracker_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/first_tracker_decision.dart';
import '../data/first_tracker_templates.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import '../theme/app_theme.dart';

/// First-tracker flow (1.4.0), shown instead of the page list to any account
/// the server reports with no cell at all (new or dormant).
///
/// Screen 1 picks a template (or a custom title); screen 2 creates the page
/// with its legends and sets today's cell in the account's real data. The
/// only exit that creates nothing is "Later". Finishing or skipping is
/// remembered per device and account ([isDone] / [markDone]).
class FirstTrackerScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onLater;
  final void Function(String pageId, int year) onOpenTracker;

  /// Clock, injectable in tests. Read at tap time, so a flow left open past
  /// midnight still writes the right day.
  final DateTime Function() now;

  const FirstTrackerScreen({
    super.key,
    required this.userId,
    required this.onLater,
    required this.onOpenTracker,
    this.now = DateTime.now,
  });

  static String _prefKey(String userId) => 'first_tracker_done_$userId';

  /// True once this device finished or skipped the flow for [userId].
  static Future<bool> isDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(userId)) ?? false;
  }

  static Future<void> markDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(userId), true);
  }

  @override
  State<FirstTrackerScreen> createState() => _FirstTrackerScreenState();
}

enum _Step { choose, today }

class _FirstTrackerScreenState extends State<FirstTrackerScreen> {
  _Step _step = _Step.choose;
  FirstTrackerTemplate? _template;
  bool _titleOpen = false;
  final _titleController = TextEditingController();

  /// Page + legends once the server has them; created at most once.
  CreatedPage? _created;
  String? _todayColor;
  bool _busy = false;
  bool _error = false;
  Future<bool> Function()? _retry;

  @override
  void initState() {
    super.initState();
    // Continue enables as soon as the custom title is not blank.
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  String _title(LanguageProvider lang) =>
      _template!.customTitle ? _titleController.text.trim() : lang.t(_template!.titleKey);

  void _choose(FirstTrackerTemplate t) {
    setState(() {
      _template = t;
      if (t.customTitle) {
        _titleOpen = true;
      } else {
        _step = _Step.today;
      }
    });
  }

  void _continueWithTitle() {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _step = _Step.today);
  }

  Future<void> _later() async {
    await FirstTrackerScreen.markDone(widget.userId);
    if (mounted) widget.onLater();
  }

  /// Runs one server-facing step. On failure the inline error shows and the
  /// step is kept for Retry, so only the failed step is replayed.
  Future<void> _run(Future<bool> Function() step) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = false;
      _retry = step;
    });
    final ok = await step();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = !ok;
      if (ok) _retry = null;
    });
  }

  /// Creates the page with its legends, once. Later calls return the cached
  /// result, so a retry after a failed cell never creates a second page.
  Future<CreatedPage?> _ensureCreated() async {
    final existing = _created;
    if (existing != null) return existing;
    final lang = context.read<LanguageProvider>();
    final pages = context.read<PagesProvider>();
    final legends = context.read<LegendsProvider>();
    final created = await pages.createFirstTracker(
      title: _title(lang),
      legends: _template!.legends(lang),
      replaces: replaceablePageId(pages.pages, legends.legendsFor),
    );
    if (created == null || !mounted) return created;
    // Point the store at the new page, as the page list would have.
    legends.setLegends(created.page.id, created.legends);
    legends.setPageId(created.page.id);
    context.read<CellsProvider>().setContext(pageId: created.page.id, year: widget.now().year);
    _created = created;
    return created;
  }

  Future<void> _pickColor(String color) => _run(() async {
        final created = await _ensureCreated();
        if (created == null || !mounted) return false;
        final today = widget.now();
        final cells = context.read<CellsProvider>();
        cells.setContext(pageId: created.page.id, year: today.year);
        await cells.setCell(today.month, today.day, color);
        // setCell reverts silently when the server refuses: ask the store.
        if (cells.getCell(today.month, today.day)?.color != color) return false;
        _todayColor = color;
        await FirstTrackerScreen.markDone(widget.userId);
        return true;
      });

  Future<void> _notToday() => _run(() async {
        final created = await _ensureCreated();
        if (created == null) return false;
        await FirstTrackerScreen.markDone(widget.userId);
        if (mounted) widget.onOpenTracker(created.page.id, widget.now().year);
        return true;
      });

  void _open() {
    final created = _created;
    if (created != null) widget.onOpenTracker(created.page.id, widget.now().year);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ShellButton(label: lang.t('firstTracker.later'), onTap: _later),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _step == _Step.choose ? _buildChoose(lang) : _buildToday(lang),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoose(LanguageProvider lang) {
    final columns = MediaQuery.of(context).size.width >= 600 ? 3 : 2;
    return _Card(
      children: [
        Text(
          lang.t('firstTracker.title'),
          style: AppFonts.pixel(fontSize: 18, color: AppColors.title),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          lang.t('firstTracker.subtitle'),
          style: AppFonts.dot(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (final t in firstTrackerTemplates)
              _Tile(
                label: lang.t(t.titleKey),
                colors: t.colors,
                placeholder: t.customTitle,
                plusLabel: '+ ${lang.t('firstTracker.titleField')}',
                selected: _titleOpen && identical(t, _template),
                onTap: () => _choose(t),
              ),
          ],
        ),
        if (_titleOpen) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            maxLength: 35,
            style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
            decoration: InputDecoration(
              hintText: lang.t('firstTracker.titleField'),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onSubmitted: (_) => _continueWithTitle(),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: lang.t('firstTracker.continue'),
            enabled: _titleController.text.trim().isNotEmpty,
            onTap: _continueWithTitle,
          ),
        ],
      ],
    );
  }

  Widget _buildToday(LanguageProvider lang) {
    final today = widget.now();
    final legends = _template!.legends(lang);
    return _Card(
      children: [
        Text(
          _title(lang),
          style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          lang.longDate(today),
          style: AppFonts.dot(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          lang.t('firstTracker.today'),
          style: AppFonts.pixel(fontSize: 14, color: AppColors.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(child: _BigDot(color: _todayColor, busy: _busy)),
        const SizedBox(height: 20),
        for (final l in legends)
          _LegendButton(
            color: l.color,
            label: l.label,
            selected: _todayColor == l.color,
            enabled: !_busy,
            onTap: () => _pickColor(l.color),
          ),
        if (_error) ...[
          const SizedBox(height: 4),
          Text(
            lang.t('firstTracker.error'),
            style: AppFonts.dot(fontSize: 13, color: AppColors.btnResetText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Center(
            child: _ShellButton(
              label: lang.t('firstTracker.retry'),
              onTap: () {
                final retry = _retry;
                if (retry != null) _run(retry);
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_todayColor != null)
          _PrimaryButton(label: lang.t('firstTracker.open'), enabled: !_busy, onTap: _open)
        else
          GestureDetector(
            onTap: _busy ? null : _notToday,
            child: Text(
              lang.t('firstTracker.notToday'),
              style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

Color _hex(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

/// The shell card used by both screens.
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.shell,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shellBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Small bordered button in the shell colors ("Later", "Retry").
class _ShellButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShellButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.shell,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.shellBorder),
        ),
        child: Text(label, style: AppFonts.pixel(fontSize: 12, color: AppColors.accent)),
      ),
    );
  }
}

/// Full-width accent button ("Continue", "Open my tracker").
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.btnAdd,
            border: Border.all(color: AppColors.btnAddBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText)),
        ),
      ),
    );
  }
}

/// Template tile: name + its legend dots (empty dots and "+ Title" for Other…).
class _Tile extends StatelessWidget {
  final String label;
  final List<String> colors;
  final bool placeholder;
  final String plusLabel;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.label,
    required this.colors,
    required this.placeholder,
    required this.plusLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppFonts.pixel(fontSize: 11, color: AppColors.title),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in colors)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: placeholder ? AppColors.dotEmpty : _hex(c),
                      border: placeholder ? Border.all(color: AppColors.dotBorder, width: 0.5) : null,
                    ),
                  ),
              ],
            ),
            if (placeholder) ...[
              const SizedBox(height: 6),
              Text(plusLabel, style: AppFonts.dot(fontSize: 11, color: AppColors.accent)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Today's dot: empty, or colored with the grid's "today" ring.
class _BigDot extends StatelessWidget {
  final String? color;
  final bool busy;
  const _BigDot({required this.color, required this.busy});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c != null ? _hex(c) : AppColors.dotEmpty,
              border: c == null ? Border.all(color: AppColors.dotBorder) : null,
            ),
          ),
          if (c != null)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
            ),
          if (busy)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}

/// One legend as a button: dot + label, highlighted when it is today's color.
class _LegendButton extends StatelessWidget {
  final String color;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LegendButton({
    required this.color,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _hex(color)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: AppFonts.dot(fontSize: 14, color: AppColors.text))),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests and analyze**

Run: `cd flutter_app && flutter analyze && flutter test test/first_tracker_screen_test.dart`
Expected: no analyzer issue, all 9 tests PASS. If the analyzer flags `use_build_context_synchronously`, the `if (!mounted) return` / `if (created == null || !mounted)` guards above are the fix pattern; keep them before every `context.read` that follows an `await`.

- [ ] **Step 5: Commit**

```bash
git branch --show-current   # master
git add flutter_app/lib/screens/first_tracker_screen.dart flutter_app/test/first_tracker_screen_test.dart
git commit -m "App: FirstTrackerScreen (template tiles, today's dot, retry per step) with widget tests"
```

---

### Task 10: Wire the flow in `main.dart`, remove the old onboarding

**Files:**
- Modify: `flutter_app/lib/main.dart:18` (import), `:106` (enum), `:144-192` (`_startSessionInner`), `:370-377` (`_buildAppScreen`)
- Delete: `flutter_app/lib/screens/onboarding_screen.dart`
- Modify: `flutter_app/lib/providers/language_provider.dart` (drop every `'onboarding.*'` key)

**Interfaces:**
- Consumes: `SyncService.activated`, `snapshotActivated` (Task 7); `shouldShowFirstTracker`, `replaceablePageId` (Task 8); `FirstTrackerScreen`, `isDone` (Task 9); `PremiumProvider.maxTrackers`.
- Produces: `AppScreen.firstTracker` replaces `AppScreen.onboarding`; the device flag `onboarding_done` is no longer read or written.

No unit test owns this wiring (it is `setState` plumbing on the shell); the decision itself is tested in Task 8 and the screen in Task 9. Verification is `flutter analyze`, the full test suite, and the simulator checklist in Step 5.

- [ ] **Step 1: Imports and enum**

In `flutter_app/lib/main.dart` replace `import 'screens/onboarding_screen.dart';` with:

```dart
import 'data/first_tracker_decision.dart';
import 'screens/first_tracker_screen.dart';
```

and change the enum to:

```dart
enum AppScreen { login, register, forgotPassword, firstTracker, pageList, tracker, settings }
```

Update the doc comment of `_startSession` from `on onboarding, the last open tracker, or the page list.` to `on the first-tracker flow, the last open tracker, or the page list.`

- [ ] **Step 2: Replace the landing decision in `_startSessionInner`**

Replace this block:

```dart
    if (await OnboardingScreen.shouldShow()) {
      if (!mounted) return;
      setState(() {
        _screen = AppScreen.onboarding;
        _selectedYear = year;
        _restoreInProgress = false;
      });
      return;
    }

    // First launch on this device: nothing on disk, wait once for the network.
    if (!hydrated) await sync.ensureYear(year);
    if (!mounted) return;
```

with:

```dart
    // Anyone the snapshot already knows as active lands at once (instant
    // first paint). Everyone else waits for the server once: new and dormant
    // accounts get the first-tracker flow only on a confirmed "no cell at
    // all". Offline, `activated` stays null and the normal app shows.
    if (!hydrated || sync.snapshotActivated != true) await sync.ensureYear(year);
    if (!mounted) return;

    final userId = auth.userId!;
    final doneOnThisDevice = await FirstTrackerScreen.isDone(userId);
    if (!mounted) return;
    final pagesProv = context.read<PagesProvider>();
    final legendsProv = context.read<LegendsProvider>();
    if (shouldShowFirstTracker(
      activated: sync.activated,
      doneOnThisDevice: doneOnThisDevice,
      pageCount: pagesProv.pages.length,
      maxTrackers: context.read<PremiumProvider>().maxTrackers,
      hasReplaceablePage: replaceablePageId(pagesProv.pages, legendsProv.legendsFor) != null,
    )) {
      setState(() {
        _screen = AppScreen.firstTracker;
        _selectedYear = year;
        _restoreInProgress = false;
      });
      return;
    }
```

The existing `final pagesProv = context.read<PagesProvider>();` a few lines below (before `if (lastId != null && pagesProv.pages.any(...))`) is now a duplicate declaration: delete that line, the earlier `pagesProv` is in scope.

- [ ] **Step 3: Replace the screen case**

In `_buildAppScreen` replace:

```dart
      case AppScreen.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onDone: () => _navigate(AppScreen.pageList),
        );
```

with:

```dart
      case AppScreen.firstTracker:
        return FirstTrackerScreen(
          key: const ValueKey('firstTracker'),
          userId: context.read<AuthProvider>().userId!,
          onLater: () => _navigate(AppScreen.pageList),
          onOpenTracker: (pageId, year) {
            // The created tracker becomes the last-opened one (saved by
            // _navigate) so the next launch lands on it.
            _selectedYear = year;
            _navigate(AppScreen.tracker, pageId: pageId);
          },
        );
```

- [ ] **Step 4: Delete the old screen and its strings**

```bash
cd flutter_app && git rm lib/screens/onboarding_screen.dart
sed -i '' "/^      'onboarding\./d" lib/providers/language_provider.dart
grep -rn "onboarding" lib   # expected: no output
```

- [ ] **Step 5: Analyze, full test suite, simulator**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: no analyzer issue, all PASS.

Then with the local backend (Task map) and `make run` on a simulator, check the list below. The dormant account comes from `cd backend && npx tsx scripts/seed-test-accounts.ts` or a fresh signup followed by a force quit before choosing.

- new account → the flow shows, not the page list; Mood → Great → the grid opens with today's dot and the ring; the Edit button does not pulse;
- force quit, relaunch → lands on that tracker, no flow;
- a second new account, "Later" → page list (empty, + button); relaunch → page list again, no flow;
- an account with an empty "My Tracker" (create one with the + button on an older build, or `POST /api/pages` with curl) → the flow replaces it: one tracker in the list afterwards;
- airplane mode, then tap a legend → the error line and Retry; airplane off → Retry succeeds;
- airplane mode at launch on a never-activated account → the normal app;
- Larger Text (accessibility) and landscape: the cards scroll, nothing overflows.

- [ ] **Step 6: Commit**

```bash
git branch --show-current   # master
git add -A flutter_app/lib
git commit -m "App: first-tracker flow replaces the onboarding cards, triggered by the server's activated flag"
```

---

### Task 11: "Today" button in the tracker sidebar

**Files:**
- Modify: `flutter_app/lib/screens/tracker_screen.dart` (`_buildSidebar`, right after the Edit button; a new `_openToday` method near `_changeYear`)

**Interfaces:**
- Consumes: `lang.t('tracker.today')` (Task 5), `_changeYear(int delta)`, `CellEditorDialog.show(context, month:, day:, year:)`, `DashedBorder`.
- Produces: a dashed button under Edit and above the Stats header, icon-only when the sidebar is collapsed, that opens the cell editor on today's date (switching to the current year first when needed).

No unit test: it is two lines of UI plus a call into existing, tested paths (`_changeYear`, `CellEditorDialog.show`). Verified by analyze + the simulator steps below.

- [ ] **Step 1: Add the handler**

In `_TrackerScreenState`, right after `_changeYear`:

```dart
  /// "Today": the cell editor on today's date, from any year.
  void _openToday() {
    final today = DateTime.now();
    if (_year != today.year) _changeYear(today.year - _year);
    CellEditorDialog.show(context, month: today.month, day: today.day, year: today.year);
  }
```

- [ ] **Step 2: Add the button**

In `_buildSidebar`, the Edit button ends with `))),` (closing `Center(child: _MaybePulse(... child: GestureDetector(...)))`) followed by `],` that closes the legends `Column` children. Insert between them:

```dart
                    // Today: one tap to the day that matters.
                    const SizedBox(height: 6),
                    Center(
                      child: GestureDetector(
                        onTap: _openToday,
                        child: DashedBorder(
                          color: AppColors.inputBorder,
                          borderRadius: 4,
                          dashLength: 3,
                          gapLength: 2,
                          padding: EdgeInsets.symmetric(
                            horizontal: showLabels ? 8 : 4,
                            vertical: 5,
                          ),
                          child: showLabels
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, size: 10, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      lang.t('tracker.today'),
                                      style: AppFonts.pixel(fontSize: editFs, color: AppColors.accent),
                                    ),
                                  ],
                                )
                              : Icon(Icons.circle, size: 12, color: AppColors.accent),
                        ),
                      ),
                    ),
```

- [ ] **Step 3: Analyze and check on the simulator**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: no analyzer issue, all PASS.

Simulator: open a tracker → Today sits under Edit, above STATS, in the dashed style; tap → the editor opens on today's date; go to the previous year with the arrow, tap Today → the sidebar year becomes the current one and the editor opens on today; collapse the sidebar (chevron) → the icon-only button still works; phone portrait, landscape and tablet widths all fit.

- [ ] **Step 4: Commit**

```bash
git branch --show-current   # master
git add flutter_app/lib/screens/tracker_screen.dart
git commit -m "App: Today button in the tracker sidebar (editor on today's date, jumps to the current year)"
```

---

### Task 12: App changelogs, README, ROADMAP

**Files:**
- Modify: `flutter_app/CHANGELOG.md` (`## [Unreleased]`)
- Create: `flutter_app/docs/changelogs/1.4.0.md`
- Modify: `README.md` (after the "### Data loading (1.3.0+)" section)
- Modify: `docs/ROADMAP.md` (section "### 1. Activation (premier geste)")

**Interfaces:**
- Produces: the notes `./release-app.sh` requires (technical changelog + store notes, four locales ≤ 500 chars each).

- [ ] **Step 1: Technical changelog**

In `flutter_app/CHANGELOG.md` under `## [Unreleased]` add:

```markdown
Requires backend ≥ 1.2.0.

### Added
- First-tracker flow for any account without a single cell (new or dormant): pick a ready-made template (Mood, Sleep, Exercise, Reading, Habits, or a custom title), see today's date and set today's dot right there; the tracker then opens with the dot already placed. "Later" is remembered per device and account; the flow never runs offline or against a backend older than 1.2.0.
- "Today" button in the tracker sidebar: opens the cell editor on today's date, switching to the current year first when another one is shown.
- `PagesProvider.createFirstTracker` (page + legends in one request, replacing an empty page when the server allows it), `SyncService.activated` / `snapshotActivated`, `LanguageProvider.longDate`.

### Removed
- The three explanatory onboarding cards and the `onboarding_done` device flag: the flow explains by doing.
```

- [ ] **Step 2: Store notes**

Create `flutter_app/docs/changelogs/1.4.0.md`:

```markdown
# What's new — 1.4.0

Store release notes, pasted as-is in App Store Connect and the Play Console
(one block per store locale, same bullets in every language, 500 characters
max per block — the Play Console limit).

## en-US
- New here? Pick a ready-made tracker (mood, sleep, exercise, reading, habits or your own title) and set today's dot right away. Everything stays editable.
- New "Today" button in the tracker: one tap opens today's day, whatever year you are looking at.

## fr-FR
- Nouveau ? Choisissez un tracker prêt à l'emploi (humeur, sommeil, sport, lecture, habitudes ou votre propre titre) et posez le point du jour tout de suite. Tout reste modifiable.
- Nouveau bouton « Aujourd'hui » dans le tracker : un tap ouvre la journée en cours, quelle que soit l'année affichée.

## zh-Hans
- 刚开始使用？选择一个现成的追踪器（心情、睡眠、运动、阅读、习惯或自定义标题），马上填上今天的点。一切都可以之后修改。
- 追踪器新增「今天」按钮：一键打开今天，无论当前显示的是哪一年。

## zh-Hant
- 剛開始使用？選擇一個現成的追蹤器（心情、睡眠、運動、閱讀、習慣或自訂標題），馬上填上今天的點。一切都可以之後修改。
- 追蹤器新增「今天」按鈕：一鍵打開今天，無論目前顯示的是哪一年。
```

Check the limit: `awk '/^## /{if (n) print block, n; block=$0; n=0; next} {n += length($0)} END {print block, n}' flutter_app/docs/changelogs/1.4.0.md` — every block ≤ 500.

- [ ] **Step 3: README**

In `README.md`, after the "### Data loading (1.3.0+)" section (before "### Environment Variables"), add:

```markdown
### First tracker (1.4.0+)

`GET /api/bootstrap` says whether the account has any cell (`activated`).
When it does not (new or dormant account), and the device has not already
finished or skipped it for this account, the app shows the first-tracker
flow instead of the page list: six templates (`lib/data/first_tracker_templates.dart`,
labels in `language_provider.dart`), one `POST /api/pages` with `legends`
(and `replaces` when an empty page exists), then today's cell through the
usual cell route. The decision is `shouldShowFirstTracker` in
`lib/data/first_tracker_decision.dart`; the server never creates a page at
signup. Activation by signup cohort: `backend/scripts/prod-activation.sql`.
```

- [ ] **Step 4: ROADMAP**

In `docs/ROADMAP.md` replace the body of "### 1. Activation (premier geste)" with:

```markdown
### 1. Activation (premier geste) — en cours
Objectif : faire poser le premier point à l'inscription. Spec validé le
2026-10-15 : `docs/superpowers/specs/2026-10-15-activation-first-tracker-design.md`,
plan `docs/superpowers/plans/2026-10-15-activation-first-tracker.md`.
- Backend 1.2.0 : `POST /api/pages` avec légendes et remplacement d'une page
  vide, `bootstrap.activated`, plus de "My Tracker" à l'inscription,
  `cells.created_at`, `scripts/prod-activation.sql`.
- App 1.4.0 : parcours en deux écrans (modèle → point du jour) pour tout
  compte sans case, bouton Aujourd'hui dans le tracker.
- Mesure de succès : part des nouveaux comptes avec ≥ 1 case à J+1 et J+7
  par cohorte hebdomadaire (aujourd'hui ~53 % à vie). Première lecture de
  référence à la sortie, bilan à huit semaines.
```

- [ ] **Step 5: Commit**

```bash
git branch --show-current   # master
git add flutter_app/CHANGELOG.md flutter_app/docs/changelogs/1.4.0.md README.md docs/ROADMAP.md
git commit -m "Docs: app 1.4.0 changelog and store notes, README first-tracker section, roadmap"
```

---

### Task 13: Release — run by hand by Charles (never by an agent)

**Files:** none in the repo beyond what the scripts commit.

**Interfaces:**
- Consumes: Tasks 1–12 merged on `master`, pushed, CI green.

These commands change production and the stores; they are Charles's to run, in this order, from a real terminal (`./deploy-prod.sh` asks for the version typed back).

- [ ] **Step 1: Backend 1.2.0**

```bash
git branch --show-current && git status --short     # master, clean, pushed
./release-backend.sh minor                          # backend-v1.2.0; follow the printed `gh run watch`
./deploy-prod.sh                                    # migration 0013 runs during the deploy
curl -fsS https://diandian.overridedev.com/api/health   # "version":"1.2.0"
cd backend && SMOKE_BASE=https://diandian.overridedev.com npx tsx scripts/smoke.ts   # throwaway account, deleted at the end
```

Then the baseline: `ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-activation.sql` — copy the table into `docs/ROADMAP.md` ("Mesures") as the pre-release reference.

- [ ] **Step 2: App 1.4.0**

```bash
./release-app.sh minor            # app-v1.4.0 (needs docs/changelogs/1.4.0.md, Task 12)
git checkout app-v1.4.0
make prod-ios                     # upload the .ipa, submit for review
make prod-android                 # upload the .aab in the Play Console
git checkout master
```

- [ ] **Step 3: Eight weeks later**

Run `prod-activation.sql` again; the J+7 column of the post-release cohorts against the pre-release reference is the verdict (spec: clearly above the 53 % lifetime figure).

---

## Self-review notes

- Spec coverage: templates + four languages (5), trigger from the server with device flag and limit rule (7, 8, 10), screen 1 and screen 2 with every edge case (9), replaceable page (3, 6, 8, 9), after-flow landing (10), Today button (11), `POST /api/pages` extension (3), bootstrap flag (2), no default page (2), migration 0013 (1), smoke tests (1–3), measurement script (4), compatibility and rollout order (13), changelogs (4, 12).
- Deliberate gaps: no widget test for the Today button and the `main.dart` wiring (manual simulator steps in 10 and 11); the French "vous" rule is pinned by a test on three keys only.
