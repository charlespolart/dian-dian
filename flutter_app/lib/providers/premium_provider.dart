import 'package:flutter/foundation.dart';
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
    // Load cached state
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_prefKey) ?? false;
    _cursorEnabled = prefs.getBool(_cursorEnabledKey) ?? false;
    _cursorId = prefs.getString(_cursorIdKey) ?? 'default';
    notifyListeners();

    // Initialize purchase service
    _purchaseService.configure(
      monthlyId: 'dian_dian_premium_monthly',
      yearlyId: 'dian_dian_premium_yearly',
      lifetimeId: 'dian_dian_premium_lifetime',
    );
    _purchaseService.onPurchaseUpdated = _onPurchaseUpdated;
    await _purchaseService.init();

    // Check for active subscription (restores purchases)
    if (!_isPremium) {
      await _purchaseService.checkActiveSubscription();
    }
  }

  void _onPurchaseUpdated(bool isPremium) {
    setPremium(isPremium);
  }

  /// Buy premium subscription.
  Future<bool> buyPremium({String? productId}) async {
    return _purchaseService.buyPremium(productId: productId);
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    await _purchaseService.restorePurchases();
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
    // Sync to server (fire-and-forget)
    ApiService().apiFetch('/api/auth/settings', method: 'PATCH', body: {'cursorEnabled': value}).ignore();
  }

  /// Set which cursor to use (for future multiple cursors).
  Future<void> setCursorId(String id) async {
    _cursorId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cursorIdKey, id);
    notifyListeners();
    // Sync to server (fire-and-forget)
    ApiService().apiFetch('/api/auth/settings', method: 'PATCH', body: {'cursorId': id}).ignore();
  }

  /// Set premium status (also used for testing).
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
