import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/snapshot_store.dart';
import 'package:dian_dian/services/sync_service.dart';
import 'package:dian_dian/services/token_store.dart';
import 'package:dian_dian/services/ws_service.dart';

class MemorySnapshots implements SnapshotStore {
  String? data;
  int writes = 0;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String json) async {
    data = json;
    writes++;
  }

  @override
  Future<void> delete() async => data = null;
}

class FakeTokens implements TokenStore {
  @override
  Future<String?> getRefreshToken() async => 'r';
  @override
  Future<void> setRefreshToken(String token) async {}
  @override
  Future<void> deleteRefreshToken() async {}
  @override
  Future<String?> getUserId() async => 'u1';
  @override
  Future<void> setUserId(String id) async {}
  @override
  Future<void> deleteUserId() async {}
}

Map<String, dynamic> bootstrapBody(int year, {String color = '#AAAAAA'}) => {
      'year': year,
      'pages': [
        {'id': 'a', 'userId': 'u1', 'title': 'A', 'position': 0, 'palette': null, 'createdAt': '', 'year': year},
      ],
      'legends': {
        'a': [
          {'id': 'l1', 'pageId': 'a', 'color': color, 'label': 'L', 'position': 0, 'createdAt': ''},
        ],
      },
      'cells': {
        'a': [
          [1, 1, color],
        ],
      },
    };

