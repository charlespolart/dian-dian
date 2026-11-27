import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/auth_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/storage_service.dart';

import 'sync_fakes.dart';

/// The phone's secure storage, in memory.
class FakeStorage implements StorageService {
  final values = <String, String>{};
  @override
  Future<String?> getRefreshToken() async => values['refresh'];
  @override
  Future<void> setRefreshToken(String token) async => values['refresh'] = token;
  @override
  Future<void> deleteRefreshToken() async => values.remove('refresh');
  @override
  Future<String?> getUserId() async => values['user'];
  @override
  Future<void> setUserId(String id) async => values['user'] = id;
  @override
  Future<void> deleteUserId() async => values.remove('user');
  @override
  Future<String?> getEmail() async => values['email'];
  @override
  Future<void> setEmail(String email) async => values['email'] = email;
  @override
  Future<void> deleteEmail() async => values.remove('email');
  @override
  Future<String?> invisibleKey(String userId) async => values['key:$userId'];
  @override
  Future<void> setInvisibleKey(String userId, String key) async => values['key:$userId'] = key;
  @override
  Future<void> deleteInvisibleKey(String userId) async {
    values.remove('key:$userId');
    values.remove('created:$userId');
  }

  @override
  Future<bool> invisibleCreated(String userId) async => values['created:$userId'] == 'yes';
  @override
  Future<void> markInvisibleCreated(String userId) async => values['created:$userId'] = 'yes';
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a launch lands at once only on a session still held: an account id and its renewal token (review, minor 1)', () {
    expect(AuthProvider.landsAtOnce(storedUserId: 'u1', refreshToken: 'r'), isTrue);
    expect(AuthProvider.landsAtOnce(storedUserId: 'u1', refreshToken: null), isFalse,
        reason: 'a session the server closed keeps the account id for the reconnection (H25), not a session: no flash of the trackers, no message again');
    expect(AuthProvider.landsAtOnce(storedUserId: null, refreshToken: 'r'), isFalse);
    expect(AuthProvider.landsAtOnce(storedUserId: 'u1', refreshToken: null, hasKey: true), isTrue,
        reason: 'an invisible account lands at once on its key, even before the server has it (case 5)');
  });

  late ApiService api;
  AuthProvider build(Future<http.Response> Function(http.Request) answer, FakeStorage storage, {FakeWs? ws}) {
    api = ApiService.custom(client: MockClient(answer), tokens: storage, keys: storage);
    return AuthProvider.custom(api: api, ws: ws ?? FakeWs(), storage: storage);
  }

  test('« Continuer sans compte » offline: the app is usable at once, under the id the phone chose (case 5)', () async {
    final storage = FakeStorage();
    final auth = build((req) async => throw http.ClientException('no network'), storage);
    await settle();
    expect(auth.isAuthenticated, isFalse);

    await auth.continueWithoutAccount();

    expect(auth.isAuthenticated, isTrue);
    expect(auth.userId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(storage.values['user'], auth.userId);
    expect(storage.values['key:${auth.userId}'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')), reason: '32 bytes, base64url');
    expect(auth.kind, isNull, reason: 'the server has not said yet (principle 5)');
    expect(auth.email, isNull);
  });

  test('« Continuer sans compte » online: the account is born, and the server says it is invisible', () async {
    final storage = FakeStorage();
    final sent = <String>[];
    final auth = build((req) async {
      sent.add(req.url.path);
      if (req.url.path == '/api/auth/invisible') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r1', 'userId': body['id'], 'email': null, 'kind': 'invisible', 'methods': []}), 201);
      }
      return http.Response('{}', 401);
    }, storage);
    await settle();
    await auth.continueWithoutAccount();
    await settle();
    expect(sent, contains('/api/auth/invisible'));
    expect(auth.kind, 'invisible');
    expect(auth.methods, isEmpty);
    expect(auth.isOffline, isFalse);
    expect(storage.values['created:${auth.userId}'], 'yes');
  });

  test('a session end, whatever it is, forgets the address kept on the phone (case 68)', () async {
    for (final code in ['password_changed', 'session_revoked', 'account_deleted']) {
      final storage = FakeStorage()
        ..values['user'] = 'u1'
        ..values['refresh'] = 'r1'
        ..values['email'] = 'old@example.com';
      final auth = build((req) async {
        if (req.url.path == '/api/auth/refresh') {
          return http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1', 'email': 'old@example.com', 'kind': 'attached', 'methods': ['email', 'password']}), 200);
        }
        return http.Response(jsonEncode({'error': 'Session ended', 'code': code}), 401);
      }, storage);
      await settle();
      expect(auth.kind, 'attached');
      expect(auth.methods, ['email', 'password']);
      await api.apiFetch('/api/pages');
      await settle();
      expect(auth.isAuthenticated, isFalse, reason: code);
      expect(storage.values['email'], isNull, reason: code);
      expect(auth.email, isNull);
    }
  });

  test('the address is the one the server sends, never one kept from before (ruling 11)', () async {
    final storage = FakeStorage()
      ..values['user'] = 'u1'
      ..values['refresh'] = 'r1'
      ..values['email'] = 'stale@example.com';
    final auth = build((req) async => http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1', 'email': null, 'kind': 'invisible', 'methods': []}), 200), storage);
    await settle();
    expect(auth.email, isNull);
    expect(storage.values['email'], isNull);
  });

  test('the live channel saying the session ended ends it like a refused request (ruling 21)', () async {
    final storage = FakeStorage()
      ..values['user'] = 'u1'
      ..values['refresh'] = 'r1';
    final ws = FakeWs();
    final auth = build((req) async {
      if (req.url.path == '/api/auth/refresh' && storage.values['refresh'] == 'r1') {
        return http.Response(jsonEncode({'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1', 'email': 'a@b.fr', 'kind': 'attached', 'methods': ['email']}), 200);
      }
      return http.Response('{"code":"session_revoked"}', 401);
    }, storage, ws: ws);
    await settle();
    expect(auth.isAuthenticated, isTrue);
    ws.receive('session:ended', {'code': 'session_revoked'});
    await settle();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionEnded, SessionEnd.revoked);
  });

  test('a deletion ends with the copy forgotten; every other end keeps it for the reconnection', () {
    expect(SessionEnd.values.where((e) => !e.keepsCopy), [SessionEnd.accountDeleted]);
  });
}
