/**
 * Applying one change a phone sent (offline sync, chantier 10), inside the
 * caller's transaction: read what the server has of its element, judge it
 * (mutations.ts), and apply it or say why not. What other devices must hear
 * is returned, to be broadcast once the transaction has committed: today's
 * events for apps 1.4.0 (which do not know `sync`), and the caller adds one
 * `sync` for the newer apps.
 *
 * A change that waited is never refused for the free tier (decided by
 * Charles: losing entries would cost more than the rule earns); one made
 * online keeps today's checks.
 */
import { and, asc, count, eq, inArray, max } from 'drizzle-orm';
import { cells, deletions, legends, pages, users } from '../db/schema.js';
import { daysInMonth } from '../lib/dates.js';
import { isUnlimited, lockedPageIds, maxFreeTrackers } from '../lib/premium.js';
import { cellKey, nextRev, touchPageContent, trace, type Tx } from '../lib/revs.js';
import { dayNumber, judge, mergeOrder, type ElementState, type Mutation, type MutationResult } from './mutations.js';

/** An event for the account's other devices: [name, data]. */
export type Outgoing = [string, unknown];
export type Applied = { result: MutationResult; events: Outgoing[] };

const maxLegends = 12;
const ok = (state: Partial<ElementState> = {}): ElementState => ({ exists: true, editRev: 0, tombstoned: false, parentGone: false, ...state });

/** The tracker [pageId] of the account, or null when it is gone (or not the account's). */
async function ownPage(tx: Tx, userId: string, pageId: string) {
  const [page] = await tx.select().from(pages).where(and(eq(pages.id, pageId), eq(pages.userId, userId))).limit(1);
  return page ?? null;
}

/** The number of the last trace of [key], or null. */
async function traced(tx: Tx, userId: string, kind: 'page' | 'legend' | 'cell', key: string): Promise<number | null> {
  const [row] = await tx.select({ rev: max(deletions.rev) }).from(deletions)
    .where(and(eq(deletions.userId, userId), eq(deletions.kind, kind), eq(deletions.key, key)));
  return row?.rev ?? null;
}

/** A tracker as the events and `current` describe it (palette parsed). */
const pageBody = (page: typeof pages.$inferSelect) => ({ ...page, palette: page.palette ? JSON.parse(page.palette) : null });

