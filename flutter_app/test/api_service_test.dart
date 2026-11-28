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

  group('a deletion asked on this phone (cases 65 and 66)', () {
    late List<String> paths;
    late FakeKeys keys;
    late FakeTokens tokens;

    ApiService api(Future<http.Response> Function(http.Request) answer) {
      paths = [];
      return ApiService.custom(
        client: MockClient((req) async {
          paths.add('${req.method} ${req.url.path}');
          return answer(req);
        }),
        tokens: tokens,
        keys: keys,
      );
    }

    setUp(() {
      keys = FakeKeys();
      tokens = FakeTokens(refresh: 'r1')..userId = 'u1';
    });

    test('its answer lost: a later « account deleted » is this deletion, never « deleted on another device » (review, important 1)', () async {
      var deleted = false;
      final a = api((req) async {
        if (req.method == 'DELETE') {
          deleted = true; // done on the server…
          throw http.ClientException('connection reset'); // …and the answer lost
        }
        if (req.url.path == '/api/auth/refresh') return http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1'}), 200);
        return deleted ? http.Response('{"error":"Session ended","code":"account_deleted"}', 401) : http.Response('{}', 200);
      });
      final ends = <SessionEnd>[];
      a.onSessionEnded = ends.add;
      expect(await a.deleteAccount(), isFalse, reason: 'the phone cannot know yet');
      expect(ends, isEmpty);
      await a.apiFetch('/api/sync?since=0'); // the sync's next request
      expect(ends, [SessionEnd.deletedHere]);
      expect(tokens.userId, isNull);
      expect(keys.asked, isEmpty, reason: 'forgotten with the account');
    });

    test('its answer lost, then the app closed: at the next launch too', () async {
      final first = api((req) async => req.method == 'DELETE'
          ? throw http.ClientException('connection reset')
          : http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1'}), 200));
      await first.tryRestoreSession();
      expect(await first.deleteAccount(), isFalse);
      final relaunched = api((req) async => http.Response('{"error":"x","code":"account_deleted"}', 401));
      final r = await relaunched.tryRestoreSession();
      expect(r.end, SessionEnd.deletedHere);
    });

    test('refused because the session had already ended for another reason: that reason ends it, not « réessayez » (review, minor 4)', () async {
      final a = api((req) async => http.Response('{"error":"Session ended","code":"password_changed"}', 401));
      final ends = <SessionEnd>[];
      a.onSessionEnded = ends.add;
      expect(await a.deleteAccount(), isFalse);
      expect(ends, [SessionEnd.passwordChanged]);
    });

    test('an invisible account the server never had is deleted on the phone alone, without the network (review, minor 3)', () async {
      keys.keys['u1'] = 'k';
      tokens.refresh = null;
      final a = api((req) async => throw http.ClientException('no network'));
      final ends = <SessionEnd>[];
      a.onSessionEnded = ends.add;
      expect(await a.deletesOnPhoneOnly(), isTrue);
      expect(await a.deleteAccount(), isTrue);
      expect(paths, isEmpty);
      expect(ends, [SessionEnd.deletedHere]);
      expect(keys.keys, isEmpty);
    });
  });

  test('a session ends once, however many requests learn it at the same time (review, minor 5)', () async {
    final client = MockClient((req) async => http.Response('{"error":"Session ended","code":"session_revoked"}', 401));
    final api = ApiService.custom(client: client, tokens: FakeTokens(refresh: 'r1')..userId = 'u1');
    final ends = <SessionEnd>[];
    api.onSessionEnded = ends.add;
    await Future.wait([api.apiFetch('/api/pages'), api.apiFetch('/api/sync?since=0'), api.sessionEndedByServer('session_revoked')]);
    expect(ends, [SessionEnd.revoked]);
  });

  test('a refusal with its reason drops the access token even when the key cannot reach the server (review, minor 10)', () async {
    final keys = FakeKeys()..keys['u1'] = 'k'..created.add('u1');
    final api = ApiService.custom(
      client: MockClient((req) async => req.url.path == '/api/auth/key'
          ? throw http.ClientException('no network')
          : req.url.path == '/api/auth/refresh'
              ? http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1'}), 200)
              : http.Response('{"error":"Session ended","code":"session_revoked"}', 401)),
      tokens: FakeTokens(refresh: 'r1')..userId = 'u1',
      keys: keys,
    );
    await api.tryRestoreSession();
    expect(api.accessToken, 'a1');
    await expectLater(api.apiFetch('/api/pages'), throwsA(isA<ApiUnreachable>()));
    expect(api.accessToken, isNull, reason: 'a dead token is not kept to be refused again');
  });

  test('an invisible account the server does not have yet goes to /invisible, never through a stray refresh token (review, minor 1)', () async {
    final keys = FakeKeys()..keys['u1'] = 'k';
    final paths = <String>[];
    final api = ApiService.custom(
      client: MockClient((req) async {
        paths.add(req.url.path);
        return switch (req.url.path) {
          '/api/auth/refresh' => http.Response(jsonEncode({'accessToken': 'x', 'refreshToken': 'x', 'userId': 'someone-else'}), 200),
          '/api/auth/invisible' => http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1'}), 201),
          _ => http.Response('{}', 404),
        };
      }),
      tokens: FakeTokens(refresh: 'stale')..userId = 'u1',
      keys: keys,
    );
    final r = await api.tryRestoreSession();
    expect(r.outcome, RefreshOutcome.ok);
    expect(paths, ['/api/auth/invisible']);
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
  final asked = <String>{};
  @override
  Future<void> forgetAccount(String userId) async {
    keys.remove(userId);
    created.remove(userId);
    asked.remove(userId);
  }

  @override
  Future<bool> invisibleCreated(String userId) async => created.contains(userId);
  @override
  Future<void> markInvisibleCreated(String userId) async => created.add(userId);
  @override
  Future<bool> deletionAsked(String userId) async => asked.contains(userId);
  @override
  Future<void> markDeletionAsked(String userId) async => asked.add(userId);
}
