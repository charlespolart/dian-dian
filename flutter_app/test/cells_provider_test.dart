import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/ws_service.dart';

import 'helpers.dart';

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

  test('mutationEpoch increments on local/WS changes, not on applyBootstrap', () {
    final p = loaded();
    final e0 = p.mutationEpoch;
    p.applyBootstrap(2025, {'a': <dynamic>[]});
    expect(p.mutationEpoch, e0);
    p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
    }));
    expect(p.mutationEpoch, e0 + 1);
    p.debugHandleWs(const WsMessage(event: 'cells:recolored', data: {
      'pageId': 'a', 'colorMap': {'#CCCCCC': '#DDDDDD'},
    }));
    expect(p.mutationEpoch, e0 + 2);
  });

  test('recolorCells reverts every cached year when the server rejects it', () async {
    final client = MockClient((req) async => http.Response('{"error":"nope"}', 500));
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    final p = CellsProvider(api: api, audio: AudioService.silent());
    p.applyBootstrap(2026, {'a': [[1, 1, '#AAAAAA']]});
    p.applyBootstrap(2025, {'a': [[2, 2, '#AAAAAA']]});
    p.setContext(pageId: 'a', year: 2026);
    await p.recolorCells({'#AAAAAA': '#111111'});
    expect(p.cellsFor('a', 2026)!.get(1, 1)!.color, '#AAAAAA');
    expect(p.cellsFor('a', 2025)!.get(2, 2)!.color, '#AAAAAA');
  });

  test('recolorCells keeps the new colors when the server accepts', () async {
    final client = MockClient((req) async => http.Response('{"ok":true}', 200));
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    final p = CellsProvider(api: api, audio: AudioService.silent());
    p.applyBootstrap(2026, {'a': [[1, 1, '#AAAAAA']]});
    p.setContext(pageId: 'a', year: 2026);
    await p.recolorCells({'#AAAAAA': '#111111'});
    expect(p.cellsFor('a', 2026)!.get(1, 1)!.color, '#111111');
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

  group('lastChange', () {
    CellsProvider withServer({int status = 200}) {
      final client = MockClient((req) async {
        if (req.method == 'PUT' && req.url.path.startsWith('/api/cells/')) {
          return http.Response(
            '{"pageId":"a","year":2026,"month":1,"day":3,"color":"#111111","updatedAt":""}',
            status,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (req.method == 'DELETE') return http.Response('', status == 200 ? 204 : status);
        return http.Response('{}', 404);
      });
      final p = CellsProvider(api: ApiService.custom(client: client, tokens: FakeTokens()), audio: AudioService.silent());
      p.applyBootstrap(2026, {'a': [[1, 1, '#AAAAAA']]});
      p.setContext(pageId: 'a', year: 2026);
      return p;
    }

    test('is null until this device changes a cell, then names the cell and its new colour', () async {
      final p = withServer();
      expect(p.lastChange, isNull);
      await p.setCell(1, 3, '#111111');
      final c = p.lastChange!;
      expect((c.pageId, c.year, c.month, c.day, c.color, c.erased), ('a', 2026, 1, 3, '#111111', false));
    });

    test('seq grows at every change, an erase keeps the old colour', () async {
      final p = withServer();
      await p.setCell(1, 3, '#111111');
      final first = p.lastChange!.seq;
      await p.deleteCell(1, 1);
      final c = p.lastChange!;
      expect(c.seq, greaterThan(first));
      expect((c.month, c.day, c.color, c.erased), (1, 1, '#AAAAAA', true));
    });

    test('a refused change is forgotten with the revert', () async {
      final p = withServer(status: 500);
      await p.setCell(1, 3, '#111111');
      expect(p.getCell(1, 3), isNull);
      expect(p.lastChange, isNull);
    });

    test('a bootstrap, a WS message or clear() never produce a pop', () async {
      final p = withServer();
      p.applyBootstrap(2026, {'a': [[2, 2, '#BBBBBB']]});
      expect(p.lastChange, isNull);
      p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
        'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
      }));
      expect(p.lastChange, isNull);
      await p.setCell(1, 3, '#111111');
      p.clear();
      expect(p.lastChange, isNull);
    });
  });
}
