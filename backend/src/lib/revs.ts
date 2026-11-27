/**
 * Version numbers for offline sync (chantier 10,
 * docs/superpowers/specs/2026-11-26-offline-sync-design.md).
 *
 * Each account has a counter (`users.rev`). Every write of its data, through
 * today's routes (apps 1.4.0) or the sync routes, takes the next number in
 * its transaction and stamps it on what it changed: a phone that comes back
 * asks for everything above the last number it saw, and a change that waited
 * is compared with the number of its element ("the server wins").
 *
 * Taking the number updates the account's row, which locks it until the
 * transaction ends: the writes of one account are numbered one at a time.
 */
import { eq, sql } from 'drizzle-orm';
import type { db as database } from '../db/index.js';
import { deletions, pages, users } from '../db/schema.js';

/** A transaction of the database (every numbered write runs in one). */
export type Tx = Parameters<Parameters<typeof database.transaction>[0]>[0];

/** The account's next number, taken inside [tx]. */
export async function nextRev(tx: Tx, userId: string): Promise<number> {
  const [row] = await tx.update(users)
    .set({ rev: sql`${users.rev} + 1` })
    .where(eq(users.id, userId))
    .returning({ rev: users.rev });
  if (!row) throw new Error('nextRev: no such account');
  return row.rev;
}

/** How a day is named in the deletion traces: `pageId:yyyy-mm-dd`. */
export function cellKey(pageId: string, year: number, month: number, day: number): string {
  const two = (n: number) => String(n).padStart(2, '0');
  return `${pageId}:${year}-${two(month)}-${two(day)}`;
}

/** Something of the tracker [pageId] changed under number [rev]: its content number, and its row. */
export async function touchPageContent(tx: Tx, pageId: string, rev: number): Promise<void> {
  await tx.update(pages).set({ contentRev: rev, rev }).where(eq(pages.id, pageId));
}

/** Leaves the trace of a deletion: a phone that comes back learns it. */
export async function trace(
  tx: Tx,
  entries: { userId: string; kind: 'page' | 'legend' | 'cell'; key: string; pageId: string | null; rev: number }[],
): Promise<void> {
  if (entries.length === 0) return;
  await tx.insert(deletions).values(entries);
}
