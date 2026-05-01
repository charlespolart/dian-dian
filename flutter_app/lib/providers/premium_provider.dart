import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/purchase_service.dart';

class PremiumProvider extends ChangeNotifier {
  static const _prefKey = 'is_premium';
  static const _cursorEnabledKey = 'cursor_enabled';
  static const _cursorIdKey = 'cursor_id';
  static const maxFreeTrackers = 3;

  bool _isPremium = false;
  bool _isVip = false;
  bool _cursorEnabled = false;
  String _cursorId = 'cat';
  final PurchaseService _purchaseService = PurchaseService();

  bool get isPremium => _isPremium || _isVip;
  int get maxTrackers => isPremium ? 999 : maxFreeTrackers;
  bool get canUseCustomThemes => isPremium;
  bool get canUseAnimatedCursor => isPremium && _cursorEnabled;
  bool get canExportImage => isPremium;
  bool get cursorEnabled => _cursorEnabled;
  String get cursorId => _cursorId;

  PurchaseService get purchaseService => _purchaseService;

  PremiumProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load cached state for instant UI on cold start.
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_prefKey) ?? false;
    _cursorEnabled = prefs.getBool(_cursorEnabledKey) ?? false;
    _cursorId = prefs.getString(_cursorIdKey) ?? 'default';
    notifyListeners();

    _purchaseService.onPremiumChanged = _onPremiumChanged;
    await _purchaseService.init();
  }

  void _onPremiumChanged(bool isPremium) {
    _setPremiumCached(isPremium);
  }

  /// Buy a specific RC package (monthly / yearly / lifetime).
  Future<bool> purchasePackage(Package package) async {
    return _purchaseService.purchasePackage(package);
  }

  /// Restore previous purchases.
  Future<bool> restorePurchases() async {
    return _purchaseService.restorePurchases();
  }

  /// Check subscription status from server (used as a backup, e.g. if RC
  /// listener missed an update). The webhook keeps the DB authoritative.
  Future<void> checkServerSubscription() async {
    try {
      final response = await ApiService().apiFetch('/api/purchase/status');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['premium'] == true && !_isPremium) {
          await _setPremiumCached(true);
        }
      }
    } catch (_) {}
  }

  /// Set VIP status (from AuthProvider).
  void setVip(bool value) {
    _isVip = value;
    notifyListeners();
  }

  /// Apply settings from server (called after login / session restore).
  void applyServerSettings({String? cursorId, bool? cursorEnabled}) {
    bool changed = false;
    if (cursorId != null && cursorId != _cursorId) {
      _cursorId = cursorId;
      changed = true;
    }
    if (cursorEnabled != null && cursorEnabled != _cursorEnabled) {
      _cursorEnabled = cursorEnabled;
      changed = true;
    }
    if (changed) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_cursorEnabledKey, _cursorEnabled);
        prefs.setString(_cursorIdKey, _cursorId);
      });
      notifyListeners();
    }
  }

  /// Toggle animated cursor on/off.
  Future<void> setCursorEnabled(bool value) async {
    _cursorEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cursorEnabledKey, value);
    notifyListeners();
    ApiService().apiFetch('/api/auth/settings', method: 'PATCH', body: {'cursorEnabled': value}).ignore();
  }

  /// Set which cursor to use (for future multiple cursors).
  Future<void> setCursorId(String id) async {
    _cursorId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cursorIdKey, id);
    notifyListeners();
    ApiService().apiFetch('/api/auth/settings', method: 'PATCH', body: {'cursorId': id}).ignore();
  }

  Future<void> _setPremiumCached(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    notifyListeners();
  }
}
