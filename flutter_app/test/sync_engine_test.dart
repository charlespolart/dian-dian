import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dian_dian/data/connectivity.dart';
import 'package:dian_dian/data/local_store.dart';
import 'package:dian_dian/data/mutation.dart';
import 'package:dian_dian/data/sync_engine.dart';
import 'package:dian_dian/services/api_service.dart';

import 'helpers.dart';

const p1 = '11111111-1111-4111-8111-111111111111';

/// A server that keeps every answer by change id, like the real one: a resend
/// gets the same answer and applies nothing again.
class FakeServer {
  final answers = <String, Map<String, dynamic>>{};
  final batches = <List<String>>[];
  /// 'send' or 'pull', in the order the phone asked.
  final calls = <String>[];
  /// The base each change arrived with, by id (the last time it came).
  final bases = <String, Object?>{};
  int applied = 0;
  int rev = 1;
  int pulls = 0;
  /// Fail the next N mutation posts (no network).
  int failPosts = 0;
  /// Apply the next post, then lose its answer (throw).
  bool loseNextAnswer = false;
  /// Kinds of answer to give per change id (default applied).
  final verdicts = <String, String>{};
  /// Answer a tracker's content number too, as the server does for a change inside a tracker.
  bool contentRevs = false;

  late final client = MockClient((req) async {
    if (req.url.path == '/api/sync/mutations') {
      calls.add('send');
      if (failPosts > 0) {
        failPosts--;
        throw const SocketLikeException();
      }
      final mutations = (jsonDecode(req.body)['mutations'] as List).cast<Map<String, dynamic>>();
      batches.add([for (final m in mutations) m['id'] as String]);
      for (final m in mutations) {
        bases[m['id'] as String] = m['base'];
      }
      final results = [
        for (final m in mutations)
          answers.putIfAbsent(m['id'] as String, () {
            final status = verdicts[m['id']] ?? 'applied';
            if (status == 'applied') applied++;
            rev++;
            return status == 'applied'
                ? {'id': m['id'], 'status': 'applied', 'revs': {'element': rev, 'account': rev, if (contentRevs) 'content': rev}}
                : {'id': m['id'], 'status': status, 'current': null};
          }),
      ];
      if (loseNextAnswer) {
        loseNextAnswer = false;
        throw const SocketLikeException();
      }
      return http.Response(jsonEncode({'results': results, 'rev': rev}), 200);
    }
    if (req.url.path == '/api/sync') {
      calls.add('pull');
      pulls++;
      return http.Response(jsonEncode({
        'rev': rev, 'full': req.url.queryParameters['since'] == '0', 'pages': [], 'legends': [], 'cells': {}, 'deletions': [],
        'legendsOrder': {}, 'settings': {}, 'premium': false, 'vip': false,
      }), 200);
    }
    return http.Response('{}', 404);
  });
}

class SocketLikeException implements Exception {
  const SocketLikeException();
}

class FakeNetwork implements NetworkWatcher {
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get onChange => _changes.stream;
  void comeBack() => _changes.add(null);
}

Map<String, dynamic> day(int d) => {'pageId': p1, 'year': 2026, 'month': 1 + (d ~/ 28), 'day': 1 + (d % 28), 'color': '#123456'};

