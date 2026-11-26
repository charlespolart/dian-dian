/**
 * How long measurement rows are kept (docs/REGISTRE.md, fiches 4 and 7, and
 * the privacy policy): 13 months at most for product events, and for
 * purchase events that name no account. Rows that belong to an account are
 * not this module's business: they go with the account.
 */
import { and, isNull, lt } from 'drizzle-orm';
import type { db as database } from '../db/index.js';
import { events, subscriptionEvents } from '../db/schema.js';

type Db = typeof database;

/** Product events (`events`): the current month and the 12 before it. */
export const EVENTS_MONTHS = 13;
/**
 * Purchase events with no account (`subscription_events.user_id` null: the
 * account was deleted, the purchase came under an anonymous id, or it was a
 * test event): the same, counted from when they were received.
 */
export const UNLINKED_PURCHASE_EVENTS_MONTHS = 13;
/**
 * How often the purge runs: hourly, so a row outlives its limit by an hour
 * at most, and a run that failed (the database down at boot) is tried again
 * within the hour.
 */
export const RETENTION_PURGE_EVERY_MS = 60 * 60 * 1000;

/**
 * The first instant kept: the start (UTC) of the month `months - 1` months
 * before the month of `now`. That month and the later ones stay, so at least
 * `months - 1` months are kept and nothing kept is older than `months`.
 */
export function keptSince(now: Date, months: number): Date {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - (months - 1), 1));
}

/**
 * Deletes the product events created before their limit, and the purchase
 * events with no account received before theirs. A purchase event of an
 * account is never deleted here, whatever its age. Returns how many rows of
 * each went.
 */
export async function purgeOldRows(db: Db, now: Date): Promise<{ events: number; purchaseEvents: number }> {
  const oldEvents = await db.delete(events).where(lt(events.createdAt, keptSince(now, EVENTS_MONTHS)));
  const oldPurchaseEvents = await db.delete(subscriptionEvents).where(and(
    isNull(subscriptionEvents.userId),
    lt(subscriptionEvents.receivedAt, keptSince(now, UNLINKED_PURCHASE_EVENTS_MONTHS)),
  ));
  return { events: oldEvents.count, purchaseEvents: oldPurchaseEvents.count };
}

/**
 * `purgeOldRows`, for a timer: a failure is logged and never thrown (the
 * next run tries again), and a run that deleted rows says how many — two
 * numbers, nothing that names anyone.
 */
export async function runRetentionPurge(db: Db, now: Date, log: Pick<Console, 'log' | 'error'> = console): Promise<void> {
  try {
    const purged = await purgeOldRows(db, now);
    if (purged.events + purged.purchaseEvents > 0) {
      log.log(`Retention purge: ${purged.events} product events and ${purged.purchaseEvents} purchase events without account deleted`);
    }
  } catch (err) {
    log.error('Retention purge failed:', err);
  }
}
