# Multi-year tracker refactor (C2)

## Goal
Trackers become year-agnostic. Cells gain a `year` field. Users no longer
recreate a tracker each January — they navigate years inside a single tracker
that lives forever.

---

## UX

### Before
- PageList top bar: `< 2026 >` switches the **list of trackers** for that year.
- Each tracker is bound to one year. Jan 1 → must recreate "Mood 2027" + redo
  legends.

### After
- PageList top bar: `< 2026 >` stays — but now it switches the **mini-grid
  preview** of each tracker. The list itself shows all trackers, always.
- Click a tracker → opens TrackerScreen on the selected year.
- TrackerScreen top bar: **new** year selector → navigate years without going
  back to PageList.

Net: two levels of year navigation (overview vs deep), no more annual
recreation.

---

## Schema

```sql
-- pages: drop year, trackers are year-agnostic
ALTER TABLE pages DROP COLUMN year;

-- cells: add year, new composite PK
ALTER TABLE cells ADD COLUMN year SMALLINT NOT NULL;
ALTER TABLE cells DROP CONSTRAINT cells_pkey;
ALTER TABLE cells ADD PRIMARY KEY (page_id, year, month, day);
CREATE INDEX cells_page_year_idx ON cells (page_id, year);
```

### Data migration (drizzle SQL, run inside transaction)
```sql
-- 1. add cells.year (nullable initially)
ALTER TABLE cells ADD COLUMN year SMALLINT;

-- 2. backfill from pages.year
UPDATE cells
SET year = pages.year
FROM pages
WHERE cells.page_id = pages.id;

-- 3. enforce NOT NULL + new PK
ALTER TABLE cells ALTER COLUMN year SET NOT NULL;
ALTER TABLE cells DROP CONSTRAINT cells_pkey;
ALTER TABLE cells ADD PRIMARY KEY (page_id, year, month, day);
CREATE INDEX cells_page_year_idx ON cells (page_id, year);

-- 4. drop pages.year
ALTER TABLE pages DROP COLUMN year;
```

**Existing data**: "Mood 2024" and "Mood 2025" stay as 2 separate trackers
(no auto-merge — risky). User can manually delete duplicates if desired.

---

## File-by-file changes

### Backend (`backend/src/`)

| File | Change |
|---|---|
| `db/schema.ts` | Drop `pages.year`, add `cells.year`, change PK |
| `drizzle/<timestamp>_multiyear.sql` | Migration above |
| `routes/pages.ts` | Remove `?year=` filter; return all pages for user |
| `routes/cells.ts` | Add `year` query param to GET; add to body for PUT/DELETE |
| `lib/ws.ts` | Include `year` in cell-update events |

### Flutter (`flutter_app/lib/`)

| File | Change |
|---|---|
| `models/page_model.dart` | Drop `year` field |
| `models/cell_model.dart` | Add `year` field |
| `providers/pages_provider.dart` | Load all user pages (no year filter) |
| `providers/cells_provider.dart` | Map keyed by `(year, month, day)`; loadFor(pageId, year); setCell(year, m, d, color) |
| `providers/legends_provider.dart` | Unchanged (legends already per-page, shared across years naturally) |
| `screens/page_list_screen.dart` | Year selector stays; mini-grids use selected year; pass year on tracker open |
| `screens/tracker_screen.dart` | NEW: year selector in top bar with `< >` arrows; reload cells on year change |
| `widgets/tracker_grid.dart` | Already takes `year` prop — no change |
| `widgets/stats_detail_dialog.dart` | Already year-scoped via passed `year` — verify |
| `widgets/global_stats_dialog.dart` | Year-scoped (use selected PageList year) |
| `widgets/export_image_builder.dart` | Export current active year |
| `services/ws_service.dart` | Parse `year` from events; only apply if matches active year of cells provider |

---

## Backward compatibility (during rollout window)

Old Flutter clients hit new backend without sending `year`:

- `GET /api/cells?pageId=X` (no year) → server defaults to **current
  calendar year** (`new Date().getFullYear()`).
- `PUT /api/cells` body without `year` → server defaults to current year.
- `GET /api/pages?year=X` → server **ignores** the year, returns all pages.
- WebSocket events with no `year`: server emits with current year; old clients
  ignore the field.

This keeps the old app working until users update from the App Store.

---

## Order of operations

1. **Schema** — update `db/schema.ts`, generate migration, hand-edit SQL to use
   the safe 4-step backfill.
2. **Backend routes** — `pages.ts`, `cells.ts`, `lib/ws.ts`, with
   backward-compat defaults.
3. **Backend tests** — manual: hit endpoints with and without `year`.
4. **Flutter models** — `PageModel`, `CellModel`.
5. **Flutter providers** — `PagesProvider`, `CellsProvider`. Verify compile.
6. **Flutter UI** — `PageListScreen` (year selector behavior change),
   `TrackerScreen` (new year selector).
7. **Flutter peripherals** — stats, export, WS.
8. **Compile + analyze** — `flutter analyze` clean.
9. **Manual smoke test** — create tracker, fill 2026, switch to 2027, fill,
   navigate back to 2026, check persistence + sync.

---

## Edge cases

| Case | Handling |
|---|---|
| Year with no cells for tracker | Empty grid, normal fill flow |
| Best streak | Stays year-scoped (cohérent avec "stats of year X") |
| Cross-year streak (Dec 31 → Jan 1) | Out of scope for v1 — possible v2 |
| Real-time sync from another device on different year | WS listener filters: only apply if `event.year == cellsProvider.currentYear` |
| Today highlight | Already correct (renders only when `year == DateTime.now().year`) |
| Leap year (Feb 29) | Already handled in `getDaysInMonth(month, year)` |
| Premium maxFreeTrackers | Unchanged — count is per-tracker, not per-tracker-per-year |
| Export PNG | Exports the active year of the current tracker |
| Page reorder | Stays per-tracker (position field), unchanged |

---

## Testing checklist (post-implementation)

- [ ] Create new tracker on 2026, fill 5 cells → save → reload → cells persist
- [ ] Switch to 2027 in tracker view → grid empty → fill 3 cells → save
- [ ] Switch back to 2026 → previous 5 cells still there
- [ ] Go to PageList, switch year selector to 2027 → mini-grid shows 3 cells
- [ ] Switch year selector to 2026 → mini-grid shows 5 cells
- [ ] Open another tracker (existing pre-migration "Mood 2025") → its data is on 2025 only
- [ ] Stats dialog: shows year-scoped numbers correctly
- [ ] Global stats: uses selected year
- [ ] Export PNG: exports the active year
- [ ] Real-time sync: another device modifying 2025 doesn't update 2026 view
- [ ] Today border: only shows on current year
- [ ] Old Flutter app (pre-update) still loads and saves cells (backward compat)

---

## Rollout

1. **Backup prod DB** before deploy: `pg_dump diandian > backup-pre-multiyear-$(date +%Y%m%d).sql`
2. Deploy backend (migration runs on `npm run db:migrate` then start)
3. Verify backend with old Flutter app still works (backward compat sanity)
4. Build + submit Flutter app to App Store
5. Monitor Sentry / logs for any cell save errors during transition
6. After ~80% users updated (2-3 weeks): remove backward-compat defaults, make
   `year` required in cells endpoints
