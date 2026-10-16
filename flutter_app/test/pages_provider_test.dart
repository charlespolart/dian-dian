import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/models/page_model.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/ws_service.dart';

import 'helpers.dart';

void main() {
  PagesProvider withServer(int deleteStatus) {
    final client = MockClient((req) async {
      if (req.method == 'DELETE') return http.Response('{"error":"x"}', deleteStatus);
      return http.Response('{}', 200);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    return PagesProvider(api: api)..applyBootstrap([pageJson('a'), pageJson('b', position: 1)]);
  }

  test('deletePage puts the page back when the server fails', () async {
    final p = withServer(500);
    await p.deletePage('a');
    expect(p.pages.map((x) => x.id), containsAll(['a', 'b']));
  });

  test('deletePage drops the page on 404 (already gone server-side)', () async {
    final p = withServer(404);
    await p.deletePage('a');
    expect(p.pages.map((x) => x.id), ['b']);
  });

  test('mutationEpoch increments on local and WS changes, not on applyBootstrap', () {
    final p = withServer(200);
    final e0 = p.mutationEpoch;
    p.applyBootstrap([pageJson('a')]);
    expect(p.mutationEpoch, e0);
    p.debugHandleWs(WsMessage(event: 'page:created', data: pageJson('c', position: 2)));
    expect(p.mutationEpoch, e0 + 1);
    expect(p.pages.map((x) => x.id), containsAll(['a', 'c']));
    p.debugHandleWs(const WsMessage(event: 'pages:reordered', data: {'ids': ['c', 'a']}));
    expect(p.mutationEpoch, e0 + 2);
    expect(p.pages.map((x) => x.id), ['c', 'a']);
  });

  PagesProvider withClient(MockClient client, List<Map<String, dynamic>> pages) =>
      PagesProvider(api: ApiService.custom(client: client, tokens: FakeTokens()))..applyBootstrap(pages);

  test('createFirstTracker sends title, legends and position, stores the page and returns its legends', () async {
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response(jsonEncode({
        ...pageJson('n', position: 2, title: 'Humeur'),
        'legends': [legendJson('l1', 'n', '#FFEC99', 0), legendJson('l2', 'n', '#FFD43B', 1)],
        'replaced': null,
      }), 201);
    });
    final p = withClient(client, [pageJson('a'), pageJson('b', position: 1)]);
    final created = await p.createFirstTracker(
      title: 'Humeur',
      legends: const [(color: '#FFEC99', label: 'Génial'), (color: '#FFD43B', label: 'Super')],
    );
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/pages');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['title'], 'Humeur');
    expect(body['position'], 2);
    expect(body.containsKey('replaces'), isFalse);
    expect(body['legends'], [
      {'color': '#FFEC99', 'label': 'Génial'},
      {'color': '#FFD43B', 'label': 'Super'},
    ]);
    expect(created!.page.id, 'n');
    expect(created.legends.map((l) => l.id), ['l1', 'l2']);
    expect(p.pages.map((x) => x.id), ['a', 'b', 'n']);
  });

  test('createFirstTracker with replaces omits position, drops the replaced page and keeps its slot', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({
        ...pageJson('n', position: 0, title: 'Humeur'), 'legends': <dynamic>[], 'replaced': 'a',
      }), 201);
    });
    final p = withClient(client, [pageJson('a'), pageJson('b', position: 1)]);
    final created = await p.createFirstTracker(title: 'Humeur', legends: const [], replaces: 'a');
    expect(sent['replaces'], 'a');
    expect(sent.containsKey('position'), isFalse);
    expect(created, isNotNull);
    expect(p.pages.map((x) => x.id), ['n', 'b']);
  });

  test('createFirstTracker retries once without replaces when the server says 404 or 409', () async {
    final bodies = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      bodies.add(body);
      if (body.containsKey('replaces')) return http.Response('{"error":"Page is not empty"}', 409);
      return http.Response(jsonEncode({...pageJson('n', position: 1), 'legends': <dynamic>[], 'replaced': null}), 201);
    });
    final p = withClient(client, [pageJson('a')]);
    final created = await p.createFirstTracker(title: 'X', legends: const [], replaces: 'a');
    expect(bodies.length, 2);
    expect(bodies.last.containsKey('replaces'), isFalse);
    expect(bodies.last['position'], 1);
    expect(created!.page.id, 'n');
    expect(p.pages.map((x) => x.id), ['a', 'n'], reason: 'the page that could not be replaced stays');
  });

  test('createFirstTracker returns null and changes nothing on a server error', () async {
    final client = MockClient((req) async => http.Response('{"error":"x"}', 500));
    final p = withClient(client, [pageJson('a')]);
    expect(await p.createFirstTracker(title: 'X', legends: const []), isNull);
    expect(p.pages.map((x) => x.id), ['a']);
  });

  test('createFirstTracker does not fall back without replaces when the caller forbids it (free limit)', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      return http.Response('{"error":"Page is not empty"}', 409);
    });
    final p = withClient(client, [pageJson('a'), pageJson('b', position: 1), pageJson('c', position: 2)]);
    final created = await p.createFirstTracker(
      title: 'X', legends: const [], replaces: 'a', fallbackWithoutReplaces: false,
    );
    expect(created, isNull);
    expect(calls, 1, reason: 'no second request');
    expect(p.pages.map((x) => x.id), ['a', 'b', 'c']);
  });

  test('keepFree sends the ids, flags them locally and clears the others', () async {
    late Map<String, dynamic> sent;
    late String path;
    final client = MockClient((req) async {
      path = '${req.method} ${req.url.path}';
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{"ok":true}', 200);
    });
    final p = withClient(client, [pageJson('a', keepFree: true), pageJson('b', position: 1), pageJson('c', position: 2)]);
    final ok = await p.keepFree(['b', 'c']);
    expect(ok, isTrue);
    expect(path, 'PUT /api/pages/keep');
    expect(sent, {'ids': ['b', 'c']});
    expect(p.pages.map((x) => '${x.id}:${x.keepFree}'), ['a:false', 'b:true', 'c:true']);
  });

  test('keepFree reverts the flags when the server refuses', () async {
    final client = MockClient((req) async => http.Response('{"error":"x"}', 500));
    final p = withClient(client, [pageJson('a', keepFree: true), pageJson('b', position: 1)]);
    expect(await p.keepFree(['b']), isFalse);
    expect(p.pages.map((x) => '${x.id}:${x.keepFree}'), ['a:true', 'b:false']);
  });

  test('pages:kept from another device applies the choice', () {
    final p = withServer(200);
    p.debugHandleWs(const WsMessage(event: 'pages:kept', data: {'ids': ['b']}));
    expect(p.pages.map((x) => '${x.id}:${x.keepFree}'), ['a:false', 'b:true']);
  });

  test('PageModel reads activity and keepFree, defaults when absent (snapshot of 1.3.0)', () {
    final full = PageModel.fromJson(pageJson('a', recentCells: 7, lastCellAt: '2026-10-15T00:00:00Z', keepFree: true));
    expect(full.recentCells, 7);
    expect(full.lastCellAt, '2026-10-15T00:00:00Z');
    expect(full.keepFree, isTrue);
    final old = PageModel.fromJson({'id': 'b', 'userId': 'u1', 'title': 'T', 'year': 2026, 'position': 0, 'palette': null, 'createdAt': ''});
    expect(old.recentCells, 0);
    expect(old.lastCellAt, isNull);
    expect(old.keepFree, isFalse);
    expect(PageModel.fromJson(full.toJson()).keepFree, isTrue, reason: 'round-trips through the snapshot');
  });

  test('createFirstTracker forwards the clientId and accepts a 200 replay', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({...pageJson('n', title: 'X'), 'legends': <dynamic>[], 'replaced': null}), 200);
    });
    final p = withClient(client, const []);
    final created = await p.createFirstTracker(
      title: 'X', legends: const [], clientId: '11111111-1111-4111-8111-111111111111',
    );
    expect(sent['clientId'], '11111111-1111-4111-8111-111111111111');
    expect(created!.page.id, 'n');
    expect(p.pages.single.id, 'n');
  });
}
