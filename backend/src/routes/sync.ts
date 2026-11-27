/**
 * Offline sync (chantier 10): the phone sends the changes it queued, and asks
 * what changed since the last number it saw.
 * Spec: docs/superpowers/specs/2026-11-26-offline-sync-design.md;
 * plan: docs/superpowers/plans/2026-11-27-offline-sync.md (task 3).
 *
 * POST /api/sync/mutations {mutations: [...]} — 1 to 100 changes, judged and
 *   applied one by one, in order, each in its own transaction with the
 *   record of its answer: a change sent again (its answer lost) gets the
 *   same answer and is never applied twice. Answers: {results, rev}.
 * GET /api/sync?since=N — everything whose number is above N, the deletion
 *   traces, the orders and settings that changed, Premium, and the account's
 *   number. since=0, a number below the account's floor (traces purged since)
 *   or above its counter (a restored database) gives the full copy.
 */
import { Router } from 'express';
import { and, asc, eq, gt, inArray } from 'drizzle-orm';
import { db } from '../db/index.js';
import { cells, deletions, legends, pages, syncMutations, users } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { broadcast } from '../lib/ws.js';
import { hasActiveSubscription } from '../lib/premium.js';
import { recordSyncBatch } from '../lib/syncStats.js';
import { applyMutation, type Outgoing } from '../sync/apply.js';
import { parseMutation, type MutationResult } from '../sync/mutations.js';

const router = Router();
router.use(requireAuth);

const maxBatch = 100;

router.post('/mutations', async (req, res) => {
  const raw = (req.body as { mutations?: unknown })?.mutations;
  if (!Array.isArray(raw) || raw.length === 0 || raw.length > maxBatch) {
    res.status(400).json({ error: `1 to ${maxBatch} mutations` });
    return;
  }
  const userId = req.userId!;
  try {
    const results: MutationResult[] = [];
    const events: Outgoing[] = [];
    let waited = 0;
    for (const item of raw) {
      const m = parseMutation(item);
      if (!m) {
        const id = typeof (item as { id?: unknown })?.id === 'string' ? (item as { id: string }).id : '';
        results.push({ id, status: 'rejected', reason: 'invalid' });
        continue;
      }
      if (m.waited) waited++;
      const outcome = await db.transaction(async (tx) => {
        // Answered before: the same answer, nothing applied again.
        const [done] = await tx.select({ result: syncMutations.result }).from(syncMutations)
          .where(and(eq(syncMutations.userId, userId), eq(syncMutations.id, m.id))).limit(1);
        if (done) return { result: done.result as MutationResult, events: [] as Outgoing[] };
        const applied = await applyMutation(tx, userId, m);
        await tx.insert(syncMutations).values({ id: m.id, userId, result: applied.result });
        return applied;
      });
      results.push(outcome.result);
      events.push(...outcome.events);
    }
    const [{ rev }] = await db.select({ rev: users.rev }).from(users).where(eq(users.id, userId)).limit(1);
    // Apps 1.4.0 hear today's events; the newer ones fetch what changed.
    for (const [event, data] of events) broadcast(userId, event, data);
    if (events.length > 0) broadcast(userId, 'sync', { rev });
    recordSyncBatch(new Date(), waited, results).catch((err) => console.error('Sync stats failed:', err));
    res.json({ results, rev });
  } catch (err) {
    console.error('Sync mutations error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

/** A day as the phone stores it: [year, month, day, color, comment, rev, editRev]. */
type CompactCell = [number, number, number, string, string | null, number, number];

router.get('/', async (req, res) => {
  const userId = req.userId!;
  const asked = Number(req.query.since);
  try {
    const [account] = await db.select().from(users).where(eq(users.id, userId)).limit(1);
    if (!account) { res.status(404).json({ error: 'Not found' }); return; }
    const full = !Number.isInteger(asked) || asked <= 0 || asked < account.syncFloorRev || asked > account.rev;
    const since = full ? -1 : asked;

    const ownPages = await db.select().from(pages).where(eq(pages.userId, userId)).orderBy(asc(pages.position), asc(pages.createdAt));
    const pageIds = ownPages.map((p) => p.id);
    const changedPages = ownPages.filter((p) => p.rev > since);
    const [legendRows, cellRows, traceRows] = await Promise.all([
      pageIds.length === 0 ? [] : db.select().from(legends)
        .where(and(inArray(legends.pageId, pageIds), gt(legends.rev, since)))
        .orderBy(asc(legends.pageId), asc(legends.position)),
      pageIds.length === 0 ? [] : db.select({
        pageId: cells.pageId, year: cells.year, month: cells.month, day: cells.day,
        color: cells.color, comment: cells.comment, rev: cells.rev, editRev: cells.editRev,
      }).from(cells).where(and(inArray(cells.pageId, pageIds), gt(cells.rev, since))),
      full ? [] : db.select({ kind: deletions.kind, key: deletions.key, pageId: deletions.pageId, rev: deletions.rev })
        .from(deletions).where(and(eq(deletions.userId, userId), gt(deletions.rev, since))).orderBy(asc(deletions.rev)),
    ]);

    const cellsByPage: Record<string, CompactCell[]> = {};
    for (const c of cellRows) {
      (cellsByPage[c.pageId] ??= []).push([c.year, c.month, c.day, c.color, c.comment, c.rev, c.editRev]);
    }
    // The order of a tracker's legends, for the trackers whose order changed.
    const legendsOrder: Record<string, { rev: number; ids: string[] }> = {};
    const reordered = ownPages.filter((p) => p.legendsOrderRev > since).map((p) => p.id);
    if (reordered.length > 0) {
      const rows = await db.select({ id: legends.id, pageId: legends.pageId }).from(legends)
        .where(inArray(legends.pageId, reordered)).orderBy(asc(legends.pageId), asc(legends.position));
      for (const p of ownPages.filter((x) => reordered.includes(x.id))) {
        legendsOrder[p.id] = { rev: p.legendsOrderRev, ids: rows.filter((r) => r.pageId === p.id).map((r) => r.id) };
      }
    }
    const setting = <T>(rev: number, value: T) => (rev > since ? { rev, value } : undefined);

    res.json({
      rev: account.rev,
      full,
      pages: changedPages.map((p) => ({
        id: p.id, title: p.title, position: p.position, keepFree: p.keepFree, createdAt: p.createdAt,
        palette: p.palette ? JSON.parse(p.palette) : null,
        rev: p.rev, editRev: p.editRev, contentRev: p.contentRev, legendsOrderRev: p.legendsOrderRev,
      })),
      legends: legendRows.map((l) => ({ id: l.id, pageId: l.pageId, color: l.color, label: l.label, position: l.position, rev: l.rev, editRev: l.editRev })),
      cells: cellsByPage,
      deletions: traceRows,
      pagesOrder: account.pagesOrderRev > since ? { rev: account.pagesOrderRev, ids: pageIds } : undefined,
      keepFree: account.keepFreeRev > since ? { rev: account.keepFreeRev, ids: ownPages.filter((p) => p.keepFree).map((p) => p.id) } : undefined,
      legendsOrder,
      settings: {
        theme: setting(account.themeRev, account.theme),
        language: setting(account.languageRev, account.language),
        cursor: setting(account.cursorRev, { id: account.cursorId, enabled: account.cursorEnabled }),
      },
      premium: await hasActiveSubscription(userId),
      vip: account.vip,
    });
  } catch (err) {
    console.error('Sync error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