void main() {
  setUpAll(sqfliteFfiInit);

  late FakeServer server;
  late LocalStore store;
  late FakeNetwork network;
  late List<Duration> retries;
  late SyncEngine engine;

  setUp(() async {
    server = FakeServer();
    store = await LocalStore.open('u1', factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    network = FakeNetwork();
    retries = [];
    engine = SyncEngine(
      store: store,
      api: ApiService.custom(client: server.client, tokens: FakeTokens()),
      network: network,
      schedule: (delay, run) => retries.add(delay),
    );
  });

  tearDown(() async {
    engine.dispose();
    await store.close();
  });

  test('the queue leaves in order, by batches of 100, then the phone asks what changed', () async {
    final ids = [for (var i = 0; i < 150; i++) (await store.record('cell.set', day(i), offline: true)).id];
    await engine.kick();
    expect(server.batches.map((b) => b.length), [100, 50]);
    expect(server.batches.expand((b) => b), ids, reason: 'in the order of the gestures');
    expect(await store.pendingCount(), 0);
    expect(engine.pendingCount, 0);
    expect(server.pulls, 2, reason: 'they waited: read before sending them (H29), and after');
    expect(engine.state, SyncState.online);
    expect(engine.lastSentCount, 150);
  });

  test('no network: the queue stays, everything in it is marked as having waited, and a retry is planned', () async {
    for (var i = 0; i < 3; i++) {
      await store.record('cell.set', day(i), offline: false);
    }
    server.failPosts = 1;
    await engine.kick();
    expect(engine.state, SyncState.offline);
    expect(engine.pendingCount, 3);
    expect((await store.pending()).every((m) => m.waited), isTrue, reason: 'their first send failed (spec, "a attendu")');
    expect(retries.single, const Duration(seconds: 5));
    server.failPosts = 1;
    await engine.kick();
    expect(retries.last, const Duration(seconds: 10), reason: 'the delay doubles');
  });

  test('a cut in the middle resumes where it stopped', () async {
    for (var i = 0; i < 150; i++) {
      await store.record('cell.set', day(i), offline: true);
    }
    server.failPosts = 0;
    final real = server.client;
    var posts = 0;
    final engine2 = SyncEngine(
      store: store,
      api: ApiService.custom(
        client: MockClient((req) async {
          if (req.url.path == '/api/sync/mutations' && ++posts == 2) throw const SocketLikeException();
          return real.send(http.Request(req.method, req.url)..body = req.body).then(http.Response.fromStream);
        }),
        tokens: FakeTokens(),
      ),
      network: network,
      schedule: (delay, run) {},
    );
    await engine2.kick();
    expect(await store.pendingCount(), 50, reason: 'the first 100 went');
    await engine.kick();
    expect(await store.pendingCount(), 0);
    expect(server.applied, 150);
    engine2.dispose();
  });

  test('an answer lost on the way: the resend is answered the same, nothing is applied twice', () async {
    await store.record('cell.set', day(1), offline: true);
    server.loseNextAnswer = true;
    await engine.kick();
    expect(await store.pendingCount(), 1, reason: 'the phone does not know it was applied');
    await engine.kick();
    expect(await store.pendingCount(), 0);
    expect(server.applied, 1);
  });

  test('what was set aside is told once (H17)', () async {
    final m = await store.record('cell.set', day(1), offline: true);
    server.verdicts[m.id] = 'changed';
    await engine.kick();
    final told = engine.takeOutcomes();
    expect(told.single.status, 'changed');
    expect(engine.takeOutcomes(), isEmpty);
    expect(server.calls, ['pull', 'send', 'pull']);
  });

  test('the network coming back sends the queue without a gesture', () async {
    await store.record('cell.set', day(1), offline: true);
    server.failPosts = 1;
    await engine.kick();
    expect(engine.state, SyncState.offline);
    network.comeBack();
    await pumpEventQueue();
    await engine.idle;
    expect(await store.pendingCount(), 0);
    expect(engine.state, SyncState.online);
  });

  test('coming back after being offline is counted once, with what was sent', () async {
    await store.record('cell.set', day(1), offline: false);
    server.failPosts = 1;
    await engine.kick();
    expect(engine.returns, 0);
    await store.record('cell.set', day(2), offline: true);
    await engine.kick();
    expect(engine.returns, 1);
    expect(engine.returnedSent, 2);
    await engine.kick();
    expect(engine.returns, 1, reason: 'a cycle while online is not a return');
  });

  test('a launch that sends changes which waited is a return too', () async {
    await store.record('cell.set', day(1), offline: true);
    await engine.kick();
    expect((engine.returns, engine.returnedSent), (1, 1));
  });

  test('what was not kept and not told yet waits for the next launch', () async {
    final m = await store.record('cell.set', day(1), offline: true);
    server.verdicts[m.id] = 'changed';
    await engine.kick();
    expect(engine.hasOutcomes, isTrue);
    final next = SyncEngine(store: store, api: ApiService.custom(client: server.client, tokens: FakeTokens()), network: network, schedule: (delay, run) {});
    await next.restore();
    expect(next.hasOutcomes, isTrue);
    expect(next.takeOutcomes().single.status, 'changed');
    expect(next.hasOutcomes, isFalse);
    next.dispose();
  });

  test('changes that waited leave after the phone has read what changed meanwhile (H29)', () async {
    await store.record('cell.set', day(1), offline: true);
    await engine.kick();
    expect(server.calls, ['pull', 'send', 'pull']);
    server.calls.clear();
    await store.record('cell.set', day(2), offline: false);
    await engine.kick();
    expect(server.calls, ['send', 'pull'], reason: 'online, no extra read');
  });

  test('a change waits for the answer to an earlier one of its element, and leaves with its number (H28)', () async {
    final first = await store.record('cell.set', day(1), offline: false);
    server.loseNextAnswer = true;
    await engine.kick(); // applied on the server, its answer lost
    final second = await store.record('cell.set', {...day(1), 'color': '#654321'}, offline: true);
    server.batches.clear();
    await engine.kick();
    expect(server.batches, [[first.id], [second.id]], reason: 'never in the same batch');
    expect(server.bases[second.id], (server.answers[first.id]!['revs'] as Map)['element'], reason: 'the number the first one left');
  });

  test('a tracker created then renamed offline leaves in two steps, the rename with the creation\'s number', () async {
    const id = '33333333-3333-4333-8333-333333333333';
    final create = await store.record('page.create', {'id': id, 'title': 'New'}, offline: true);
    final rename = await store.record('page.update', {'id': id, 'title': 'Renamed'}, offline: true);
    await engine.kick();
    expect(server.batches, [[create.id], [rename.id]]);
    expect(server.bases[rename.id], (server.answers[create.id]!['revs'] as Map)['element']);
  });

  test('a tracker deletion waits for the answers to the changes before it in that tracker (C1)', () async {
    // A tracker the phone has (from the server), a day coloured in it, then the tracker deleted, offline.
    await store.applyServer(SyncDelta.fromJson({
      'rev': 5, 'full': true,
      'pages': [{'id': p1, 'title': 'T', 'position': 0, 'keepFree': false, 'createdAt': '', 'palette': null, 'rev': 5, 'editRev': 5, 'contentRev': 5, 'legendsOrderRev': 0}],
      'legends': [], 'cells': {}, 'deletions': [], 'legendsOrder': {}, 'settings': {}, 'premium': false, 'vip': false,
    }));
    final colour = await store.record('cell.set', day(1), offline: true);
    final delete = await store.record('page.delete', {'id': p1}, offline: true);
    server.contentRevs = true;
    await engine.kick();
    expect(server.batches, [[colour.id], [delete.id]]);
    expect(server.bases[delete.id], (server.answers[colour.id]!['revs'] as Map)['content'], reason: 'judged against the tracker as the day left it');
  });

  test('the legends of a tracker created offline then edited leave after it, with its number (C1)', () async {
    const id = '33333333-3333-4333-8333-333333333333';
    const legend = '55555555-5555-4555-8555-555555555555';
    final create = await store.record('page.create', {'id': id, 'title': 'New', 'legends': [{'id': legend, 'color': '#AAAAAA', 'label': 'A'}]}, offline: true);
    final rename = await store.record('legend.update', {'id': legend, 'label': 'B'}, offline: true);
    await engine.kick();
    expect(server.batches, [[create.id], [rename.id]]);
    expect(server.bases[rename.id], (server.answers[create.id]!['revs'] as Map)['element']);
  });

  test('what is still queued at launch has waited: it is judged by the offline rule (I3)', () async {
    await store.record('cell.set', day(1), offline: false); // the app was killed before it left
    final next = SyncEngine(store: store, api: ApiService.custom(client: server.client, tokens: FakeTokens()), network: network, schedule: (delay, run) {});
    await next.restore();
    expect((await store.pending()).single.waited, isTrue);
    next.dispose();
  });
}
