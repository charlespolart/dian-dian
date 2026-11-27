import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dian_dian/data/change_sink.dart';
import 'package:dian_dian/data/tracker_lock.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/sync_service.dart';

import 'helpers.dart';
import 'sync_fakes.dart';

Map<String, dynamic> snapshot({String userId = 'u1', int year = 2026, bool? activated}) => {
      'v': 1,
      'userId': userId,
      'year': year,
      'savedAt': '',
      'data': {
        'year': year,
        'activated': ?activated,
        'pages': [pageJson('s', title: 'From 1.4.0')],
        'legends': {'s': [legendJson('ls', 's', '#AAAAAA', 0)]},
        'cells': {'s': [[1, 1, '#AAAAAA']]},
      },
    };

void main() {
  // No binding on purpose: SyncService is built with observeLifecycle: false.
  // (With the test binding, MockClient-backed futures never resolve under test().)
  setUpAll(sqfliteFfiInit);

  late Directory dir;
  late FakeSyncServer server;
  late FakeNetwork network;
  late FakeWs ws;
  late MemorySnapshots snapshots;
  late PagesProvider pages;
  late CellsProvider cells;
  late LegendsProvider legends;
  final services = <SyncService>[];

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dian_sync_');
    server = FakeSyncServer();
    network = FakeNetwork();
    ws = FakeWs();
    snapshots = MemorySnapshots();
  });

  tearDown(() async {
    for (final s in services) {
      await s.clear(keepCopy: true);
      s.dispose();
    }
    services.clear();
    SettingsSink.sink = null;
    dir.deleteSync(recursive: true);
  });

  /// A fresh app (new providers) over the same phone (same files).
  SyncService build() {
    pages = PagesProvider(audio: AudioService.silent());
    cells = CellsProvider(audio: AudioService.silent());
    legends = LegendsProvider(audio: AudioService.silent());
    final sync = SyncService(
      api: ApiService.custom(client: server.client, tokens: FakeTokens()),
      pages: pages,
      cells: cells,
      legends: legends,
      ws: ws,
      snapshots: snapshots,
      observeLifecycle: false,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databasePath: (userId) => '${dir.path}/dian_$userId.db',
      network: network,
    );
    services.add(sync);
    return sync;
  }

  Future<SyncService> started({String userId = 'u1'}) async {
    final sync = build();
    await sync.start(userId: userId, year: 2026);
    await sync.firstSync;
    return sync;
  }

  /// Lets the engine's cycle and the reload it triggers finish.
  Future<void> settle(SyncService sync) async {
    await sync.engine.value!.idle;
    await Future<void>.delayed(Duration.zero);
    await sync.firstSync;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  test('a fresh phone shows the full copy after the first sync: every year, legends, activated', () async {
    server
      ..addPage('a', title: 'Sport')
      ..addCell('a', 2024, 3, 3, '#AAAAAA')
      ..addCell('a', 2026, 1, 1, '#AAAAAA');
    server.legends['l1'] = {'id': 'l1', 'pageId': 'a', 'color': '#AAAAAA', 'label': 'Yes', 'position': 0, 'rev': 9, 'editRev': 9};
    final sync = build();
    expect(await sync.start(userId: 'u1', year: 2026), isFalse, reason: 'nothing on the phone yet');
    await sync.firstSync;
    expect(pages.pages.map((p) => p.title), ['Sport']);
    expect(legends.legendsFor('a').single.label, 'Yes');
    expect(cells.cellsFor('a', 2024)!.get(3, 3)?.color, '#AAAAAA');
    expect(cells.cellsFor('a', 2026)!.get(1, 1)?.color, '#AAAAAA');
    expect(sync.activated, isTrue);
  });

  test('the copy stays on the phone between launches and shows offline, before any network', () async {
    server
      ..addPage('a', title: 'Sport')
      ..addCell('a', 2026, 1, 1, '#AAAAAA');
    final first = await started();
    await first.clear(keepCopy: true);
    server.offline = true;
    final sync = build();
    expect(await sync.start(userId: 'u1', year: 2026), isTrue);
    expect(pages.pages.map((p) => p.title), ['Sport']);
    expect(cells.cellsFor('a', 2026)!.get(1, 1)?.color, '#AAAAAA');
    expect(sync.snapshotActivated, isTrue);
  });

  test('signing out erases the copy; a session the server closed keeps it with its queue (H25)', () async {
    server.addPage('a');
    final first = await started();
    server.offline = true;
    cells.setContext(pageId: 'a', year: 2026);
    await cells.setCell(1, 1, '#AAAAAA');
    await settle(first);
    await first.clear(keepCopy: true);

    final again = build();
    expect(await again.start(userId: 'u1', year: 2026), isTrue);
    expect(again.engine.value!.pendingCount, 1, reason: 'the change made before the session closed is still queued');
    await again.clear();

    final afterSignOut = build();
    expect(await afterSignOut.start(userId: 'u1', year: 2026), isFalse, reason: 'nothing left on the phone');
  });

  test('signing out while a sync is on its way waits for it before closing the copy', () async {
    server.addPage('a');
    final sync = await started();
    server.hold = Completer<void>();
    cells.setContext(pageId: 'a', year: 2026);
    await cells.setCell(1, 1, '#AAAAAA');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final cleared = sync.clear();
    server.hold!.complete();
    await cleared;
    expect(server.sentKinds, ['cell.set'], reason: 'the send in flight finished');
    expect(pages.pages, isEmpty);
  });

  test('a change made offline stays shown, counts one change, and leaves when the network returns (H1)', () async {
    server.addPage('a');
    final sync = await started();
    server.offline = true;
    cells.setContext(pageId: 'a', year: 2026);
    await cells.setCell(1, 1, '#AAAAAA');
    await settle(sync);
    expect(sync.engine.value!.isOffline, isTrue);
    expect(sync.engine.value!.pendingCount, 1);
    expect(cells.getCell(1, 1)?.color, '#AAAAAA', reason: 'never undone');

    server.offline = false;
    network.comeBack();
    await Future<void>.delayed(Duration.zero);
    await settle(sync);
    expect(server.sentKinds, ['cell.set']);
    expect(sync.engine.value!.pendingCount, 0);
    expect(cells.getCell(1, 1)?.color, '#AAAAAA');
  });

  test('a tracker created offline then one of its days: two changes, sent in that order (H2)', () async {
    final sync = await started();
    server.offline = true;
    final page = await pages.createPage('Sport');
    cells.setContext(pageId: page!.id, year: 2026);
    await cells.setCell(1, 1, '#AAAAAA');
    await settle(sync);
    expect(sync.engine.value!.pendingCount, 2);
    expect(pages.pages.map((p) => p.title), ['Sport']);

    server.offline = false;
    network.comeBack();
    await Future<void>.delayed(Duration.zero);
    await settle(sync);
    expect(server.sentKinds, ['page.create', 'cell.set']);
    expect(server.pages.keys, [page.id], reason: 'the id made by the phone is the server\'s');
  });

  test('a sync message from the server starts a sync', () async {
    final sync = await started();
    final before = server.pulls;
    server.addPage('a', title: 'From the other phone');
    ws.receive('sync', {'rev': server.rev});
    await Future<void>.delayed(Duration.zero);
    await settle(sync);
    expect(server.pulls, before + 1);
    expect(pages.pages.map((p) => p.title), ['From the other phone']);
  });

  test('the old live messages change nothing any more', () async {
    final sync = await started();
    final before = server.pulls;
    ws.receive('cell:updated', {'pageId': 'a', 'year': 2026, 'month': 1, 'day': 1, 'color': '#AAAAAA'});
    await settle(sync);
    expect(server.pulls, before);
    expect(cells.cellsFor('a', 2026), isNull);
  });

  test('H9: Premium lost while away keeps what was made offline (a 4th tracker), and the phone learns it', () async {
    for (final id in ['a', 'b', 'c']) {
      server.addPage(id, position: server.pages.length);
    }
    server.premium = true;
    final told = <bool>[];
    final sync = build()..onPremium = told.add;
    await sync.start(userId: 'u1', year: 2026);
    await sync.firstSync;
    expect(told.last, isTrue);

    server.offline = true;
    await pages.createPage('Fourth');
    await settle(sync);
    server
      ..premium = false
      ..offline = false;
    network.comeBack();
    await Future<void>.delayed(Duration.zero);
    await settle(sync);
    expect(pages.pages.length, 4, reason: 'nothing made offline is lost');
    expect(told.last, isFalse);
    expect(!hasKeepChoice(pages.pages) && pages.pages.length > 3, isTrue, reason: 'the list opens the keep screen');
  });

  test('settings: the copy\'s reach the app, a change goes through the queue', () async {
    server.rev++;
    server.settings['theme'] = {'rev': server.rev, 'value': 'sakura'};
    final applied = <Map<String, Object?>>[];
    final sync = build()..onSettings = applied.add;
    await sync.start(userId: 'u1', year: 2026);
    await sync.firstSync;
    expect(applied.last['theme'], 'sakura');

    await SettingsSink.record('theme', 'night');
    await settle(sync);
    expect(server.sentKinds, ['setting.set']);
    expect(server.settings['theme']!['value'], 'night');
  });

  group('the 1.4.0 snapshot (until the first full copy)', () {
    test('shows pages, legends and the year\'s days of the same account, offline', () async {
      snapshots.data = jsonEncode(snapshot(activated: true));
      server.offline = true;
      final sync = build();
      expect(await sync.start(userId: 'u1', year: 2026), isTrue);
      expect(pages.pages.single.title, 'From 1.4.0');
      expect(legends.legendsFor('s').single.id, 'ls');
      expect(cells.cellsFor('s', 2026)!.get(1, 1)?.color, '#AAAAAA');
      expect(sync.snapshotActivated, isTrue);
      expect(sync.activated, isNull, reason: 'no full copy yet');
    });

    test('of another year: pages only', () async {
      snapshots.data = jsonEncode(snapshot(year: 2025));
      server.offline = true;
      await build().start(userId: 'u1', year: 2026);
      expect(pages.pages.single.id, 's');
      expect(cells.cellsFor('s', 2025), isNull);
    });

    test('of another account, or corrupt: ignored', () async {
      snapshots.data = jsonEncode(snapshot(userId: 'someone-else'));
      server.offline = true;
      final first = build();
      expect(await first.start(userId: 'u1', year: 2026), isFalse);
      await first.clear(keepCopy: true);
      snapshots.data = '{not json';
      expect(await build().start(userId: 'u1', year: 2026), isFalse);
      expect(pages.pages, isEmpty);
    });

    test('without activated but with days (app 1.3.0) counts as activated', () async {
      snapshots.data = jsonEncode(snapshot());
      server.offline = true;
      final sync = build();
      await sync.start(userId: 'u1', year: 2026);
      expect(sync.snapshotActivated, isTrue);
    });

    test('gives way to the full copy, and is deleted then', () async {
      snapshots.data = jsonEncode(snapshot(activated: true));
      server.addPage('a', title: 'Server');
      await started();
      expect(pages.pages.map((p) => p.title), ['Server']);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.data, isNull);
    });
  });
}
