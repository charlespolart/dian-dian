import '../models/page_model.dart';

/// Trackers from the most to the least active: cells touched in the last
/// 90 days, then the last cell date, then age (older first) as a tie-break
/// so the order is stable.
List<PageModel> mostActiveTrackers(List<PageModel> pages) {
  final sorted = [...pages]..sort((a, b) {
      final byRecent = b.recentCells.compareTo(a.recentCells);
      if (byRecent != 0) return byRecent;
      final byLast = (b.lastCellAt ?? '').compareTo(a.lastCellAt ?? '');
      if (byLast != 0) return byLast;
      return a.createdAt.compareTo(b.createdAt);
    });
  return sorted;
}

/// Whether the user chose which trackers stay open (`keepFree` on any page).
bool hasKeepChoice(List<PageModel> pages) => pages.any((p) => p.keepFree);

/// Ids of the trackers locked by the free tier.
///
/// Nothing is locked for a premium account or at or under [maxTrackers].
/// Otherwise the open ones are the user's kept trackers (`keepFree`),
/// completed by the most active when fewer were kept, trimmed to the oldest
/// kept when more were (a stale choice); the rest is locked. The server
/// agrees: a page is never deleted, only closed until Premium or a new choice.
Set<String> lockedTrackerIdsFor(
  List<PageModel> pages, {
  required bool premium,
  required int maxTrackers,
}) {
  if (premium || pages.length <= maxTrackers) return const <String>{};
  final kept = pages.where((p) => p.keepFree).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final open = <String>{for (final p in kept.take(maxTrackers)) p.id};
  for (final p in mostActiveTrackers(pages)) {
    if (open.length >= maxTrackers) break;
    open.add(p.id);
  }
  return {for (final p in pages) if (!open.contains(p.id)) p.id};
}
