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

  // A refused renewal ends the session but keeps the account id: the copy of
  // the phone and its queue wait, hidden, for a reconnection to that account
  // (offline sync, H25). Only a deleted account forgets it (H24).
  for (final (body, label) in [
    ('{"error":"x","code":"session_revoked"}', 'a session closed by the server'),
    ('{"error":"x","code":"session_expired"}', 'an expired session'),
    ('{"error":"bad"}', 'a refusal without a reason (an older server)'),
  ]) {
    test('$label: the session ends with "log in again", the account id is kept', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/api/auth/refresh') return http.Response(body, 401);
        return http.Response('{}', 401);
      });
      final tokens = FakeTokens(refresh: 'r1')..userId = 'u1';
      final api = ApiService.custom(client: client, tokens: tokens);
      final ends = <SessionEnd>[];
      api.onSessionEnded = ends.add;

      final r = await api.apiFetch('/api/pages');

      expect(r.statusCode, 401);
      expect(ends, [SessionEnd.reconnect]);
      expect(tokens.refresh, isNull, reason: 'the refused token is gone');
      expect(tokens.userId, 'u1', reason: 'the account the copy belongs to is remembered');
    });
  }

  test('a deleted account ends the session and forgets the account (H24)', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') return http.Response('{"error":"x","code":"account_deleted"}', 401);
      return http.Response('{}', 401);
    });
    final tokens = FakeTokens(refresh: 'r1')..userId = 'u1';
    final api = ApiService.custom(client: client, tokens: tokens);
    final ends = <SessionEnd>[];
    api.onSessionEnded = ends.add;

    await api.apiFetch('/api/pages');

    expect(ends, [SessionEnd.accountDeleted]);
    expect(tokens.refresh, isNull);
    expect(tokens.userId, isNull);
  });

  test('at launch, a refused session is reported with its reason', () async {
    final client = MockClient((req) async => http.Response('{"error":"x","code":"account_deleted"}', 401));
    final tokens = FakeTokens(refresh: 'r1')..userId = 'u1';
    final api = ApiService.custom(client: client, tokens: tokens);

    final r = await api.tryRestoreSession();

    expect(r.outcome, RefreshOutcome.accountDeleted);
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
    api.onSessionEnded = (_) => expired = true;

    final restore = await api.tryRestoreSession();
    expect(restore.outcome, RefreshOutcome.offline);
    expect(restore.profile, isNull);

    // The access token ran out and the renewal cannot reach the server: that
    // is no network, not a refused session (minor 10 of the review).
    await expectLater(api.apiFetch('/api/pages'), throwsA(isA<ApiUnreachable>()));
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
    api.onSessionEnded = (_) => expired = true;

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
