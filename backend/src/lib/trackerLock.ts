/** The fields the free-tier lock needs; mirrors `lib/data/tracker_lock.dart` in the app. */
export type LockablePage = {
  id: string;
  createdAt: Date;
  keepFree: boolean;
  recentCells: number;
  lastCellAt: Date | null;
};

/** Most active first: cells touched in the last 90 days, then last cell date, then age (older first). */
export function mostActive(pages: LockablePage[]): LockablePage[] {
  return [...pages].sort((a, b) =>
    b.recentCells - a.recentCells
    || (b.lastCellAt?.getTime() ?? 0) - (a.lastCellAt?.getTime() ?? 0)
    || a.createdAt.getTime() - b.createdAt.getTime());
}

/**
 * Ids of the pages locked by the free tier: nothing at or under `max`;
 * otherwise the user's kept pages (oldest first, at most `max`) completed
 * by the most active stay open, the rest is locked. The app computes the
 * same set, so what it shows closed is what the server refuses to write.
 */
export function lockedPageIdsFor(pages: LockablePage[], max: number): Set<string> {
  if (pages.length <= max) return new Set();
  const kept = pages.filter((p) => p.keepFree).sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
  const open = new Set(kept.slice(0, max).map((p) => p.id));
  for (const p of mostActive(pages)) {
    if (open.size >= max) break;
    open.add(p.id);
  }
  return new Set(pages.filter((p) => !open.has(p.id)).map((p) => p.id));
}
