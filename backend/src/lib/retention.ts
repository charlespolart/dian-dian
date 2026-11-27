/**
 * How long measurement and sync rows are kept (docs/REGISTRE.md): product
 * events 13 months at most, purchase events that name no account the same;
 * offline sync's answers to changes 90 days, its deletion traces 24 months.
 * Rows that belong to an account otherwise go with the account.
 */
import { and, eq, isNull, lt, max } from 'drizzle-orm';
import type { db as database } from '../db/index.js';
import { deletions, endedSessions, events, subscriptionEvents, syncMutations, users, deletedAccounts } from '../db/schema.js';

type Db = typeof database;

/** Product events (`events`): the current month and the 12 before it. */
export const EVENTS_MONTHS = 13;
/**
 * Purchase events with no account (`subscription_events.user_id` null: the
 * account was deleted, the purchase came under an anonymous id, or it was a
 * test event): the same, counted from when they were received.
 */
export const UNLINKED_PURCHASE_EVENTS_MONTHS = 13;
/** Offline sync: the answers to changes a phone sent (a resend older than this is judged afresh). */
export const SYNC_ANSWERS_DAYS = 90;
/** Offline sync: deletion traces, as long as the memory of deleted accounts. */
export const DELETION_TRACES_MONTHS = 24;
/** Ended sessions are remembered as long as a session lasts (routes/auth.ts, SESSION_DAYS). */
export const ENDED_SESSIONS_DAYS = 548;
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
export async function purgeOldRows(db: Db, now: Date): Promise<{ events: number; purchaseEvents: number; syncMutations: number; deletions: number; endedSessions: number; deletedAccounts: number }> {
  const oldEvents = await db.delete(events).where(lt(events.createdAt, keptSince(now, EVENTS_MONTHS)));
  const oldPurchaseEvents = await db.delete(subscriptionEvents).where(and(
    isNull(subscriptionEvents.userId),
    lt(subscriptionEvents.receivedAt, keptSince(now, UNLINKED_PURCHASE_EVENTS_MONTHS)),
  ));
  const oldAnswers = await db.delete(syncMutations)
    .where(lt(syncMutations.createdAt, new Date(now.getTime() - SYNC_ANSWERS_DAYS * 24 * 60 * 60 * 1000)));
  // Before forgetting traces, each account remembers the highest number it
  // forgets: a phone that last synced below it may have missed a deletion,
  // and gets the full copy (routes/sync.ts).
  const traceLimit = keptSince(now, DELETION_TRACES_MONTHS);
  const oldTraces = await db.transaction(async (tx) => {
    const floors = await tx.select({ userId: deletions.userId, rev: max(deletions.rev) }).from(deletions)
      .where(lt(deletions.deletedAt, traceLimit)).groupBy(deletions.userId);
    for (const floor of floors) {
      if (floor.rev !== null) await tx.update(users).set({ syncFloorRev: floor.rev }).where(eq(users.id, floor.userId));
    }
    return tx.delete(deletions).where(lt(deletions.deletedAt, traceLimit));
  });
  const oldEnded = await db.delete(endedSessions)
    .where(lt(endedSessions.endedAt, new Date(now.getTime() - ENDED_SESSIONS_DAYS * 24 * 60 * 60 * 1000)));
  // Deleted accounts are remembered as long as deletion traces (chantier 9).
  const oldDeleted = await db.delete(deletedAccounts).where(lt(deletedAccounts.at, traceLimit));
  return {
    events: oldEvents.count, purchaseEvents: oldPurchaseEvents.count, syncMutations: oldAnswers.count, deletions: oldTraces.count,
    endedSessions: oldEnded.count, deletedAccounts: oldDeleted.count,
  };
}

/**
 * `purgeOldRows`, for a timer: a failure is logged and never thrown (the
 * next run tries again), and a run that deleted rows says how many — two
 * numbers, nothing that names anyone.
 */
export async function runRetentionPurge(db: Db, now: Date, log: Pick<Console, 'log' | 'error'> = console): Promise<void> {
  try {
    const purged = await purgeOldRows(db, now);
    if (purged.events + purged.purchaseEvents + purged.syncMutations + purged.deletions + purged.endedSessions + purged.deletedAccounts > 0) {
      log.log(`Retention purge: ${purged.events} product events, ${purged.purchaseEvents} purchase events without account, ${purged.syncMutations} sync answers, ${purged.deletions} deletion traces, ${purged.endedSessions} ended sessions, ${purged.deletedAccounts} remembered deleted accounts deleted`);
    }
  } catch (err) {
    log.error('Retention purge failed:', err);
  }
}
