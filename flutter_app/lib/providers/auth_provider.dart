import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/ws_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WsService _ws = WsService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _email;
  bool _isVip = false;

  // Server-synced settings (populated on login / restore)
  Map<String, dynamic>? _serverSettings;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  bool get isVip => _isVip;
  Map<String, dynamic>? get serverSettings => _serverSettings;

  AuthProvider() {
    _api.onAuthExpired = _onAuthExpired;
    tryRestoreSession();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> login(String email, String password) async {
    final data = await _api.login(email, password);
    _email = email;
    _isVip = data['vip'] == true;
    _serverSettings = {
      'theme': data['theme'],
      'language': data['language'],
      'cursorId': data['cursorId'],
      'cursorEnabled': data['cursorEnabled'],
      'premium': data['premium'],
    };
    await _storage.setEmail(email);
    _isAuthenticated = true;
    _ws.connect();
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    await _api.register(email, password);
    _email = email;
    _isVip = false;
    await _storage.setEmail(email);
    _isAuthenticated = true;
    _ws.connect();
    notifyListeners();
  }

  Future<void> logout() async {
    _ws.disconnect();
    try {
      await _api.logout();
    } finally {
      _email = null;
      _isAuthenticated = false;
      await _storage.deleteEmail();
      notifyListeners();
    }
  }

  Future<void> tryRestoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final restored = await _api.tryRestoreSession();
      _isAuthenticated = restored;
      if (restored) {
        _email = await _storage.getEmail();
        _ws.connect();
        // Fetch vip status + settings
        try {
          final response = await _api.apiFetch('/api/auth/me');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            _isVip = data['vip'] == true;
            _serverSettings = {
              'theme': data['theme'],
              'language': data['language'],
              'cursorId': data['cursorId'],
              'cursorEnabled': data['cursorEnabled'],
              'premium': data['premium'],
            };
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('AuthProvider: restore session failed: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onAuthExpired() {
    _ws.disconnect();
    _isAuthenticated = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _api.onAuthExpired = null;
    _ws.disconnect();
    super.dispose();
  }
}
