import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/key_store.dart';
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
    ('{"error":"x","code":"invalid"}', 'a spent or expired session'),
    ('{"error":"x","code":"session_expired"}', 'an expired session (a server before chantier 9)'),
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

  // --- chantier 9, lot 1: a session that says why it ended, and the key ------

  test('a request refused with its reason ends the session at once, without renewing (cases 51, 52)', () async {
    for (final (code, end) in [('password_changed', SessionEnd.passwordChanged), ('session_revoked', SessionEnd.revoked), ('account_deleted', SessionEnd.accountDeleted)]) {
      final paths = <String>[];
      final client = MockClient((req) async {
        paths.add(req.url.path);
        return http.Response('{"error":"Session ended","code":"$code"}', 401);
      });
      final tokens = FakeTokens(refresh: 'r1')..userId = 'u1';
      final api = ApiService.custom(client: client, tokens: tokens);
      final ends = <SessionEnd>[];
      api.onSessionEnded = ends.add;
      await api.apiFetch('/api/pages');
      expect(ends, [end], reason: code);
      expect(paths, ['/api/pages'], reason: '$code: no renewal attempted');
    }
  });

  test('a refusal handed to the caller does not end the session for it (case 66)', () async {
    final client = MockClient((req) async => http.Response('{"error":"Session ended","code":"account_deleted"}', 401));
    final api = ApiService.custom(client: client, tokens: FakeTokens(refresh: 'r1')..userId = 'u1');
    final ends = <SessionEnd>[];
    api.onSessionEnded = ends.add;
    final r = await api.apiFetch('/api/auth/account', method: 'DELETE', handleSessionEnd: false);
    expect(r.statusCode, 401);
    expect(ends, isEmpty);
  });

  group('the key of an invisible account', () {
    const key = 'k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k';
    late List<http.Request> seen;

    ApiService api(Future<http.Response> Function(http.Request) answer, {String? refresh, FakeKeys? keys}) {
      seen = [];
      return ApiService.custom(
        client: MockClient((req) async {
          seen.add(req);
          return answer(req);
        }),
        tokens: FakeTokens(refresh: refresh)..userId = 'u1',
        keys: keys ?? (FakeKeys()..keys['u1'] = key..created.add('u1')),
      );
    }

    String session(String access) => jsonEncode({'accessToken': access, 'refreshToken': 'r-$access', 'userId': 'u1', 'kind': 'invisible', 'methods': []});

    test('a renewal refused reopens the session with the key, unseen (principle 4)', () async {
      final a = api((req) async => switch (req.url.path) {
            '/api/auth/refresh' => http.Response('{"error":"x","code":"invalid"}', 401),
            '/api/auth/key' => http.Response(session('a2'), 200),
            _ => req.headers['Authorization'] == 'Bearer a2' ? http.Response('[]', 200) : http.Response('{}', 401),
          }, refresh: 'r1');
      final ends = <SessionEnd>[];
      a.onSessionEnded = ends.add;
      final r = await a.apiFetch('/api/pages');
      expect(r.statusCode, 200);
      expect(ends, isEmpty);
      expect(seen.map((q) => q.url.path), ['/api/pages', '/api/auth/refresh', '/api/auth/key', '/api/pages']);
    });

    test('without any token, the key creates the account once, then reopens it (case 5)', () async {
      final keys = FakeKeys()..keys['u1'] = key;
      final a = api((req) async => switch (req.url.path) {
            '/api/auth/invisible' => http.Response(session('a1'), 201),
            '/api/auth/key' => http.Response(session('a3'), 200),
            _ => req.headers['Authorization'] == null ? http.Response('{"error":"Missing token"}', 401) : http.Response('[]', 200),
          }, keys: keys);
      expect((await a.apiFetch('/api/pages')).statusCode, 200);
      expect(keys.created, {'u1'}, reason: 'created: the next reopening goes through /key');
      expect(jsonDecode(seen.firstWhere((q) => q.url.path == '/api/auth/invisible').body), {'id': 'u1', 'key': key});
    });

    test('a deleted account: the session ends as deleted, and the key is forgotten', () async {
      final keys = FakeKeys()..keys['u1'] = key..created.add('u1');
      final a = api((req) async => req.url.path == '/api/auth/key'
          ? http.Response('{"error":"x","code":"account_deleted"}', 401)
          : http.Response('{}', 401), keys: keys);
      final ends = <SessionEnd>[];
      a.onSessionEnded = ends.add;
      await a.apiFetch('/api/pages');
      expect(ends, [SessionEnd.accountDeleted]);
      expect(keys.keys, isEmpty);
    });

    test('no network on the way, or an account the server never had: no session end, the phone keeps its copy', () async {
      for (final answer in [
        (http.Request req) async => req.url.path == '/api/auth/key' ? throw http.ClientException('no network') : http.Response('{}', 401),
        (http.Request req) async => req.url.path == '/api/auth/key' ? http.Response('{"code":"too_many"}', 429) : http.Response('{}', 401),
        (http.Request req) async => req.url.path == '/api/auth/key' ? http.Response('{"error":"x","code":"unknown"}', 401) : http.Response('{}', 401),
      ]) {
        final a = api(answer);
        final ends = <SessionEnd>[];
        a.onSessionEnded = ends.add;
        await expectLater(a.apiFetch('/api/pages'), throwsA(isA<ApiUnreachable>()));
        expect(ends, isEmpty);
      }
    });

    test('the key travels only to /invisible and /key, never with another request', () async {
      final a = api((req) async => switch (req.url.path) {
            '/api/auth/key' => http.Response(session('a2'), 200),
            _ => req.headers['Authorization'] == 'Bearer a2' ? http.Response('[]', 200) : http.Response('{}', 401),
          });
      await a.apiFetch('/api/pages');
      for (final q in seen.where((q) => q.url.path != '/api/auth/key')) {
        expect('${q.headers}${q.body}${q.url}'.contains(key), isFalse, reason: q.url.path);
      }
    });
  });
}

class FakeKeys implements KeyStore {
  final keys = <String, String>{};
  final created = <String>{};
  @override
  Future<String?> invisibleKey(String userId) async => keys[userId];
  @override
  Future<void> setInvisibleKey(String userId, String key) async => keys[userId] = key;
  @override
  Future<void> deleteInvisibleKey(String userId) async {
    keys.remove(userId);
    created.remove(userId);
  }

  @override
  Future<bool> invisibleCreated(String userId) async => created.contains(userId);
  @override
  Future<void> markInvisibleCreated(String userId) async => created.add(userId);
}
