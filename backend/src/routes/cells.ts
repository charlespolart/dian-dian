import { Router } from 'express';
import { z } from 'zod';
import { db } from '../db/index.js';
import { cells, pages } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { broadcast } from '../lib/ws.js';
import { eq, and } from 'drizzle-orm';

const router = Router();
router.use(requireAuth);

// Legacy clients (≤ 1.1.0) don't send a year — we fall back to the page's
// own pages.year so their stored data continues to render correctly. New
// clients always send year explicitly.
function pickYear(input: unknown, pageYear: number): number {
  if (typeof input === 'number' && Number.isInteger(input)) return input;
  if (typeof input === 'string') {
    const n = parseInt(input, 10);
    if (!Number.isNaN(n)) return n;
  }
  return pageYear;
}

// Get cells for a page. Filtered by year (defaults to the page's own year for
// legacy compat) unless `?all=true` is passed — used by global all-time stats.
router.get('/:pageId', async (req, res) => {
  try {
    const [page] = await db.select({ id: pages.id, year: pages.year })
      .from(pages)
      .where(and(eq(pages.id, String(req.params.pageId)), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const pageId = String(req.params.pageId);
    if (req.query.all === 'true') {
      const result = await db.select().from(cells).where(eq(cells.pageId, pageId));
      res.json(result);
      return;
    }

    const year = pickYear(req.query.year, page.year);
    const result = await db.select()
      .from(cells)
      .where(and(eq(cells.pageId, pageId), eq(cells.year, year)));
    res.json(result);
  } catch (err) {
    console.error('Get cells error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

const upsertCellSchema = z.object({
  year: z.number().int().min(2000).max(2100).optional(),
  month: z.number().int().min(0).max(11),
  day: z.number().int().min(1).max(31),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Couleur hex invalide'),
  comment: z.string().max(200).nullable().optional(),
});

router.put('/:pageId', validate(upsertCellSchema), async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const { month, day, color, comment } = req.body;

    const [page] = await db.select({ id: pages.id, year: pages.year })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }
    const year = pickYear(req.body.year, page.year);

    const [cell] = await db.insert(cells)
      .values({ pageId, year, month, day, color, comment: comment ?? null, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: [cells.pageId, cells.year, cells.month, cells.day],
        set: { color, comment: comment ?? null, updatedAt: new Date() },
      })
      .returning();

    broadcast(req.userId!, 'cell:updated', cell);
    res.json(cell);
  } catch (err) {
    console.error('Upsert cell error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

const deleteCellSchema = z.object({
  year: z.number().int().min(2000).max(2100).optional(),
  month: z.number().int().min(0).max(11),
  day: z.number().int().min(1).max(31),
});

router.delete('/:pageId', validate(deleteCellSchema), async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const { month, day } = req.body;

    const [page] = await db.select({ id: pages.id, year: pages.year })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }
    const year = pickYear(req.body.year, page.year);

    await db.delete(cells)
      .where(and(
        eq(cells.pageId, pageId),
        eq(cells.year, year),
        eq(cells.month, month),
        eq(cells.day, day),
      ));

    broadcast(req.userId!, 'cell:deleted', { pageId, year, month, day });
    res.json({ ok: true });
  } catch (err) {
    console.error('Delete cell error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Recolor: rename one color → another across ALL years for this tracker.
// (Legend rename is conceptually global to the tracker, not year-specific.)
const recolorSchema = z.object({
  colorMap: z.record(z.string().regex(/^#[0-9A-Fa-f]{6}$/), z.string().regex(/^#[0-9A-Fa-f]{6}$/)),
});

router.patch('/:pageId/recolor', validate(recolorSchema), async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const { colorMap } = req.body;
    for (const [oldColor, newColor] of Object.entries(colorMap)) {
      await db.update(cells)
        .set({ color: newColor as string, updatedAt: new Date() })
        .where(and(eq(cells.pageId, pageId), eq(cells.color, oldColor)));
    }

    broadcast(req.userId!, 'cells:recolored', { pageId, colorMap });
    res.json({ ok: true });
  } catch (err) {
    console.error('Recolor cells error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Reset all cells for a page in a specific year (defaults to current year).
router.delete('/:pageId/all', async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const [page] = await db.select({ id: pages.id, year: pages.year })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const year = pickYear(req.body?.year ?? req.query.year, page.year);
    await db.delete(cells)
      .where(and(eq(cells.pageId, pageId), eq(cells.year, year)));

    broadcast(req.userId!, 'cells:reset', { pageId, year });
    res.json({ ok: true });
  } catch (err) {
    console.error('Reset cells error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
