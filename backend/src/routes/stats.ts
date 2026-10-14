import { Router } from 'express';
import { db } from '../db/index.js';
import { pages, cells } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { eq, asc } from 'drizzle-orm';

const router = Router();
router.use(requireAuth);

// GET /api/stats/days
//
// Every filled date of every page, all years: `{ pageId: [[year, month, day], ...] }`.
// Feeds the "all time" mode of the global stats dialog in one request (the
// client only needs dates to count days and compute streaks). Pages with no
// cells are simply absent — the client iterates its own page list.
router.get('/days', async (req, res) => {
  try {
    const rows = await db.select({
      pageId: cells.pageId,
      year: cells.year,
      month: cells.month,
      day: cells.day,
    })
      .from(cells)
      .innerJoin(pages, eq(pages.id, cells.pageId))
      .where(eq(pages.userId, req.userId!))
      .orderBy(asc(cells.pageId), asc(cells.year), asc(cells.month), asc(cells.day));

    const byPage: Record<string, [number, number, number][]> = {};
    for (const r of rows) (byPage[r.pageId] ??= []).push([r.year, r.month, r.day]);

    res.set('Cache-Control', 'no-store');
    res.json(byPage);
  } catch (err) {
    console.error('Stats days error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
