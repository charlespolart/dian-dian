import { Router } from 'express';
import { z } from 'zod';
import { db } from '../db/index.js';
import { pages, cells, legends } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { broadcast } from '../lib/ws.js';
import { eq, and, asc } from 'drizzle-orm';

const router = Router();
router.use(requireAuth);

// Get all pages for user
router.get('/', async (req, res) => {
  try {
    const result = await db.select()
      .from(pages)
      .where(eq(pages.userId, req.userId!))
      .orderBy(asc(pages.position));
    res.json(result.map(p => ({ ...p, palette: p.palette ? JSON.parse(p.palette) : null })));
  } catch (err) {
    console.error('Get pages error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

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

const reorderPagesSchema = z.object({
  ids: z.array(z.string().uuid()).max(500),
});

// Reorder pages in one request + one transaction. The pre-1.3.0 client sent
// a PATCH per page (still supported below).
router.put('/reorder', validate(reorderPagesSchema), async (req, res) => {
  try {
    const { ids } = req.body as { ids: string[] };
    await db.transaction(async (tx) => {
      for (let i = 0; i < ids.length; i++) {
        // Scoped to the caller's pages so foreign ids are no-ops.
        await tx.update(pages)
          .set({ position: i })
          .where(and(eq(pages.id, ids[i]), eq(pages.userId, req.userId!)));
      }
    });
    broadcast(req.userId!, 'pages:reordered', { ids });
    res.json({ ok: true });
  } catch (err) {
    console.error('Reorder pages error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

const paletteSchema = z.array(
  z.array(z.string().regex(/^#[0-9A-Fa-f]{6}$/)).length(6)
).min(1).max(7);

const updatePageSchema = z.object({
  title: z.string().min(1).max(35).optional(),
  position: z.number().int().min(0).optional(),
  palette: paletteSchema.nullable().optional(),
});

// Update page
router.patch('/:id', validate(updatePageSchema), async (req, res) => {
  try {
    const body = { ...req.body };
    if (body.palette !== undefined) {
      body.palette = body.palette === null ? null : JSON.stringify(body.palette);
    }
    const [page] = await db.update(pages)
      .set(body)
      .where(and(eq(pages.id, String(req.params.id)), eq(pages.userId, req.userId!)))
      .returning();
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }
    const parsed = { ...page, palette: page.palette ? JSON.parse(page.palette) : null };
    broadcast(req.userId!, 'page:updated', parsed);
    res.json(parsed);
  } catch (err) {
    console.error('Update page error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete page
router.delete('/:id', async (req, res) => {
  try {
    const [page] = await db.delete(pages)
      .where(and(eq(pages.id, String(req.params.id)), eq(pages.userId, req.userId!)))
      .returning({ id: pages.id });
    if (!page) { res.status(404).json({ error: 'Page not found' }); return; }
    broadcast(req.userId!, 'page:deleted', { id: page.id });
    res.json({ ok: true });
  } catch (err) {
    console.error('Delete page error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
