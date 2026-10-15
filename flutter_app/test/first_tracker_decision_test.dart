import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/first_tracker_decision.dart';
import 'package:dian_dian/models/legend_model.dart';
import 'package:dian_dian/models/page_model.dart';

PageModel page(String id, int position) =>
    PageModel(id: id, userId: 'u1', title: id, year: 2026, position: position, createdAt: '');

LegendModel legend(String pageId) =>
    LegendModel(id: 'l-$pageId', pageId: pageId, color: '#000000', label: 'x', position: 0, createdAt: '');

void main() {
  group('shouldShowFirstTracker', () {
    bool show({bool? activated = false, bool done = false, int pages = 0, int max = 3, bool replaceable = false}) =>
        shouldShowFirstTracker(
          activated: activated,
          doneOnThisDevice: done,
          pageCount: pages,
          maxTrackers: max,
          hasReplaceablePage: replaceable,
        );

    test('only on a confirmed "no cell at all"', () {
      expect(show(activated: null), isFalse, reason: 'offline, or backend < 1.2.0');
      expect(show(activated: true), isFalse);
      expect(show(activated: false), isTrue);
    });

    test('never twice on the same device for the same account', () {
      expect(show(done: true), isFalse);
    });

    test('respects the free limit unless an empty page can be replaced', () {
      expect(show(pages: 3, max: 3), isFalse, reason: 'would create a locked 4th tracker');
      expect(show(pages: 3, max: 3, replaceable: true), isTrue);
      expect(show(pages: 2, max: 3), isTrue);
      expect(show(pages: 3, max: 999), isTrue, reason: 'premium');
    });
  });

  group('replaceablePageId', () {
    test('first page by position without legends', () {
      final pages = [page('b', 1), page('a', 0), page('c', 2)];
      expect(replaceablePageId(pages, (id) => id == 'a' ? [legend('a')] : const []), 'b');
    });

    test('null when every page has legends or there is no page', () {
      expect(replaceablePageId([page('a', 0)], (id) => [legend(id)]), isNull);
      expect(replaceablePageId(const [], (_) => const []), isNull);
    });
  });
}
