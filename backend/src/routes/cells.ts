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

// Get all cells for a page
router.get('/:pageId', async (req, res) => {
  try {
    // Verify page belongs to user
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, String(req.params.pageId)), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const result = await db.select()
      .from(cells)
      .where(eq(cells.pageId, String(req.params.pageId)));
    res.json(result);
  } catch (err) {
    console.error('Get cells error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

const upsertCellSchema = z.object({
  month: z.number().int().min(0).max(11),
  day: z.number().int().min(1).max(31),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Couleur hex invalide'),
  comment: z.string().max(200).nullable().optional(),
});

// Upsert cell (set color)
router.put('/:pageId', validate(upsertCellSchema), async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const { month, day, color, comment } = req.body;

    // Verify page belongs to user
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const [cell] = await db.insert(cells)
      .values({ pageId, month, day, color, comment: comment ?? null, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: [cells.pageId, cells.month, cells.day],
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
  month: z.number().int().min(0).max(11),
  day: z.number().int().min(1).max(31),
});

// Delete cell (erase color)
router.delete('/:pageId', validate(deleteCellSchema), async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const { month, day } = req.body;

    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    await db.delete(cells)
      .where(and(eq(cells.pageId, pageId), eq(cells.month, month), eq(cells.day, day)));

    broadcast(req.userId!, 'cell:deleted', { pageId, month, day });
    res.json({ ok: true });
  } catch (err) {
    console.error('Delete cell error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Recolor: batch update colors
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

// Delete all cells for a page (reset)
router.delete('/:pageId/all', async (req, res) => {
  try {
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, String(req.params.pageId)), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    await db.delete(cells).where(eq(cells.pageId, String(req.params.pageId)));

    broadcast(req.userId!, 'cells:reset', { pageId: String(req.params.pageId) });
    res.json({ ok: true });
  } catch (err) {
    console.error('Reset cells error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
