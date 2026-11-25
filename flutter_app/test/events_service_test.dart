import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/events_service.dart';

import 'helpers.dart';

void main() {
  /// An API whose requests land in [requests] and are answered 204.
  ApiService recordingApi(List<http.Request> requests) => ApiService.custom(
        client: MockClient((req) async {
          requests.add(req);
          return http.Response('', 204);
        }),
        tokens: FakeTokens(),
      );

  test('track posts the event name with the platform and the app version', () async {
    final requests = <http.Request>[];
    final events = EventsService(api: recordingApi(requests), platform: () => 'ios', appVersion: () async => '1.5.0');
    await events.track('paywall.tracker_limit');
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/events');
    expect(jsonDecode(requests.single.body), {'name': 'paywall.tracker_limit', 'platform': 'ios', 'appVersion': '1.5.0'});
  });

  test('an origin that cannot be read is left out, and the event still goes', () async {
    final requests = <http.Request>[];
    final events = EventsService(
      api: recordingApi(requests),
      platform: () => null,
      appVersion: () async => throw StateError('no version'),
    );
    await expectLater(events.track('paywall.tracker_limit'), completes);
    expect(jsonDecode(requests.single.body), {'name': 'paywall.tracker_limit'});
  });

  test('by default the origin is this device and the installed version', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Dian Dian',
      packageName: 'app.mydiandian',
      version: '1.5.0',
      buildNumber: '412',
      buildSignature: '',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final requests = <http.Request>[];
    await EventsService(api: recordingApi(requests)).track('paywall.stats');
    expect(jsonDecode(requests.single.body), {'name': 'paywall.stats', 'platform': 'ios', 'appVersion': '1.5.0'});
  });

  test('currentPlatform names the platforms the stores ship, nothing else', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(EventsService.currentPlatform(), 'ios');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(EventsService.currentPlatform(), 'android');
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(EventsService.currentPlatform(), isNull);
  });

  test('a network failure is swallowed', () async {
    final client = MockClient((req) async => throw http.ClientException('offline'));
    final events = EventsService(
      api: ApiService.custom(client: client, tokens: FakeTokens()),
      platform: () => 'ios',
      appVersion: () async => '1.5.0',
    );
    await expectLater(events.track('paywall.tracker_limit'), completes);
  });
}
