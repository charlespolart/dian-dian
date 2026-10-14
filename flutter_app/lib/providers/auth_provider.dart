import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/ws_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _vipKey = 'is_vip';

  final ApiService _api = ApiService();
  final WsService _ws = WsService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  // Session restored from storage without a network confirmation (airplane
  // mode at launch). Cleared by the first successful token refresh.
  bool _isOffline = false;
  String? _email;
  String? _userId;
  bool _isVip = false;

  // Server-synced settings (populated on login / restore / refresh)
  Map<String, dynamic>? _serverSettings;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOffline => _isOffline;
  String? get email => _email;
  String? get userId => _userId;
  bool get isVip => _isVip;
  Map<String, dynamic>? get serverSettings => _serverSettings;

  AuthProvider() {
    _api.onAuthExpired = _onAuthExpired;
    _api.onTokensRefreshed = _onTokensRefreshed;
    tryRestoreSession();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> login(String email, String password) async {
    final data = await _api.login(email, password);
    await _applySession(data, email: email);
  }

  Future<void> register(String email, String password) async {
    final data = await _api.register(email, password);
    await _applySession(data, email: email);
  }

  /// Signs in (or signs up) via Apple/Google. Pass the provider id ('apple' or
  /// 'google') and the identity token returned by the platform SDK.
  Future<void> oauthSignIn({required String provider, required String identityToken}) async {
    final data = await _api.oauthSignIn(provider: provider, identityToken: identityToken);
    await _applySession(data);
  }

  Future<void> logout() async {
    _ws.disconnect();
    try {
      await _api.logout();
    } finally {
      _email = null;
      _userId = null;
      _isVip = false;
      _isOffline = false;
      _serverSettings = null;
      _isAuthenticated = false;
      await _storage.deleteEmail();
      notifyListeners();
    }
  }

  Future<void> tryRestoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.tryRestoreSession();
      switch (result.outcome) {
        case RefreshOutcome.ok:
          // The profile rides along with the refresh — no /me round-trip.
          _applyProfile(result.profile!);
          _email ??= await _storage.getEmail();
          _isAuthenticated = true;
          _isOffline = false;
          _ws.connect();

        case RefreshOutcome.invalid:
          _isAuthenticated = false;

        case RefreshOutcome.offline:
          // A stored session exists but the network does not: keep the user
          // in, show cached data, recover on the first successful request.
          final userId = await _storage.getUserId();
          if (userId != null) {
            _userId = userId;
            _email = await _storage.getEmail();
            final prefs = await SharedPreferences.getInstance();
            _isVip = prefs.getBool(_vipKey) ?? false;
            _isAuthenticated = true;
            _isOffline = true;
          } else {
            _isAuthenticated = false;
          }
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

  Future<void> _applySession(Map<String, dynamic> data, {String? email}) async {
    _applyProfile(data);
    if (email != null) _email = email;
    if (_email != null) await _storage.setEmail(_email!);
    if (_userId != null) await _storage.setUserId(_userId!);
    _isAuthenticated = true;
    _isOffline = false;
    _ws.connect();
    notifyListeners();
  }

  void _applyProfile(Map<String, dynamic> data) {
    _userId = data['userId'] as String? ?? _userId;
    _email = data['email'] as String? ?? _email;
    _isVip = data['vip'] == true;
    _serverSettings = {
      'theme': data['theme'],
      'language': data['language'],
      'cursorId': data['cursorId'],
      'cursorEnabled': data['cursorEnabled'],
      'premium': data['premium'],
    };
    // Cached so an offline launch keeps VIP features unlocked.
    SharedPreferences.getInstance().then((p) => p.setBool(_vipKey, _isVip));
  }

  /// Every successful refresh carries the profile. Mid-session this is how an
  /// offline-started session fills in once the network is back.
  void _onTokensRefreshed(Map<String, dynamic> profile) {
    if (!_isAuthenticated) return; // the restore path handles its own refresh
    final wasOffline = _isOffline;
    _applyProfile(profile);
    _isOffline = false;
    _ws.ensureConnected();
    if (wasOffline) notifyListeners();
  }

  void _onAuthExpired() {
    _ws.disconnect();
    _userId = null;
    _isOffline = false;
    _isAuthenticated = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _api.onAuthExpired = null;
    _api.onTokensRefreshed = null;
    _ws.disconnect();
    super.dispose();
  }
}
