import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/token_store.dart';

class FakeTokens implements TokenStore {
  String? refresh;
  String? userId;
  FakeTokens({this.refresh});

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

void main() {
  test('single-flight refresh: concurrent 401s trigger one refresh and every request is retried', () async {
    var refreshCalls = 0;
    var validToken = 'old';
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        validToken = 'new';
        return http.Response(
          jsonEncode({'accessToken': 'new', 'refreshToken': 'r2', 'userId': 'u1'}),
          200,
        );
      }
      if (req.headers['Authorization'] != 'Bearer $validToken') {
        return http.Response('{"error":"expired"}', 401);
      }
      return http.Response('{"ok":true}', 200);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens(refresh: 'r1'));

    // No access token yet → every call 401s on its first attempt.
    final results = await Future.wait(List.generate(5, (_) => api.apiFetch('/api/pages')));

    expect(results.map((r) => r.statusCode), everyElement(200));
    expect(refreshCalls, 1);
  });

  test('a 401 seen after someone else already rotated the token just retries (no second refresh)', () async {
    var refreshCalls = 0;
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') {
        refreshCalls++;
        return http.Response(
          jsonEncode({'accessToken': 'fresh', 'refreshToken': 'r2', 'userId': 'u1'}),
          200,
        );
      }
      if (req.headers['Authorization'] != 'Bearer fresh') {
        return http.Response('{"error":"expired"}', 401);
      }
      return http.Response('{"ok":true}', 200);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens(refresh: 'r1'));
    // Prime the token through a restore, then a request issued with it succeeds
    // without any further refresh.
    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.ok);
    final r = await api.apiFetch('/api/pages');
    expect(r.statusCode, 200);
    expect(refreshCalls, 1);
  });

  test('invalid refresh (401) fires onAuthExpired and clears the stored session', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') return http.Response('{"error":"bad"}', 401);
      return http.Response('{}', 401);
    });
    final tokens = FakeTokens(refresh: 'r1')..userId = 'u1';
    final api = ApiService.custom(client: client, tokens: tokens);
    var expired = false;
    api.onAuthExpired = () => expired = true;

    final r = await api.apiFetch('/api/pages');

    expect(r.statusCode, 401);
    expect(expired, isTrue);
    expect(tokens.refresh, isNull);
    expect(tokens.userId, isNull);
  });

  test('offline refresh keeps the stored session and does not expire it', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') throw http.ClientException('no network');
      return http.Response('{}', 401);
    });
    final tokens = FakeTokens(refresh: 'r1');
    final api = ApiService.custom(client: client, tokens: tokens);
    var expired = false;
    api.onAuthExpired = () => expired = true;

    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.offline);
    expect(restore.profile, isNull);

    final r = await api.apiFetch('/api/pages');
    expect(r.statusCode, 401);
    expect(expired, isFalse);
    expect(tokens.refresh, 'r1');
  });

  test('a 5xx on refresh is transient, not a logout', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') return http.Response('oops', 503);
      return http.Response('{}', 401);
    });
    final tokens = FakeTokens(refresh: 'r1');
    final api = ApiService.custom(client: client, tokens: tokens);
    var expired = false;
    api.onAuthExpired = () => expired = true;

    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.offline);
    expect(expired, isFalse);
    expect(tokens.refresh, 'r1');
  });

  test('tryRestoreSession returns the profile, stores the new tokens and the userId', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({'accessToken': 'a', 'refreshToken': 'r2', 'userId': 'u1', 'vip': true}),
          200,
        ));
    final tokens = FakeTokens(refresh: 'r1');
    final api = ApiService.custom(client: client, tokens: tokens);
    Map<String, dynamic>? seen;
    api.onTokensRefreshed = (profile) => seen = profile;

    final restore = await api.tryRestoreSession();

    expect(restore.outcome, RefreshOutcome.ok);
    expect(restore.profile!['userId'], 'u1');
    expect(restore.profile!['vip'], isTrue);
    expect(tokens.refresh, 'r2');
    expect(tokens.userId, 'u1');
    expect(seen?['userId'], 'u1');
  });

  test('without a stored refresh token the session is invalid, not offline', () async {
    final client = MockClient((req) async => http.Response('{}', 200));
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.invalid);
  });
}
