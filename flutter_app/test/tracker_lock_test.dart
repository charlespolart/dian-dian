import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/tracker_lock.dart';
import 'package:dian_dian/models/page_model.dart';

PageModel page(String id, {String createdAt = '2026-01-01', int recent = 0, String? last, bool keep = false}) =>
    PageModel(
      id: id, userId: 'u1', title: id, year: 2026, position: 0, createdAt: createdAt,
      recentCells: recent, lastCellAt: last, keepFree: keep,
    );

void main() {
  group('mostActiveTrackers', () {
    test('ranks by cells in the last 90 days, then last cell date, then age', () {
      final pages = [
        page('idle', createdAt: '2025-01-01'),
        page('busy', recent: 40, last: '2026-10-10'),
        page('fresh', recent: 5, last: '2026-10-15'),
        page('stale', recent: 5, last: '2026-06-01'),
        page('older-idle', createdAt: '2024-01-01'),
      ];
      expect(mostActiveTrackers(pages).map((p) => p.id), ['busy', 'fresh', 'stale', 'older-idle', 'idle']);
    });
  });

  group('lockedTrackerIdsFor', () {
    test('nothing locked for premium, or at or under the limit', () {
      final four = [page('a'), page('b'), page('c'), page('d')];
      expect(lockedTrackerIdsFor(four, premium: true, maxTrackers: 3), isEmpty);
      expect(lockedTrackerIdsFor(four.take(3).toList(), premium: false, maxTrackers: 3), isEmpty);
    });

    test('without a choice, the most active trackers stay open', () {
      final pages = [
        page('a', recent: 1, last: '2026-09-01'),
        page('b'),
        page('c', recent: 30, last: '2026-10-15'),
        page('d', recent: 2, last: '2026-10-01'),
        page('e', recent: 0),
      ];
      expect(lockedTrackerIdsFor(pages, premium: false, maxTrackers: 3), {'b', 'e'});
    });

    test('the user\'s kept trackers win over activity', () {
      final pages = [
        page('a', recent: 99, last: '2026-10-15'),
        page('b', keep: true),
        page('c', keep: true),
        page('d', recent: 50, last: '2026-10-14'),
        page('e', keep: true),
      ];
      expect(lockedTrackerIdsFor(pages, premium: false, maxTrackers: 3), {'a', 'd'});
    });

    test('fewer kept than the limit: the rest is filled by activity', () {
      final pages = [
        page('a', recent: 9, last: '2026-10-15'),
        page('b', keep: true),
        page('c', recent: 1, last: '2026-01-01'),
        page('d'),
      ];
      expect(lockedTrackerIdsFor(pages, premium: false, maxTrackers: 3), {'d'});
    });

    test('more kept than the limit (stale choice): the oldest kept stay', () {
      final pages = [
        page('a', createdAt: '2026-03-01', keep: true),
        page('b', createdAt: '2026-01-01', keep: true),
        page('c', createdAt: '2026-02-01', keep: true),
        page('d', createdAt: '2026-04-01', keep: true),
        page('e'),
      ];
      expect(lockedTrackerIdsFor(pages, premium: false, maxTrackers: 3), {'d', 'e'});
    });

    test('hasKeepChoice says whether the user chose', () {
      expect(hasKeepChoice([page('a'), page('b', keep: true)]), isTrue);
      expect(hasKeepChoice([page('a'), page('b')]), isFalse);
    });
  });
}
