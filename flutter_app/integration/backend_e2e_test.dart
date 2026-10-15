// End-to-end: the REAL Flutter data layer (ApiService + providers +
// SyncService) against a RUNNING local backend on http://localhost:3001.
//
// Not under test/ on purpose — `flutter test` must stay hermetic. Run with:
//   cd flutter_app && flutter test integration/backend_e2e_test.dart
//
// Registers a throwaway account, drives the store through real HTTP, and
// deletes the account at the end.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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
  Future<void> write(String json) async => data = json;
  @override
  Future<void> delete() async => data = null;
}

void main() {
  // Plain test() without the widgets binding: real sockets are allowed.
  test('real backend: register → bootstrap → mutate → snapshot → rehydrate', () async {
    final tokens = MemoryTokens();
    final api = ApiService.custom(client: http.Client(), tokens: tokens);
    final email = 'e2e-${DateTime.now().millisecondsSinceEpoch}@example.com';
    final session = await api.register(email, 'e2e-password-123');
    final userId = session['userId'] as String;
    expect(tokens.userId, userId);

    final pages = PagesProvider(api: api);
    final cells = CellsProvider(api: api, audio: AudioService.silent());
    final legends = LegendsProvider(api: api);
    final snapshots = MemorySnapshots();
    final sync = SyncService(
      api: api,
      pages: pages,
      cells: cells,
      legends: legends,
      ws: WsService(),
      snapshots: snapshots,
      observeLifecycle: false,
    );

    // Cold start without a snapshot: start() reports nothing hydrated, and
    // the awaited ensureYear completes the bootstrap.
    final year = DateTime.now().year;
    final hydrated = await sync.start(userId: userId, year: year);
    expect(hydrated, isFalse);
    await sync.ensureYear(year);
    expect(pages.pages, isEmpty, reason: 'no default tracker since backend 1.2.0');
    final first = await pages.createPage('First');
    expect(first, isNotNull, reason: 'the app creates the first tracker');
    final pageId = first!.id;
    // The new page has no cells entry until a bootstrap sees it.
    await sync.ensureYear(year);
    expect(cells.isYearLoaded(year), isTrue);
    expect(cells.cellsFor(pageId, year)!.isEmpty, isTrue);

    // Mutations go through the real endpoints and update the store.
    cells.setContext(pageId: pageId, year: year);
    legends.setPageId(pageId);
    await legends.createLegend('#FF0000', 'Red');
    expect(legends.legends.single.label, 'Red');
    await cells.setCell(12, 31, '#FF0000', comment: 'nye');
    await cells.setCell(1, 1, '#FF0000');
    expect(cells.filledDays, 2);
    expect(cells.getCell(12, 31)!.comment, 'nye');

    // A second tracker + one-request reorder.
    final created = await pages.createPage('Second');
    expect(created, isNotNull);
    await pages.reorderPages([created!.id, pageId]);
    expect(pages.pages.map((p) => p.id), [created.id, pageId]);

    // Revalidate: server state == local state → identical shape.
    await sync.revalidate();
    expect(cells.cellsFor(pageId, year)!.length, 2);
    expect(cells.cellsFor(pageId, year)!.get(12, 31)!.comment, 'nye');
    expect(legends.legendsFor(pageId).single.color, '#FF0000');
    expect(pages.pages.map((p) => p.id), [created.id, pageId]);

    // Snapshot written by the bootstrap; a fresh store hydrates from it.
    await sync.persistSnapshot();
    final snap = jsonDecode(snapshots.data!) as Map<String, dynamic>;
    expect(snap['userId'], userId);
    final pages2 = PagesProvider(api: api);
    final cells2 = CellsProvider(api: api, audio: AudioService.silent());
    final legends2 = LegendsProvider(api: api);
    final sync2 = SyncService(
      api: api,
      pages: pages2,
      cells: cells2,
      legends: legends2,
      ws: WsService(),
      snapshots: snapshots,
      observeLifecycle: false,
    );
    final hydrated2 = await sync2.start(userId: userId, year: year);
    expect(hydrated2, isTrue);
    expect(cells2.cellsFor(pageId, year)!.length, 2);
    expect(legends2.legendsFor(pageId).single.label, 'Red');
    await sync2.ensureYear(year); // joins the in-flight bootstrap start() kicked

    // Legacy endpoint still agrees (old clients keep working).
    final legacy = await api.apiFetch('/api/cells/$pageId?year=$year');
    expect(legacy.statusCode, 200);
    expect((jsonDecode(legacy.body) as List).length, 2);

    // Cleanup.
    final del = await api.apiFetch('/api/auth/account', method: 'DELETE');
    expect(del.statusCode, 200);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
