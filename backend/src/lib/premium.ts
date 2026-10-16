import { and, eq, sql } from 'drizzle-orm';
import { db } from '../db/index.js';
import { cells, pages, subscriptions, users } from '../db/schema.js';
import { lockedPageIdsFor } from './trackerLock.js';

/** Free accounts own at most this many trackers (the app shows the same number). */
export const maxFreeTrackers = 3;

export async function hasActiveSubscription(userId: string): Promise<boolean> {
  const [sub] = await db.select()
    .from(subscriptions)
    .where(and(eq(subscriptions.userId, userId), eq(subscriptions.active, true)))
    .limit(1);
  if (!sub) return false;
  if (sub.expiresAt && sub.expiresAt < new Date()) return false;
  return true;
}

/** VIP (manual flag, never counted as a customer) or an active subscription: no free-tier limits. */
export async function isUnlimited(userId: string): Promise<boolean> {
  const [u] = await db.select({ vip: users.vip }).from(users).where(eq(users.id, userId)).limit(1);
  if (u?.vip) return true;
  return hasActiveSubscription(userId);
}

export type PageActivity = { recentCells: number; lastCellAt: Date | null };

/** Per page, all years: cells touched in the last 90 days and the last cell date. */
export async function pageActivity(userId: string): Promise<Map<string, PageActivity>> {
  const rows = await db.select({
    pageId: cells.pageId,
    recent: sql<number>`count(*) filter (where ${cells.updatedAt} > now() - interval '90 days')`,
    last: sql<Date | string | null>`max(${cells.updatedAt})`,
  })
    .from(cells)
    .innerJoin(pages, eq(pages.id, cells.pageId))
    .where(eq(pages.userId, userId))
    .groupBy(cells.pageId);
  return new Map(rows.map((r) => [r.pageId, {
    recentCells: Number(r.recent ?? 0),
    lastCellAt: r.last ? new Date(r.last) : null,
  }]));
}

/**
 * Pages the free tier locks for this account (empty for VIP / subscribers
 * and for accounts at or under the limit — the common case, one query).
 */
export async function lockedPageIds(userId: string): Promise<Set<string>> {
  const rows = await db.select({ id: pages.id, createdAt: pages.createdAt, keepFree: pages.keepFree })
    .from(pages)
    .where(eq(pages.userId, userId));
  if (rows.length <= maxFreeTrackers) return new Set();
  if (await isUnlimited(userId)) return new Set();
  const activity = await pageActivity(userId);
  return lockedPageIdsFor(rows.map((r) => ({
    id: r.id,
    createdAt: r.createdAt,
    keepFree: r.keepFree,
    recentCells: activity.get(r.id)?.recentCells ?? 0,
    lastCellAt: activity.get(r.id)?.lastCellAt ?? null,
  })), maxFreeTrackers);
}
