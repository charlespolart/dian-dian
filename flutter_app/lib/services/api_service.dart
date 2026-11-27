import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'key_store.dart';
import 'storage_service.dart';
import 'token_store.dart';
import 'dev_host.dart';

/// How a session renewal went. [offline] covers everything transient (no
/// network, timeout, 429, 5xx): the tokens are kept and the next request
/// tries again. Every other outcome but [ok] ends the session, with why:
/// [invalid], the server refused it (spent, expired, unknown) — log in
/// again, the phone's copy waits for it (H25); [accountDeleted], the account
/// was deleted (from another device): the copy goes too (H24);
/// [passwordChanged] and [revoked], the server closed it (chantier 9, cases
/// 51 and 52) — log in again, the copy waits.
enum RefreshOutcome {
  ok,
  invalid,
  accountDeleted,
  passwordChanged,
  revoked,
  offline;

  /// How the session ends on this outcome; null when it does not.
  SessionEnd? get end => switch (this) {
        RefreshOutcome.invalid => SessionEnd.reconnect,
        RefreshOutcome.accountDeleted => SessionEnd.accountDeleted,
        RefreshOutcome.passwordChanged => SessionEnd.passwordChanged,
        RefreshOutcome.revoked => SessionEnd.revoked,
        RefreshOutcome.ok || RefreshOutcome.offline => null,
      };
}

/// Why a session ended without the user asking.
enum SessionEnd {
  /// Log in again: the copy of the phone and its queue are kept, hidden,
  /// for that account (H25).
  reconnect,

  /// The account was deleted elsewhere: forget it, copy included (H24).
  accountDeleted,

  /// The password was changed by « mot de passe oublié » (case 51): log in
  /// again with the new one, the copy waits.
  passwordChanged,

  /// Another phone of the account closed this session (case 52): log in
  /// again, the copy waits.
  revoked;

  /// Whether the phone keeps the account's copy for the reconnection:
  /// every end but a deletion (H25).
  bool get keepsCopy => this != SessionEnd.accountDeleted;
}

class RestoreResult {
  final RefreshOutcome outcome;

  /// The user profile returned by `/api/auth/refresh` when [outcome] is [RefreshOutcome.ok].
  final Map<String, dynamic>? profile;

  const RestoreResult(this.outcome, this.profile);
}

/// A request that needed a new access token while the server could not be
/// reached: thrown like any network error.
class ApiUnreachable implements Exception {
  const ApiUnreachable();
  @override
  String toString() => 'ApiUnreachable: the session could not be renewed (no network)';
}

class ApiService {
  static final ApiService _instance = ApiService.custom();
  factory ApiService() => _instance;

  /// Non-singleton constructor: the injection seam for tests (a `MockClient`
  /// + in-memory tokens) and for the end-to-end harness.
  ApiService.custom({http.Client? client, TokenStore? tokens, KeyStore? keys})
      : _client = client ?? http.Client(),
        _tokens = tokens ?? StorageService(),
        _keys = keys ?? (tokens == null ? StorageService() : const NoKeys());

  /// One client for the whole app. The top-level `http.get()` helpers create
  /// and close a client per call, which costs a TCP + TLS handshake on every
  /// request; a shared client keeps connections alive and reuses them.
  final http.Client _client;
  final TokenStore _tokens;
  final KeyStore _keys;

  static const _timeout = Duration(seconds: 20);

  String? _accessToken;
  Map<String, dynamic>? _lastProfile;
  Future<RefreshOutcome>? _refreshInFlight;

  /// Called when the server refused the session for good, with why. The
  /// caller shows the login screen; it erases the account's copy only for
  /// [SessionEnd.accountDeleted].
  void Function(SessionEnd end)? onSessionEnded;

  /// Called after every successful token refresh with the user profile the
  /// server attached to it (lets an offline-started session fill in later).
  void Function(Map<String, dynamic> profile)? onTokensRefreshed;

  static String get baseUrl =>
      kDebugMode ? 'http://${devApiHost(android: Platform.isAndroid)}:3001' : 'https://diandian.overridedev.com';

  String? get accessToken => _accessToken;

  // ---------------------------------------------------------------------------
  // Core fetch
  // ---------------------------------------------------------------------------

