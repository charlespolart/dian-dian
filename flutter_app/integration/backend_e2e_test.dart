// End-to-end: the REAL Flutter data layer (ApiService + providers +
// SyncService, the copy on the phone and its queue) against a RUNNING local
// backend on http://localhost:3001.
//
// Not under test/ on purpose — `flutter test` must stay hermetic. Run with:
//   cd flutter_app && flutter test integration/backend_e2e_test.dart
//
// Registers a throwaway account, drives two phones (two copies) through real
// HTTP, and deletes the account at the end.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dian_dian/data/connectivity.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/snapshot_store.dart';
import 'package:dian_dian/services/sync_service.dart';
import 'package:dian_dian/services/token_store.dart';
import 'package:dian_dian/services/ws_service.dart';

class MemoryTokens implements TokenStore {
  String? refresh;
  String? userId;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> setRefreshToken(String token) async => refresh = token;
  @override
  Future<void> deleteRefreshToken() async => refresh = null;
  @override
  Future<String?> getUserId() async => userId;
  @override
  Future<void> setUserId(String id) async => userId = id;
  @override
  Future<void> deleteUserId() async => userId = null;
}

class MemorySnapshots implements SnapshotStore {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> delete() async => data = null;
}

class QuietNetwork implements NetworkWatcher {
  @override
  Stream<void> get onChange => const Stream.empty();
}

/// One phone: its providers and its copy.
class Phone {
  Phone(ApiService api, String dir)
      : pages = PagesProvider(audio: AudioService.silent()),
        cells = CellsProvider(audio: AudioService.silent()),
        legends = LegendsProvider(audio: AudioService.silent()) {
    sync = SyncService(
      api: api,
      pages: pages,
      cells: cells,
      legends: legends,
      ws: WsService(),
      snapshots: MemorySnapshots(),
      observeLifecycle: false,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databaseDir: dir,
      network: QuietNetwork(),
    );
  }

  final PagesProvider pages;
  final CellsProvider cells;
  final LegendsProvider legends;
  late final SyncService sync;

  /// Sends the queue, brings back what changed, and waits for the screens.
  Future<void> settle() async {
    await sync.revalidate();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  // Plain test() without the widgets binding: real sockets are allowed.
  setUpAll(sqfliteFfiInit);

  test('real backend: register → write on the phone → sent → a second phone sees it → and back', () async {
    final dir = Directory.systemTemp.createTempSync('dian_e2e_');
    final tokens = MemoryTokens();
    final api = ApiService.custom(client: http.Client(), tokens: tokens);
    final email = 'e2e-${DateTime.now().millisecondsSinceEpoch}@example.com';
    final session = await api.register(email, 'e2e-password-123');
    final userId = session['userId'] as String;
    expect(tokens.userId, userId);
    final year = DateTime.now().year;

    // A fresh phone: nothing to show, the first sync brings the (empty) account.
    final one = Phone(api, (Directory('${dir.path}/one')..createSync()).path);
    expect(await one.sync.start(userId: userId, year: year), isFalse);
    await one.sync.firstSync;
    expect(one.pages.pages, isEmpty, reason: 'no default tracker since backend 1.2.0');
    expect(one.sync.activated, isFalse);

    // Changes are written on the phone at once, then sent with the queue.
    final first = await one.pages.createPage('First');
    final pageId = first!.id;
    one.cells.setContext(pageId: pageId, year: year);
    one.legends.setPageId(pageId);
    await one.legends.createLegend('#FF0000', 'Red');
    await one.cells.setCell(12, 31, '#FF0000', comment: 'nye');
    await one.cells.setCell(1, 1, '#FF0000');
    final second = await one.pages.createPage('Second');
    await one.pages.reorderPages([second!.id, pageId]);
    expect(one.cells.filledDays, 2);
    await one.settle();
    expect(one.sync.engine.value!.pendingCount, 0, reason: 'everything was accepted');
    expect(one.sync.activated, isTrue);

    // The old routes agree (old clients keep working).
    final legacy = await api.apiFetch('/api/cells/$pageId?year=$year');
    expect(legacy.statusCode, 200);
    expect((jsonDecode(legacy.body) as List).length, 2);

    // A second phone on the same account gets the whole copy.
    final two = Phone(api, (Directory('${dir.path}/two')..createSync()).path);
    await two.sync.start(userId: userId, year: year);
    await two.sync.firstSync;
    expect(two.pages.pages.map((p) => p.id), [second.id, pageId]);
    expect(two.cells.cellsFor(pageId, year)!.get(12, 31)!.comment, 'nye');
    expect(two.legends.legendsFor(pageId).single.label, 'Red');

    // Its change reaches the first phone.
    two.cells.setContext(pageId: pageId, year: year);
    await two.cells.setCell(6, 15, '#FF0000');
    await two.settle();
    await one.settle();
    expect(one.cells.cellsFor(pageId, year)!.get(6, 15)?.color, '#FF0000');

    // A legend's new colour is one change, and recolours its days everywhere.
    two.legends.setPageId(pageId);
    await two.legends.updateLegend(two.legends.legends.single.id, color: '#00FF00');
    await two.settle();
    await one.settle();
    expect(one.legends.legendsFor(pageId).single.color, '#00FF00');
    expect(one.cells.cellsFor(pageId, year)!.get(1, 1)!.color, '#00FF00');

    // Cleanup.
    await one.sync.clear();
    await two.sync.clear();
    final del = await api.apiFetch('/api/auth/account', method: 'DELETE');
    expect(del.statusCode, 200);
    dir.deleteSync(recursive: true);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
