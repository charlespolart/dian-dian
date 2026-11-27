/**
 * The weekly measure of offline sync (spec, "Mesure"): counts only, no
 * account. Kinds: syncs_with_waited, mutations_waited, set_aside_changed,
 * set_aside_deleted, rejected_<reason>. Read by scripts/prod-sync.sql.
 */
import { sql } from 'drizzle-orm';
import { db } from '../db/index.js';
import { syncStats } from '../db/schema.js';
import type { MutationResult } from '../sync/mutations.js';

/** The Monday (UTC) of the week of [now], as yyyy-mm-dd. */
export function weekOf(now: Date): string {
  const day = (now.getUTCDay() + 6) % 7; // Monday = 0
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - day)).toISOString().slice(0, 10);
}

/** What one batch adds to its week. A batch with no change that waited counts nothing. */
export function syncBatchCounts(waited: number, results: MutationResult[]): Record<string, number> {
  if (waited === 0) return {};
  const counts: Record<string, number> = { syncs_with_waited: 1, mutations_waited: waited };
  for (const r of results) {
    const kind = r.status === 'changed' ? 'set_aside_changed'
      : r.status === 'deleted' ? 'set_aside_deleted'
      : r.status === 'rejected' ? `rejected_${r.reason}` : null;
    if (kind) counts[kind] = (counts[kind] ?? 0) + 1;
  }
  return counts;
}

export async function recordSyncBatch(now: Date, waited: number, results: MutationResult[]): Promise<void> {
  const counts = Object.entries(syncBatchCounts(waited, results));
  if (counts.length === 0) return;
  const week = weekOf(now);
  await db.insert(syncStats)
    .values(counts.map(([kind, count]) => ({ week, kind, count })))
    .onConflictDoUpdate({ target: [syncStats.week, syncStats.kind], set: { count: sql`${syncStats.count} + excluded.count` } });
}
