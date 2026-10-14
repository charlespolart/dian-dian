import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/services/ws_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CellsProvider loaded() {
    final p = CellsProvider();
    p.applyBootstrap(2026, {
      'a': [
        [1, 1, '#AAAAAA'],
        [1, 2, '#BBBBBB', 'hi'],
      ],
      'b': <dynamic>[],
    });
    return p;
  }

  test('applyBootstrap loads every page and marks the year loaded', () {
    final p = loaded();
    expect(p.isYearLoaded(2026), isTrue);
    expect(p.isYearLoaded(2025), isFalse);
    expect(p.cellsFor('a', 2026)!.length, 2);
    expect(p.cellsFor('b', 2026)!.isEmpty, isTrue);
    expect(p.cellsFor('a', 2025), isNull);
  });

  test('applyBootstrap replaces the year wholesale (a page removed server-side disappears)', () {
    final p = loaded();
    p.applyBootstrap(2026, {'b': [[5, 5, '#CCCCCC']]});
    expect(p.cellsFor('a', 2026), isNull);
    expect(p.cellsFor('b', 2026)!.length, 1);
  });

  test('setContext is synchronous and exposes the current cells', () {
    final p = loaded();
    var notified = 0;
    p.addListener(() => notified++);
    p.setContext(pageId: 'a', year: 2026);
    expect(notified, 1);
    expect(p.currentPageId, 'a');
    expect(p.currentYear, 2026);
    expect(p.getCell(1, 2)?.comment, 'hi');
    expect(p.getCellColor(1, 1), '#AAAAAA');
    expect(p.getCellColor(9, 9), isNull);
    expect(p.cells.length, 2);
    expect(p.filledDays, 2);
  });

  test('setYear switches the current year without fetching', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    p.setYear(2025);
    expect(p.currentYear, 2025);
    expect(p.current, isNull);
    expect(p.filledDays, 0);
    expect(p.currentStreak, 0);
    p.setYear(2026);
    expect(p.filledDays, 2);
  });

  test('currentStreak counts consecutive days ending today or yesterday', () {
    final p = CellsProvider();
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final days = [d0, d0.subtract(const Duration(days: 1)), d0.subtract(const Duration(days: 2))]
        .where((d) => d.year == now.year)
        .toList();
    p.applyBootstrap(now.year, {
      'a': [for (final d in days) [d.month, d.day, '#AAAAAA']],
    });
    p.setContext(pageId: 'a', year: now.year);
    expect(p.currentStreak, days.length);

    // Gap before the run → streak unaffected by the earlier day.
    final far = d0.subtract(const Duration(days: 10));
    if (far.year == now.year) {
      p.applyBootstrap(now.year, {
        'a': [for (final d in days) [d.month, d.day, '#AAAAAA'], [far.month, far.day, '#AAAAAA']],
      });
      expect(p.currentStreak, days.length);
    }
  });

  test('stats are memoized per YearCells instance', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    expect(p.filledDays, 2);
    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
    }));
    expect(p.filledDays, 3);
  });

  test('WS cell:updated applies only to loaded years', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    var notified = 0;
    p.addListener(() => notified++);

    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
    }));
    expect(p.getCell(3, 3)?.color, '#CCCCCC');
    expect(notified, 1);

    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2025, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
    }));
    expect(p.cellsFor('a', 2025), isNull);
    expect(notified, 1);
  });

  test('WS cell:updated for a page unknown to this year creates its entry', () {
    final p = loaded();
    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'new-page', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
    }));
    expect(p.cellsFor('new-page', 2026)!.length, 1);
  });

  test('WS cell:deleted and cells:reset', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    p.debugHandleWs(const WsMessage(event: 'cell:deleted', data: {
      'pageId': 'a', 'year': 2026, 'month': 1, 'day': 1,
    }));
    expect(p.getCell(1, 1), isNull);
    expect(p.filledDays, 1);
    p.debugHandleWs(const WsMessage(event: 'cells:reset', data: {'pageId': 'a', 'year': 2026}));
    expect(p.filledDays, 0);
    expect(p.cellsFor('a', 2026)!.isEmpty, isTrue);
  });

  test('WS cells:recolored recolors every cached year of the page without refetch', () {
    final p = loaded();
    p.applyBootstrap(2025, {'a': [[5, 5, '#AAAAAA']], 'b': <dynamic>[]});
    p.debugHandleWs(const WsMessage(event: 'cells:recolored', data: {
      'pageId': 'a', 'colorMap': {'#AAAAAA': '#111111'},
    }));
    expect(p.cellsFor('a', 2026)!.get(1, 1)!.color, '#111111');
    expect(p.cellsFor('a', 2025)!.get(5, 5)!.color, '#111111');
    expect(p.cellsFor('a', 2026)!.get(1, 2)!.color, '#BBBBBB');
  });

  test('identity only changes for the touched (page, year)', () {
    final p = loaded();
    final a = p.cellsFor('a', 2026);
    final b = p.cellsFor('b', 2026);
    p.debugHandleWs(const WsMessage(event: 'cell:deleted', data: {
      'pageId': 'a', 'year': 2026, 'month': 1, 'day': 1,
    }));
    expect(identical(p.cellsFor('a', 2026), a), isFalse);
    expect(identical(p.cellsFor('b', 2026), b), isTrue);
  });

  test('clear forgets everything', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    p.clear();
    expect(p.isYearLoaded(2026), isFalse);
    expect(p.cellsFor('a', 2026), isNull);
    expect(p.currentPageId, isNull);
    expect(p.cells, isEmpty);
  });
}