export async function applyMutation(tx: Tx, userId: string, m: Mutation): Promise<Applied> {
  const d = m.data as Record<string, any>; // validated by parseMutation for its kind
  const setAside = (status: 'changed' | 'deleted', current?: unknown): Applied =>
    ({ result: status === 'changed' ? { id: m.id, status, current: current ?? null } : { id: m.id, status }, events: [] });
  const rejected = (reason: Extract<MutationResult, { status: 'rejected' }>['reason']): Applied =>
    ({ result: { id: m.id, status: 'rejected', reason }, events: [] });
  const applied = (revs: Record<string, number>, events: Outgoing[] = []): Applied =>
    ({ result: { id: m.id, status: 'applied', revs }, events });

  switch (m.kind) {
    case 'cell.set':
    case 'cell.clear': {
      const { pageId, year, month, day } = d as { pageId: string; year: number; month: number; day: number };
      const page = await ownPage(tx, userId, pageId);
      if (day > daysInMonth(month, year)) return rejected('invalid');
      const [cell] = page
        ? await tx.select().from(cells).where(and(eq(cells.pageId, pageId), eq(cells.year, year), eq(cells.month, month), eq(cells.day, day))).limit(1)
        : [];
      const tomb = cell ? null : await traced(tx, userId, 'cell', cellKey(pageId, year, month, day));
      // Clearing a day already empty (cleared elsewhere too) is what was asked.
      if (m.kind === 'cell.clear' && !cell && page) return applied({ element: tomb ?? 0 });
      const editRev = dayNumber(m.base, cell?.editRev ?? null, tomb);
      const verdict = judge(m, { exists: !!cell, editRev, tombstoned: tomb !== null, parentGone: !page });
      if (verdict !== 'apply') return setAside(verdict, cell ? { color: cell.color, comment: cell.comment } : null);
      if (!m.waited && (await lockedPageIds(userId)).has(pageId)) return rejected('locked');

      if (m.kind === 'cell.clear') {
        const gone = await tx.delete(cells)
          .where(and(eq(cells.pageId, pageId), eq(cells.year, year), eq(cells.month, month), eq(cells.day, day)))
          .returning({ day: cells.day });
        if (gone.length === 0) return applied({ element: tomb ?? 0 }); // already empty: nothing changed
        const rev = await nextRev(tx, userId);
        await trace(tx, [{ userId, kind: 'cell', key: cellKey(pageId, year, month, day), pageId, rev }]);
        await touchPageContent(tx, pageId, rev);
        return applied({ element: rev, content: rev, account: rev }, [['cell:deleted', { pageId, year, month, day }]]);
      }
      const rev = await nextRev(tx, userId);
      const comment = (d.comment as string | null | undefined) ?? null;
      const [row] = await tx.insert(cells)
        .values({ pageId, year, month, day, color: d.color, comment, updatedAt: new Date(), rev, editRev: rev })
        .onConflictDoUpdate({
          target: [cells.pageId, cells.year, cells.month, cells.day],
          set: { color: d.color, comment, updatedAt: new Date(), rev, editRev: rev },
        })
        .returning();
      await touchPageContent(tx, pageId, rev);
      return applied({ element: rev, content: rev, account: rev }, [['cell:updated', row]]);
    }

    case 'page.create': {
      const [existing] = await tx.select().from(pages).where(eq(pages.id, d.id)).limit(1);
      if (existing && existing.userId !== userId) return rejected('invalid'); // an id another account uses
      const tomb = existing ? null : await traced(tx, userId, 'page', d.id);
      const verdict = judge(m, { exists: !!existing, editRev: 0, tombstoned: tomb !== null, parentGone: false });
      if (verdict !== 'apply') return setAside(verdict);
      if (existing) return applied({ element: existing.editRev, content: existing.contentRev }); // sent again: already done
      if (!m.waited && !(await isUnlimited(userId))) {
        const [{ n }] = await tx.select({ n: count() }).from(pages).where(eq(pages.userId, userId));
        if (Number(n) >= maxFreeTrackers) return rejected('tracker_limit');
      }
      const rev = await nextRev(tx, userId);
      const [{ last }] = await tx.select({ last: max(pages.position) }).from(pages).where(eq(pages.userId, userId));
      const [page] = await tx.insert(pages).values({
        id: d.id, userId, title: d.title, position: (last ?? -1) + 1,
        palette: d.palette ? JSON.stringify(d.palette) : null,
        rev, editRev: rev, contentRev: rev,
      }).returning();
      const inputs = (d.legends ?? []) as { id: string; color: string; label: string }[];
      const created = inputs.length === 0 ? [] : await tx.insert(legends)
        .values(inputs.map((l, i) => ({ id: l.id, pageId: page.id, color: l.color, label: l.label, position: i, rev, editRev: rev })))
        .returning();
      return applied({ element: rev, content: rev, account: rev }, [
        ['page:created', { ...pageBody(page), legends: created }],
        ...created.map((l): Outgoing => ['legend:created', l]),
      ]);
    }

    case 'page.update':
    case 'page.delete': {
      const page = await ownPage(tx, userId, d.id);
      const tomb = page ? null : await traced(tx, userId, 'page', d.id);
      // Deleting a tracker already gone is what was asked: nothing to tell.
      if (m.kind === 'page.delete' && !page) return applied({ element: tomb ?? 0 });
      // A deletion compares the whole tracker with its content (H21).
      const number = m.kind === 'page.delete' ? page?.contentRev : page?.editRev;
      const verdict = judge(m, { exists: !!page, editRev: number ?? 0, tombstoned: tomb !== null, parentGone: false });
      if (verdict !== 'apply') return setAside(verdict, page ? { title: page.title } : null);
      const rev = await nextRev(tx, userId);
      if (m.kind === 'page.delete') {
        await tx.delete(pages).where(eq(pages.id, d.id));
        await trace(tx, [{ userId, kind: 'page', key: d.id, pageId: d.id, rev }]);
        return applied({ element: rev, account: rev }, [['page:deleted', { id: d.id }]]);
      }
      const set: Record<string, unknown> = { rev, editRev: rev, contentRev: rev };
      if (d.title !== undefined) set.title = d.title;
      if (d.palette !== undefined) set.palette = d.palette === null ? null : JSON.stringify(d.palette);
      const [row] = await tx.update(pages).set(set).where(eq(pages.id, d.id)).returning();
      return applied({ element: rev, content: rev, account: rev }, [['page:updated', pageBody(row)]]);
    }

    case 'pages.reorder':
    case 'pages.keep': {
      const [account] = await tx.select({ pagesOrderRev: users.pagesOrderRev, keepFreeRev: users.keepFreeRev }).from(users).where(eq(users.id, userId)).limit(1);
      const own = await tx.select({ id: pages.id, keepFree: pages.keepFree }).from(pages).where(eq(pages.userId, userId)).orderBy(asc(pages.position), asc(pages.createdAt));
      const reorder = m.kind === 'pages.reorder';
      const verdict = judge(m, ok({ editRev: reorder ? account.pagesOrderRev : account.keepFreeRev }));
      if (verdict !== 'apply') {
        return setAside(verdict, reorder ? own.map((p) => p.id) : own.filter((p) => p.keepFree).map((p) => p.id));
      }
      const rev = await nextRev(tx, userId);
      if (reorder) {
        const order = mergeOrder(d.ids, own.map((p) => p.id));
        for (let i = 0; i < order.length; i++) await tx.update(pages).set({ position: i }).where(eq(pages.id, order[i]));
        await tx.update(users).set({ pagesOrderRev: rev }).where(eq(users.id, userId));
        return applied({ element: rev, account: rev }, [['pages:reordered', { ids: order }]]);
      }
      const ids = (d.ids as string[]).filter((id) => own.some((p) => p.id === id));
      await tx.update(pages).set({ keepFree: false }).where(eq(pages.userId, userId));
      if (ids.length > 0) await tx.update(pages).set({ keepFree: true }).where(and(eq(pages.userId, userId), inArray(pages.id, ids)));
      await tx.update(users).set({ keepFreeRev: rev }).where(eq(users.id, userId));
      return applied({ element: rev, account: rev }, [['pages:kept', { ids }]]);
    }

    case 'legend.create': {
      const page = await ownPage(tx, userId, d.pageId);
      const [existing] = await tx.select().from(legends).where(eq(legends.id, d.id)).limit(1);
      if (existing && existing.pageId !== d.pageId) return rejected('invalid');
      const tomb = existing ? null : await traced(tx, userId, 'legend', d.id);
      const verdict = judge(m, { exists: !!existing, editRev: 0, tombstoned: tomb !== null, parentGone: !page });
      if (verdict !== 'apply') return setAside(verdict);
      if (existing) return applied({ element: existing.editRev });
      const [{ n }] = await tx.select({ n: count() }).from(legends).where(eq(legends.pageId, d.pageId));
      if (Number(n) >= maxLegends) return rejected('legend_limit'); // H12, waited or not
      const rev = await nextRev(tx, userId);
      const [{ last }] = await tx.select({ last: max(legends.position) }).from(legends).where(eq(legends.pageId, d.pageId));
      const [row] = await tx.insert(legends)
        .values({ id: d.id, pageId: d.pageId, color: d.color, label: d.label, position: (last ?? -1) + 1, rev, editRev: rev })
        .returning();
      await touchPageContent(tx, d.pageId, rev);
      return applied({ element: rev, content: rev, account: rev }, [['legend:created', row]]);
    }

    case 'legend.update':
    case 'legend.delete': {
      const [legend] = await tx.select().from(legends).where(eq(legends.id, d.id)).limit(1);
      const page = legend ? await ownPage(tx, userId, legend.pageId) : null;
      if (legend && !page) return rejected('not_found'); // another account's legend
      const tomb = legend ? null : await traced(tx, userId, 'legend', d.id);
      if (m.kind === 'legend.delete' && !legend) return applied({ element: tomb ?? 0 }); // already gone: nothing to tell
      const verdict = judge(m, { exists: !!legend, editRev: legend?.editRev ?? 0, tombstoned: tomb !== null, parentGone: false });
      if (verdict !== 'apply') return setAside(verdict, legend ? { label: legend.label, color: legend.color } : null);
      const rev = await nextRev(tx, userId);
      if (m.kind === 'legend.delete') {
        await tx.delete(legends).where(eq(legends.id, d.id));
        await trace(tx, [{ userId, kind: 'legend', key: d.id, pageId: legend!.pageId, rev }]);
        await touchPageContent(tx, legend!.pageId, rev);
        return applied({ element: rev, content: rev, account: rev }, [['legend:deleted', { id: d.id, pageId: legend!.pageId }]]);
      }
      const events: Outgoing[] = [];
      const recolour = d.color !== undefined && d.color !== legend!.color;
      if (recolour) {
        // The legend's days take the new colour without being edited: their
        // changes made offline elsewhere are kept (H29). Their `rev` moves,
        // so the other phones receive the new colour.
        await tx.update(cells).set({ color: d.color, rev })
          .where(and(eq(cells.pageId, legend!.pageId), eq(cells.color, legend!.color)));
        events.push(['cells:recolored', { pageId: legend!.pageId, colorMap: { [legend!.color]: d.color } }]);
      }
      const set: Record<string, unknown> = { rev, editRev: rev };
      if (d.label !== undefined) set.label = d.label;
      if (d.color !== undefined) set.color = d.color;
      const [row] = await tx.update(legends).set(set).where(eq(legends.id, d.id)).returning();
      await touchPageContent(tx, legend!.pageId, rev);
      return applied({ element: rev, content: rev, account: rev }, [['legend:updated', row], ...events]);
    }

    case 'legends.reorder': {
      const page = await ownPage(tx, userId, d.pageId);
      const own = page ? await tx.select({ id: legends.id }).from(legends).where(eq(legends.pageId, d.pageId)).orderBy(asc(legends.position)) : [];
      const verdict = judge(m, ok({ editRev: page?.legendsOrderRev ?? 0, parentGone: !page }));
      if (verdict !== 'apply') return setAside(verdict, own.map((l) => l.id));
      const rev = await nextRev(tx, userId);
      const order = mergeOrder(d.ids, own.map((l) => l.id));
      for (let i = 0; i < order.length; i++) await tx.update(legends).set({ position: i }).where(eq(legends.id, order[i]));
      await tx.update(pages).set({ legendsOrderRev: rev }).where(eq(pages.id, d.pageId));
      await touchPageContent(tx, d.pageId, rev);
      return applied({ element: rev, content: rev, account: rev }, [['legends:reordered', { pageId: d.pageId, ids: order }]]);
    }

    case 'setting.set': {
      const [account] = await tx.select().from(users).where(eq(users.id, userId)).limit(1);
      const key = d.key as 'theme' | 'language' | 'cursor';
      const number = key === 'theme' ? account.themeRev : key === 'language' ? account.languageRev : account.cursorRev;
      const current = key === 'theme' ? account.theme : key === 'language' ? account.language : { id: account.cursorId, enabled: account.cursorEnabled };
      const verdict = judge(m, ok({ editRev: number }));
      if (verdict !== 'apply') return setAside(verdict, current);
      const rev = await nextRev(tx, userId);
      const set: Record<string, unknown> =
        key === 'theme' ? { theme: d.value, themeRev: rev }
        : key === 'language' ? { language: d.value, languageRev: rev }
        : { cursorId: d.value.id, cursorEnabled: d.value.enabled, cursorRev: rev };
      await tx.update(users).set(set).where(eq(users.id, userId));
      return applied({ element: rev, account: rev });
    }
  }
}

// Used by the sync route to read a phone's account number without a write.
export async function accountRev(tx: Tx, userId: string): Promise<number> {
  const [row] = await tx.select({ rev: users.rev }).from(users).where(eq(users.id, userId)).limit(1);
  return row?.rev ?? 0;
}

