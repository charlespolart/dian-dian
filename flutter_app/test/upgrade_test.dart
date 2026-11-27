import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/sync_service.dart';

import 'helpers.dart';
import 'sync_fakes.dart';

/// What app 1.4.0 left on disk: one tracker, one legend, one day of 2026.
String snapshot140({String userId = 'u1'}) => jsonEncode({
      'v': 1,
      'userId': userId,
      'year': 2026,
      'savedAt': '',
      'data': {
        'year': 2026,
        'activated': true,
        'pages': [pageJson('s', title: 'From 1.4.0')],
        'legends': {'s': [legendJson('ls', 's', '#AAAAAA', 0)]},
        'cells': {'s': [[1, 1, '#AAAAAA']]},
      },
    });

void main() {
  // No binding on purpose, like sync_service_test.dart.
  setUpAll(sqfliteFfiInit);

  late Directory dir;
  late FakeSyncServer server;
  late FakeNetwork network;
  late MemorySnapshots snapshots;
  late PagesProvider pages;
  late CellsProvider cells;
  late LegendsProvider legends;
  late int refusals;
  final services = <SyncService>[];

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dian_upgrade_');
    server = FakeSyncServer();
    network = FakeNetwork();
    snapshots = MemorySnapshots();
    refusals = 0;
  });

  tearDown(() async {
    for (final s in services) {
      await s.clear(keepCopy: true);
      s.dispose();
    }
    services.clear();
    dir.deleteSync(recursive: true);
  });

  /// The app launched again on the same phone (same files, new providers).
  Future<SyncService> launch() async {
    pages = PagesProvider(audio: AudioService.silent());
    cells = CellsProvider(audio: AudioService.silent());
    legends = LegendsProvider(audio: AudioService.silent());
    final sync = SyncService(
      api: ApiService.custom(client: server.client, tokens: FakeTokens()),
      pages: pages,
      cells: cells,
      legends: legends,
      ws: FakeWs(),
      snapshots: snapshots,
      observeLifecycle: false,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databaseDir: dir.path,
      network: network,
    )..onWriteRefused = () => refusals++;
    services.add(sync);
    await sync.start(userId: 'u1', year: 2026);
    await sync.firstSync;
    return sync;
  }

  Future<void> networkBack(SyncService sync) async {
    server.offline = false;
    network.comeBack();
    await Future<void>.delayed(Duration.zero);
    await sync.engine.value!.idle;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  group('H15, the first launch after the update from 1.4.0', () {
    test('with the network: the full copy comes down, then the 1.4.0 file is erased', () async {
      snapshots.data = snapshot140();
      server
        ..addPage('s', title: 'From the server')
        ..addCell('s', 2025, 6, 1, '#AAAAAA');
      await launch();
      expect(pages.pages.single.title, 'From the server');
      expect(cells.cellsFor('s', 2025)!.get(6, 1)?.color, '#AAAAAA', reason: 'every year, not only 1.4.0\'s');
      expect(snapshots.data, isNull);

      cells.setContext(pageId: 's', year: 2026);
      await cells.setCell(2, 2, '#AAAAAA');
      expect(refusals, 0);
      expect(cells.getCell(2, 2)?.color, '#AAAAAA');
    });

    test('without the network: it opens on the 1.4.0 file, and a change is refused without writing anything', () async {
      snapshots.data = snapshot140();
      server.offline = true;
      final sync = await launch();
      expect(pages.pages.single.title, 'From 1.4.0');
      expect(cells.cellsFor('s', 2026)!.get(1, 1)?.color, '#AAAAAA');

      cells.setContext(pageId: 's', year: 2026);
      legends.setPageId('s');
      await cells.setCell(2, 2, '#AAAAAA');
      await cells.deleteCell(1, 1);
      await pages.createPage('New');
      await pages.updatePage('s', {'title': 'Renamed'});
      await legends.createLegend('#BBBBBB', 'Other');
      expect(refusals, 5, reason: 'each attempt says a connection is needed');
      expect(cells.getCell(2, 2), isNull);
      expect(cells.getCell(1, 1)?.color, '#AAAAAA');
      expect(pages.pages.map((p) => p.title), ['From 1.4.0']);
      expect(legends.legendsFor('s').length, 1);
      expect(sync.engine.value!.pendingCount, 0, reason: 'nothing written');
      expect(snapshots.data, isNotNull, reason: 'kept until the full copy');
    });

    test('once the network comes back, the full copy arrives and changes are written again', () async {
      snapshots.data = snapshot140();
      server
        ..offline = true
        ..addPage('s', title: 'From the server');
      final sync = await launch();
      await networkBack(sync);
      expect(pages.pages.single.title, 'From the server');
      expect(snapshots.data, isNull);
      cells.setContext(pageId: 's', year: 2026);
      await cells.setCell(2, 2, '#AAAAAA');
      expect(refusals, 0);
      await sync.engine.value!.idle;
      expect(server.sentKinds, ['cell.set']);
    });
  });

  group('H14, a tracker deletion that holds', () {
    test('the app killed during the 8 seconds finds it done when reopened: gone, and in the queue', () async {
      server
        ..addPage('a', title: 'Keep')
        ..addPage('b', title: 'Delete me', position: 1);
      var sync = await launch();
      server.offline = true;
      pages.softDeletePage(pages.pages.firstWhere((p) => p.id == 'b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Killed: the providers and their 8-second timer are gone, the files stay.
      await sync.clear(keepCopy: true);

      sync = await launch();
      expect(pages.pages.map((p) => p.title), ['Keep']);
      expect(sync.engine.value!.pendingCount, 1, reason: 'its deletion is queued');
      expect(server.sentKinds, isEmpty, reason: 'offline');
      await networkBack(sync);
      expect(server.sentKinds, ['page.delete']);
    });

    test('an undo within the 8 seconds leaves nothing behind', () async {
      server
        ..addPage('a', title: 'Keep')
        ..addPage('b', title: 'Delete me', position: 1);
      var sync = await launch();
      pages.softDeletePage(pages.pages.firstWhere((p) => p.id == 'b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      pages.undoDeletePage();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sync.clear(keepCopy: true);

      sync = await launch();
      expect(pages.pages.map((p) => p.title), ['Keep', 'Delete me']);
      expect(sync.engine.value!.pendingCount, 0);
    });
  });
}
