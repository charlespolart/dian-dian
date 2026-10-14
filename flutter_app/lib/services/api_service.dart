import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';
import 'token_store.dart';

/// What a refresh attempt concluded about the stored session.
///
/// Only [invalid] means the session is gone. [offline] covers everything
/// transient (no network, timeout, 5xx): the refresh token is kept and the
/// next request tries again.
enum RefreshOutcome { ok, invalid, offline }

class RestoreResult {
  final RefreshOutcome outcome;

  /// The user profile returned by `/api/auth/refresh` when [outcome] is [RefreshOutcome.ok].
  final Map<String, dynamic>? profile;

  const RestoreResult(this.outcome, this.profile);
}

class ApiService {
  static final ApiService _instance = ApiService.custom();
  factory ApiService() => _instance;

  /// Non-singleton constructor: the injection seam for tests (a `MockClient`
  /// + in-memory tokens) and for the end-to-end harness.
  ApiService.custom({http.Client? client, TokenStore? tokens})
      : _client = client ?? http.Client(),
        _tokens = tokens ?? StorageService();

  /// One client for the whole app. The top-level `http.get()` helpers create
  /// and close a client per call, which costs a TCP + TLS handshake on every
  /// request; a shared client keeps connections alive and reuses them.
  final http.Client _client;
  final TokenStore _tokens;

  static const _timeout = Duration(seconds: 20);

  String? _accessToken;
  Map<String, dynamic>? _lastProfile;
  Future<RefreshOutcome>? _refreshInFlight;

  /// Called when both access and refresh tokens are definitively invalid.
  /// The caller should navigate the user to the login screen.
  VoidCallback? onAuthExpired;

  /// Called after every successful token refresh with the user profile the
  /// server attached to it (lets an offline-started session fill in later).
  void Function(Map<String, dynamic> profile)? onTokensRefreshed;

  static String get baseUrl =>
      kDebugMode ? 'http://localhost:3001' : 'https://diandian.overridedev.com';

  String? get accessToken => _accessToken;

  // ---------------------------------------------------------------------------
  // Core fetch
  // ---------------------------------------------------------------------------

  /// Generic HTTP helper. Attaches the access token and, on a 401, refreshes
  /// once (shared across concurrent callers) before retrying.
  Future<http.Response> apiFetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final usedToken = _accessToken;
    final response = await _send(path, method: method, body: body, headers: headers);
    if (response.statusCode != 401) return response;

    // Another request already rotated the token while this one was in
    // flight: the current token is fresh, just retry with it.
    if (usedToken != _accessToken) {
      return _send(path, method: method, body: body, headers: headers);
    }

    switch (await _refreshTokens()) {
      case RefreshOutcome.ok:
        return _send(path, method: method, body: body, headers: headers);
      case RefreshOutcome.invalid:
        _handleAuthExpired();
        return response;
      case RefreshOutcome.offline:
        return response;
    }
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

  /// Single-flight: concurrent 401s share one refresh. Without this, N
  /// parallel requests hitting an expired access token each rotated the
  /// refresh token; only the first succeeded and the rest logged the user out.
  Future<RefreshOutcome> _refreshTokens() {
    // Block body on purpose: a `whenComplete` callback that *returns* a
    // future makes the chain wait for it (an arrow returning the cleared
    // slot would be fine here, but keep the shape obviously safe).
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storeSession(data);
        _lastProfile = data;
        onTokensRefreshed?.call(data);
        return RefreshOutcome.ok;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return RefreshOutcome.invalid;
      }
      // 5xx / 429 / anything else: the server is unhappy, not the session.
      return RefreshOutcome.offline;
    } catch (e) {
      debugPrint('Token refresh failed (transient): $e');
      return RefreshOutcome.offline;
    }
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    _accessToken = data['accessToken'] as String;
    await _tokens.setRefreshToken(data['refreshToken'] as String);
    final userId = data['userId'];
    if (userId is String) await _tokens.setUserId(userId);
  }

  void _handleAuthExpired() {
    _accessToken = null;
    _lastProfile = null;
    _tokens.deleteRefreshToken();
    _tokens.deleteUserId();
    onAuthExpired?.call();
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

  /// Attempts to restore a previous session by refreshing the token pair.
  Future<RestoreResult> tryRestoreSession() async {
    final outcome = await _refreshTokens();
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
