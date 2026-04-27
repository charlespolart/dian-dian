import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  String? _accessToken;

  /// Called when both access and refresh tokens are expired.
  /// The caller should navigate the user to the login screen.
  VoidCallback? onAuthExpired;

  static String get baseUrl =>
      kDebugMode ? 'http://localhost:3001' : 'https://diandian.overridedev.com';

  String? get accessToken => _accessToken;

  // ---------------------------------------------------------------------------
  // Core fetch
  // ---------------------------------------------------------------------------

  /// Generic HTTP helper. Automatically attaches the access token and retries
  /// once after a transparent token refresh when the server returns 401.
  Future<http.Response> apiFetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _send(path, method: method, body: body, headers: headers);

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        return _send(path, method: method, body: body, headers: headers);
      }
      _handleAuthExpired();
    }

    return response;
  }

  Future<http.Response> _send(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      ...?headers,
    };

    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: mergedHeaders);
      case 'POST':
        return http.post(uri, headers: mergedHeaders, body: encodedBody);
      case 'PUT':
        return http.put(uri, headers: mergedHeaders, body: encodedBody);
      case 'PATCH':
        return http.patch(uri, headers: mergedHeaders, body: encodedBody);
      case 'DELETE':
        return http.delete(uri, headers: mergedHeaders, body: encodedBody);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // ---------------------------------------------------------------------------
  // Token refresh
  // ---------------------------------------------------------------------------

  Future<bool> _refreshTokens() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/api/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['accessToken'] as String;
        final newRefresh = data['refreshToken'] as String;
        await _storage.setRefreshToken(newRefresh);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    return false;
  }

  void _handleAuthExpired() {
    _accessToken = null;
    _storage.deleteRefreshToken();
    onAuthExpired?.call();
  }

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  /// Returns a map with `accessToken`, `refreshToken`, and `userId`.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    await _storage.setRefreshToken(data['refreshToken'] as String);
    return data;
  }

  /// Returns a map with `accessToken`, `refreshToken`, and `userId`.
  Future<Map<String, dynamic>> register(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    await _storage.setRefreshToken(data['refreshToken'] as String);
    return data;
  }

  Future<void> logout() async {
    try {
      await apiFetch('/api/auth/logout', method: 'POST');
    } finally {
      _accessToken = null;
      await _storage.deleteRefreshToken();
    }
  }

  /// Attempts to restore a previous session by refreshing the token pair.
  /// Returns `true` if the session was restored successfully.
  Future<bool> tryRestoreSession() async {
    return _refreshTokens();
  }

  Future<void> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
  }

  Future<Map<String, dynamic>> oauthSignIn({
    required String provider,
    required String identityToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/oauth');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'provider': provider, 'identityToken': identityToken}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    await _storage.setRefreshToken(data['refreshToken'] as String);
    return data;
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/reset-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
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
