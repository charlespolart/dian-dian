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
router.get('/', async (req, res) => {
  try {
    const userId = req.userId!;
    const year = parseYear(req.query.year) ?? new Date().getFullYear();

    const [pageRows, legendRows, cellRows] = await Promise.all([
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
        .orderBy(asc(legends.position)),
      db.select({
        pageId: cells.pageId,
        month: cells.month,
        day: cells.day,
        color: cells.color,
        comment: cells.comment,
      })
        .from(cells)
        .innerJoin(pages, eq(pages.id, cells.pageId))
        .where(and(eq(pages.userId, userId), eq(cells.year, year))),
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