void main() {
  // No binding on purpose: SyncService is built with observeLifecycle: false.
  // (With the test binding, MockClient-backed futures never resolve under test().)

  late int bootstrapCalls;
  late int statusCode;
  late MemorySnapshots snapshots;
  late PagesProvider pages;
  late CellsProvider cells;
  late LegendsProvider legends;

  SyncService build({Map<String, dynamic> Function(int year)? body}) {
    bootstrapCalls = 0;
    statusCode = 200;
    final client = MockClient((req) async {
      if (req.url.path == '/api/bootstrap') {
        bootstrapCalls++;
        if (statusCode != 200) return http.Response('{"error":"down"}', statusCode);
        final year = int.parse(req.url.queryParameters['year']!);
        return http.Response(jsonEncode((body ?? bootstrapBody)(year)), 200);
      }
      return http.Response('{}', 404);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    snapshots = MemorySnapshots();
    pages = PagesProvider();
    cells = CellsProvider();
    legends = LegendsProvider();
    return SyncService(
      api: api,
      pages: pages,
      cells: cells,
      legends: legends,
      ws: WsService(),
      snapshots: snapshots,
      observeLifecycle: false,
    );
  }

  test('ensureYear fetches once per year (deduped) and applies to all providers', () async {
    final sync = build();
    await Future.wait([sync.ensureYear(2026), sync.ensureYear(2026)]);
    await sync.ensureYear(2026);
    expect(bootstrapCalls, 1);
    expect(pages.pages.single.id, 'a');
    expect(legends.legendsFor('a').single.id, 'l1');
    expect(cells.isYearLoaded(2026), isTrue);
    expect(cells.cellsFor('a', 2026)!.get(1, 1)!.color, '#AAAAAA');
    expect(sync.activeYear, 2026);
    expect(snapshots.data, isNotNull);
  });

  test('a second year is a second fetch, and the first year stays', () async {
    final sync = build();
    await sync.ensureYear(2026);
    await sync.ensureYear(2025);
    expect(bootstrapCalls, 2);
    expect(cells.isYearLoaded(2025), isTrue);
    expect(cells.isYearLoaded(2026), isTrue);
    expect(sync.activeYear, 2025);
  });

  test('start hydrates pages, legends and cells from a matching snapshot before the network', () async {
    final first = build();
    await first.start(userId: 'u1', year: 2026);
    await first.ensureYear(2026); // awaits the bootstrap start() kicked off
    final saved = snapshots.data!;

    final sync = build();
    snapshots.data = saved;
    final hydrated = await sync.start(userId: 'u1', year: 2026);
    expect(hydrated, isTrue);
    expect(pages.pages.single.id, 'a');
    expect(legends.legendsFor('a').single.id, 'l1');
    expect(cells.cellsFor('a', 2026)!.length, 1);
    expect(cells.isYearLoaded(2026), isTrue);
  });

  test('snapshot cells are ignored when the snapshot year differs (pages still hydrate)', () async {
    final first = build();
    await first.start(userId: 'u1', year: 2026);
    await first.ensureYear(2026); // awaits the bootstrap start() kicked off
    final saved = snapshots.data!;

    final sync = build();
    snapshots.data = saved;
    final hydrated = await sync.start(userId: 'u1', year: 2025);
    expect(hydrated, isTrue);
    expect(pages.pages.single.id, 'a');
    // The snapshot held 2026 cells; they must not be applied under 2025 nor
    // marked loaded for 2026.
    expect(cells.isYearLoaded(2026), isFalse);
    expect(cells.cellsFor('a', 2026), isNull);
  });

  test('snapshot of another user is ignored', () async {
    final first = build();
    await first.start(userId: 'u1', year: 2026);
    await first.ensureYear(2026); // awaits the bootstrap start() kicked off
    final saved = snapshots.data!;

    final sync = build();
    snapshots.data = saved;
    final hydrated = await sync.start(userId: 'someone-else', year: 2026);
    expect(hydrated, isFalse);
    expect(pages.pages, isEmpty);
  });

  test('a corrupt snapshot is ignored', () async {
    final sync = build();
    snapshots.data = '{not json';
    final hydrated = await sync.start(userId: 'u1', year: 2026);
    expect(hydrated, isFalse);
  });

  test('revalidate with an unchanged body does not notify or rewrite the snapshot', () async {
    final sync = build();
    await sync.ensureYear(2026);
    final writesBefore = snapshots.writes;
    var notified = 0;
    cells.addListener(() => notified++);
    pages.addListener(() => notified++);
    await sync.revalidate();
    expect(bootstrapCalls, 2);
    expect(notified, 0);
    expect(snapshots.writes, writesBefore);
  });

  test('revalidate with a changed body applies it', () async {
    var color = '#AAAAAA';
    final sync = build(body: (y) => bootstrapBody(y, color: color));
    await sync.ensureYear(2026);
    color = '#222222';
    await sync.revalidate();
    expect(cells.cellsFor('a', 2026)!.get(1, 1)!.color, '#222222');
    expect(legends.legendsFor('a').single.color, '#222222');
  });

  test('a failed fetch keeps the current data and the year stays unloaded', () async {
    final sync = build();
    statusCode = 503;
    await sync.ensureYear(2026);
    expect(cells.isYearLoaded(2026), isFalse);
    expect(pages.pages, isEmpty);
    // Next ensureYear retries.
    statusCode = 200;
    await sync.ensureYear(2026);
    expect(bootstrapCalls, 2);
    expect(cells.isYearLoaded(2026), isTrue);
  });

  test('revalidate before start is a no-op', () async {
    final sync = build();
    await sync.revalidate();
    expect(bootstrapCalls, 0);
  });

  test('persistSnapshot serializes the current store in bootstrap format', () async {
    final sync = build();
    await sync.ensureYear(2026);
    cells.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
      'pageId': 'a', 'year': 2026, 'month': 6, 'day': 6, 'color': '#333333', 'comment': 'c', 'updatedAt': '',
    }));
    await sync.persistSnapshot();
    final snap = jsonDecode(snapshots.data!) as Map<String, dynamic>;
    expect(snap['v'], 1);
    expect(snap['userId'], isNull); // not started via start(): no user id
    final data = snap['data'] as Map<String, dynamic>;
    expect(data['year'], 2026);
    expect((data['cells'] as Map)['a'], containsAll([[6, 6, '#333333', 'c']]));
  });

  test('an identical body is still applied when the store changed locally since the last apply', () async {
    final sync = build();
    await sync.ensureYear(2026);
    // A local change the server never received (e.g. a failed recolor).
    cells.debugHandleWs(const WsMessage(event: 'cells:recolored', data: {
      'pageId': 'a', 'colorMap': {'#AAAAAA': '#999999'},
    }));
    expect(cells.cellsFor('a', 2026)!.get(1, 1)!.color, '#999999');
    await sync.revalidate(); // server body is byte-identical to the first one
    expect(cells.cellsFor('a', 2026)!.get(1, 1)!.color, '#AAAAAA', reason: 'store healed from the server');
  });

  test('a local mutation during an in-flight bootstrap discards that body and refetches once', () async {
    var mutateDuringFetch = false;
    final sync = build(body: (y) {
      if (mutateDuringFetch) {
        mutateDuringFetch = false;
        // Simulates a tap that landed while the request was in flight.
        cells.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
          'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
        }));
      }
      return bootstrapBody(y);
    });
    await sync.ensureYear(2026);
    expect(bootstrapCalls, 1);
    mutateDuringFetch = true;
    await sync.revalidate();
    expect(bootstrapCalls, 3, reason: 'stale body discarded, one retry');
    expect(cells.cellsFor('a', 2026)!.get(3, 3), isNull, reason: 'the retry carries server truth');
  });

  test('ensureYear refetches a loaded year when a page has no entry for it', () async {
    final sync = build();
    await sync.ensureYear(2026);
    pages.debugHandleWs(WsMessage(event: 'page:created', data: {
      'id': 'b', 'userId': 'u1', 'title': 'B', 'position': 1, 'palette': null, 'createdAt': '', 'year': 2026,
    }));
    await sync.ensureYear(2026);
    expect(bootstrapCalls, 2);
  });

  test('clear wipes providers and snapshot', () async {
    final sync = build();
    await sync.start(userId: 'u1', year: 2026);
    await sync.ensureYear(2026);
    await sync.clear();
    expect(pages.pages, isEmpty);
    expect(legends.legendsFor('a'), isEmpty);
    expect(cells.isYearLoaded(2026), isFalse);
    expect(snapshots.data, isNull);
    await sync.revalidate();
    expect(bootstrapCalls, 1);
  });
}