  /// Generic HTTP helper. Attaches the access token and, on a 401, renews
  /// the session once (shared across concurrent callers) before retrying.
  ///
  /// A 401 that says why the server ended the session (chantier 9:
  /// `account_deleted`, `password_changed`, `session_revoked`) is not
  /// renewed: the session ends with that reason — unless the account is
  /// invisible, whose key reopens it (principle 4), or a deletion.
  /// With [handleSessionEnd] false, such a refusal is handed back to the
  /// caller instead, the session untouched: a retried deletion whose first
  /// answer was lost says itself that the data is gone (case 66).
  Future<http.Response> apiFetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool handleSessionEnd = true,
  }) async {
    final usedToken = _accessToken;
    final response = await _send(path, method: method, body: body, headers: headers);
    if (response.statusCode != 401) return response;

    // Another request already rotated the token while this one was in
    // flight: the current token is fresh, just retry with it.
    if (usedToken != _accessToken) {
      return _send(path, method: method, body: body, headers: headers);
    }

    final refused = _refusalOf(_refusalCode(response));
    if (refused != null && !handleSessionEnd) return response;
    final outcome = await _renew(refused: refused);
    switch (outcome) {
      case RefreshOutcome.ok:
        return _send(path, method: method, body: body, headers: headers);
      case RefreshOutcome.offline:
        // The token ran out and its renewal cannot reach the server: no
        // network, not a refused session (the sync retries, H5).
        throw const ApiUnreachable();
      case RefreshOutcome.invalid:
      case RefreshOutcome.accountDeleted:
      case RefreshOutcome.passwordChanged:
      case RefreshOutcome.revoked:
        if (handleSessionEnd) await _endSession(outcome.end!);
        return response;
    }
  }

  /// The live channel said the session ended (chantier 9): the same path as
  /// a request refused with that [code].
  Future<void> sessionEndedByServer(String? code) async {
    final end = (await _renew(refused: _refusalOf(code))).end;
    if (end != null) await _endSession(end);
  }

  Future<http.Response> _send(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse('$baseUrl$path');

    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      ...?headers,
    };

    final encodedBody = body != null ? jsonEncode(body) : null;

    final Future<http.Response> future;
    switch (method.toUpperCase()) {
      case 'GET':
        future = _client.get(uri, headers: mergedHeaders);
      case 'POST':
        future = _client.post(uri, headers: mergedHeaders, body: encodedBody);
      case 'PUT':
        future = _client.put(uri, headers: mergedHeaders, body: encodedBody);
      case 'PATCH':
        future = _client.patch(uri, headers: mergedHeaders, body: encodedBody);
      case 'DELETE':
        future = _client.delete(uri, headers: mergedHeaders, body: encodedBody);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
    return future.timeout(_timeout);
  }

  // ---------------------------------------------------------------------------
  // Token refresh
  // ---------------------------------------------------------------------------

  /// Single-flight: concurrent 401s share one renewal. Without this, N
  /// parallel requests hitting an expired access token each rotated the
  /// refresh token; only the first succeeded and the rest logged the user out.
  /// [refused]: the server already said why the session ended — its refresh
  /// token is not tried.
  Future<RefreshOutcome> _renew({RefreshOutcome? refused}) {
    // Block body on purpose: a `whenComplete` callback that *returns* a
    // future makes the chain wait for it (an arrow returning the cleared
    // slot would be fine here, but keep the shape obviously safe).
    return _refreshInFlight ??= _doRenew(refused).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<RefreshOutcome> _doRenew(RefreshOutcome? refused) async {
    final outcome = refused ?? await _doRefresh();
    switch (outcome) {
      case RefreshOutcome.ok:
      case RefreshOutcome.offline:
      case RefreshOutcome.accountDeleted:
        return outcome;
      case RefreshOutcome.invalid:
      case RefreshOutcome.passwordChanged:
      case RefreshOutcome.revoked:
        // Refused, lost or absent: an invisible account reopens its session
        // with its key, unseen (chantier 9, principle 4).
        return await _openWithKey() ?? outcome;
    }
  }

  /// Opens the session of this phone's invisible account with its key:
  /// `/api/auth/invisible` until the server has the account (the account is
  /// born at the first network, case 5), `/api/auth/key` after. Null when the
  /// phone holds no key for its account. A failure on the way (no network,
  /// 429, 5xx, an account the server does not have) is [RefreshOutcome.offline]:
  /// the phone keeps its copy, stays in, and tries again later.
  Future<RefreshOutcome?> _openWithKey() async {
    final userId = await _tokens.getUserId();
    if (userId == null) return null;
    final key = await _keys.invisibleKey(userId);
    if (key == null) return null;
    final created = await _keys.invisibleCreated(userId);
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/${created ? 'key' : 'invisible'}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': userId, 'key': key}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!created) await _keys.markInvisibleCreated(userId);
        await _sessionOpened(jsonDecode(response.body) as Map<String, dynamic>);
        return RefreshOutcome.ok;
      }
      final code = _refusalCode(response);
      if (code == 'account_deleted') return RefreshOutcome.accountDeleted;
      debugPrint('Key session not opened (${response.statusCode} $code): kept for later');
      return RefreshOutcome.offline;
    } catch (e) {
      // The type only: the request carried the key.
      debugPrint('Key session failed (transient): ${e.runtimeType}');
      return RefreshOutcome.offline;
    }
  }

  Future<RefreshOutcome> _doRefresh() async {
    final refreshToken = await _tokens.getRefreshToken();
    if (refreshToken == null) return RefreshOutcome.invalid;

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        await _sessionOpened(jsonDecode(response.body) as Map<String, dynamic>);
        return RefreshOutcome.ok;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return _refusalOf(_refusalCode(response)) ?? RefreshOutcome.invalid;
      }
      // 5xx / 429 / anything else: the server is unhappy, not the session.
      return RefreshOutcome.offline;
    } catch (e) {
      debugPrint('Token refresh failed (transient): $e');
      return RefreshOutcome.offline;
    }
  }

  Future<void> _sessionOpened(Map<String, dynamic> data) async {
    await _storeSession(data);
    _lastProfile = data;
    onTokensRefreshed?.call(data);
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    _accessToken = data['accessToken'] as String;
    await _tokens.setRefreshToken(data['refreshToken'] as String);
    final userId = data['userId'];
    if (userId is String) await _tokens.setUserId(userId);
  }

  /// The ending a refusal's code names (chantier 9), or null when it names
  /// none: a token that ran out, `invalid`, an older server's
  /// `session_expired`, no code at all.
  static RefreshOutcome? _refusalOf(String? code) => switch (code) {
        'account_deleted' => RefreshOutcome.accountDeleted,
        'password_changed' => RefreshOutcome.passwordChanged,
        'session_revoked' => RefreshOutcome.revoked,
        _ => null,
      };

  /// The `code` of a refusal (`account_deleted`, `password_changed`,
  /// `session_revoked`, `invalid`; an older server's `session_expired`), or null.
  static String? _refusalCode(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body is Map && body['code'] is String ? body['code'] as String : null;
    } catch (_) {
      return null;
    }
  }

  /// The session is over. The refused token goes; the account id stays
  /// unless the account itself was deleted: it says whose copy the phone
  /// keeps for the reconnection. A deleted account's key goes with it.
  Future<void> _endSession(SessionEnd end, {bool notify = true}) async {
    _accessToken = null;
    _lastProfile = null;
    await _tokens.deleteRefreshToken();
    if (end == SessionEnd.accountDeleted) {
      final userId = await _tokens.getUserId();
      if (userId != null) await _keys.deleteInvisibleKey(userId);
      await _tokens.deleteUserId();
    }
    if (notify) onSessionEnded?.call(end);
  }

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _authPost(String path, Map<String, dynamic> body, {Set<int> ok = const {200}}) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (!ok.contains(response.statusCode)) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Returns the session payload (`accessToken`, `refreshToken`, `userId`, profile).
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _authPost('/api/auth/login', {'email': email, 'password': password});
    await _storeSession(data);
    _lastProfile = data;
    return data;
  }

  /// Returns the session payload (`accessToken`, `refreshToken`, `userId`, profile).
  Future<Map<String, dynamic>> register(String email, String password) async {
    final data = await _authPost(
      '/api/auth/register',
      {'email': email, 'password': password},
      ok: const {200, 201},
    );
    await _storeSession(data);
    _lastProfile = data;
    return data;
  }

  Future<void> logout() async {
    try {
      await apiFetch('/api/auth/logout', method: 'POST');
    } finally {
      _accessToken = null;
      _lastProfile = null;
      await _tokens.deleteRefreshToken();
      await _tokens.deleteUserId();
    }
  }

  /// Attempts to restore a previous session by refreshing the token pair,
  /// or, for an invisible account, by its key (which creates the account
  /// on the server the first time, case 5).
  Future<RestoreResult> tryRestoreSession() async {
    final outcome = await _renew();
    // The caller reads the outcome itself: the tokens are settled here, the
    // callback is not fired.
    final end = outcome.end;
    if (end != null) await _endSession(end, notify: false);
    return RestoreResult(outcome, outcome == RefreshOutcome.ok ? _lastProfile : null);
  }

  Future<void> forgotPassword(String email) async {
    await _authPost('/api/auth/forgot-password', {'email': email});
  }

  Future<Map<String, dynamic>> oauthSignIn({
    required String provider,
    required String identityToken,
  }) async {
    final data = await _authPost(
      '/api/auth/oauth',
      {'provider': provider, 'identityToken': identityToken},
      ok: const {200, 201},
    );
    await _storeSession(data);
    _lastProfile = data;
    return data;
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _authPost('/api/auth/reset-password', {'email': email, 'code': code, 'password': password});
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['message'] ?? data['error'] ?? response.body) as String;
    } catch (_) {
      return response.body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
