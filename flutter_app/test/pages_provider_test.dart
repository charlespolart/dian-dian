import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
}
