import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/events_service.dart';

import 'helpers.dart';

void main() {
  test('track posts the event name and never throws', () async {
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response('', 204);
    });
    final events = EventsService(api: ApiService.custom(client: client, tokens: FakeTokens()));
    await events.track('paywall.tracker_limit');
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/events');
    expect(jsonDecode(requests.single.body), {'name': 'paywall.tracker_limit'});
  });

  test('a network failure is swallowed', () async {
    final client = MockClient((req) async => throw http.ClientException('offline'));
    final events = EventsService(api: ApiService.custom(client: client, tokens: FakeTokens()));
    await expectLater(events.track('paywall.tracker_limit'), completes);
  });
}
