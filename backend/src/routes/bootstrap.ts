import { Router } from 'express';
import { db } from '../db/index.js';
import { pages, cells, legends } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { eq, and, asc, sql } from 'drizzle-orm';
import { pageActivity } from '../lib/premium.js';

const router = Router();
router.use(requireAuth);

function parseYear(input: unknown): number | null {
  if (typeof input !== 'string') return null;
  const n = parseInt(input, 10);
  return Number.isInteger(n) && n >= 2000 && n <= 2100 ? n : null;
}

// `[month, day, color]` or `[month, day, color, comment]` — ~16 bytes per cell
// instead of ~130 for the verbose row, and no per-cell pageId/updatedAt the
// grid never reads.
type CompactCell = [number, number, string] | [number, number, string, string];

// GET /api/bootstrap?year=YYYY
//
// One round-trip for everything the app needs to paint the page list and
// open any tracker on `year`: every page, every legend, and the cells of
// that year for every page. Replaces the 1 + 2N request cascade the
// pre-1.3.0 client made (pages, then cells + legends per page).
//
// Every page id is present as a key in `legends` and `cells` (possibly an
// empty array) so the client can treat "key present" as "loaded".
// `activated`: the account has at least one cell (any page, any year).
// Each page carries `recentCells` (cells touched in the last 90 days) and
// `lastCellAt`, plus its `keepFree` flag.
router.get('/', async (req, res) => {
  try {
    const userId = req.userId!;
    const year = parseYear(req.query.year) ?? new Date().getFullYear();

    const [pageRows, legendRows, cellRows, anyCell, activity] = await Promise.all([
      db.select()
        .from(pages)
        .where(eq(pages.userId, userId))
        .orderBy(asc(pages.position)),
      db.select({
        id: legends.id,
        pageId: legends.pageId,
        color: legends.color,
        label: legends.label,
        position: legends.position,
        createdAt: legends.createdAt,
      })
        .from(legends)
        .innerJoin(pages, eq(pages.id, legends.pageId))
        .where(eq(pages.userId, userId))
        // Deterministic order: the client skips bodies that are byte-identical
        // to the previous one, which only works if row order is stable.
        .orderBy(asc(legends.pageId), asc(legends.position), asc(legends.id)),
      db.select({
        pageId: cells.pageId,
        month: cells.month,
        day: cells.day,
        color: cells.color,
        comment: cells.comment,
      })
        .from(cells)
        .innerJoin(pages, eq(pages.id, cells.pageId))
        .where(and(eq(pages.userId, userId), eq(cells.year, year)))
        .orderBy(asc(cells.pageId), asc(cells.month), asc(cells.day)),
      // Any cell at all for this account (any page, any year): drives the
      // first-tracker flow in app ≥ 1.4.0. Index pages_user_id_idx + the
      // cells primary key (page_id first) make it a lookup.
      db.select({ one: sql<number>`1` })
        .from(cells)
        .innerJoin(pages, eq(pages.id, cells.pageId))
        .where(eq(pages.userId, userId))
        .limit(1),
      // Activity per page, all years: lets a free account over the limit
      // keep its most active trackers by default (1.2.0).
      pageActivity(userId),
    ]);

    const legendsByPage: Record<string, typeof legendRows> = {};
    const cellsByPage: Record<string, CompactCell[]> = {};
    for (const p of pageRows) {
      legendsByPage[p.id] = [];
      cellsByPage[p.id] = [];
    }
    for (const l of legendRows) legendsByPage[l.pageId]?.push(l);
    for (const c of cellRows) {
      cellsByPage[c.pageId]?.push(
        c.comment ? [c.month, c.day, c.color, c.comment] : [c.month, c.day, c.color],
      );
    }

    res.set('Cache-Control', 'no-store');
    res.json({
      year,
      activated: anyCell.length > 0,
      pages: pageRows.map((p) => {
        const a = activity.get(p.id);
        return {
          ...p,
          palette: p.palette ? JSON.parse(p.palette) : null,
          recentCells: a?.recentCells ?? 0,
          lastCellAt: a?.lastCellAt?.toISOString() ?? null,
        };
      }),
      legends: legendsByPage,
      cells: cellsByPage,
    });
  } catch (err) {
    console.error('Bootstrap error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
