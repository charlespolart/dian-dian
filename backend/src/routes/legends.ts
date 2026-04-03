import { Router } from 'express';
import { z } from 'zod';
import { db } from '../db/index.js';
import { legends, pages } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { broadcast } from '../lib/ws.js';
import { eq, and, asc } from 'drizzle-orm';

const router = Router();
router.use(requireAuth);

// Get legends for a page
router.get('/:pageId', async (req, res) => {
  try {
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, String(req.params.pageId)), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const result = await db.select()
      .from(legends)
      .where(eq(legends.pageId, String(req.params.pageId)))
      .orderBy(asc(legends.position));
    res.json(result);
  } catch (err) {
    console.error('Get legends error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

const createLegendSchema = z.object({
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  label: z.string().min(1).max(30),
  position: z.number().int().min(0).default(0),
});

// Create legend
router.post('/:pageId', validate(createLegendSchema), async (req, res) => {
  try {
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, String(req.params.pageId)), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    // Max 12 legends per page
    const existing = await db.select({ id: legends.id })
      .from(legends)
      .where(eq(legends.pageId, String(req.params.pageId)));
    if (existing.length >= 12) { res.status(400).json({ error: 'Maximum 12 legends per page' }); return; }

    const [legend] = await db.insert(legends)
      .values({ pageId: String(req.params.pageId), ...req.body })
      .returning();

    broadcast(req.userId!, 'legend:created', legend);
    res.status(201).json(legend);
  } catch (err) {
    console.error('Create legend error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

const reorderSchema = z.object({
  ids: z.array(z.string().uuid()),
});

// Reorder legends
router.put('/:pageId/reorder', validate(reorderSchema), async (req, res) => {
  try {
    const { ids } = req.body;
    await Promise.all(ids.map((id: string, i: number) =>
      db.update(legends).set({ position: i }).where(eq(legends.id, id))
    ));
    broadcast(req.userId!, 'legends:reordered', { pageId: String(req.params.pageId), ids });
    res.json({ ok: true });
  } catch (err) {
    console.error('Reorder legends error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Recolor legends
const recolorLegendSchema = z.object({
  colorMap: z.record(z.string().regex(/^#[0-9A-Fa-f]{6}$/), z.string().regex(/^#[0-9A-Fa-f]{6}$/)),
});

router.patch('/:pageId/recolor', validate(recolorLegendSchema), async (req, res) => {
  try {
    const pageId = String(req.params.pageId);
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }

    const { colorMap } = req.body;
    for (const [oldColor, newColor] of Object.entries(colorMap)) {
      await db.update(legends)
        .set({ color: newColor as string })
        .where(and(eq(legends.pageId, pageId), eq(legends.color, oldColor)));
    }

    broadcast(req.userId!, 'legends:recolored', { pageId, colorMap });
    res.json({ ok: true });
  } catch (err) {
    console.error('Recolor legends error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update legend (label/color)
const updateLegendSchema = z.object({
  label: z.string().min(1).max(30).optional(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
});

router.patch('/:id', validate(updateLegendSchema), async (req, res) => {
  try {
    const [legend] = await db.select({ id: legends.id, pageId: legends.pageId })
      .from(legends)
      .where(eq(legends.id, String(req.params.id)))
      .limit(1);
    if (!legend) { res.status(404).json({ error: 'Legend not found' }); return; }

    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, legend.pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(403).json({ error: 'Unauthorized' }); return; }

    const [updated] = await db.update(legends)
      .set(req.body)
      .where(eq(legends.id, String(req.params.id)))
      .returning();

    broadcast(req.userId!, 'legend:updated', updated);
    res.json(updated);
  } catch (err) {
    console.error('Update legend error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete legend
router.delete('/:id', async (req, res) => {
  try {
    const [legend] = await db.select({ id: legends.id, pageId: legends.pageId })
      .from(legends)
      .where(eq(legends.id, String(req.params.id)))
      .limit(1);
    if (!legend) { res.status(404).json({ error: 'Legend not found' }); return; }

    // Verify ownership
    const [page] = await db.select({ id: pages.id })
      .from(pages)
      .where(and(eq(pages.id, legend.pageId), eq(pages.userId, req.userId!)))
      .limit(1);
    if (!page) { res.status(403).json({ error: 'Unauthorized' }); return; }

    await db.delete(legends).where(eq(legends.id, String(req.params.id)));
    broadcast(req.userId!, 'legend:deleted', { id: String(req.params.id), pageId: legend.pageId });
    res.json({ ok: true });
  } catch (err) {
    console.error('Delete legend error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
