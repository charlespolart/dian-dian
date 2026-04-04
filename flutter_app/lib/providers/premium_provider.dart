import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/purchase_service.dart';

class PremiumProvider extends ChangeNotifier {
  static const _prefKey = 'is_premium';
  static const _cursorEnabledKey = 'cursor_enabled';
  static const _cursorIdKey = 'cursor_id';
  static const maxFreeTrackers = 3;

  bool _isPremium = false;
  bool _cursorEnabled = false;
  String _cursorId = 'cat';
  final PurchaseService _purchaseService = PurchaseService();

  bool get isPremium => _isPremium;
  int get maxTrackers => _isPremium ? 999 : maxFreeTrackers;
  bool get canUseCustomThemes => _isPremium;
  bool get canUseAnimatedCursor => _isPremium && _cursorEnabled;
  bool get canExportImage => _isPremium;
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

  /// Toggle animated cursor on/off.
  Future<void> setCursorEnabled(bool value) async {
    _cursorEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cursorEnabledKey, value);
    notifyListeners();
  }

  /// Set which cursor to use (for future multiple cursors).
  Future<void> setCursorId(String id) async {
    _cursorId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cursorIdKey, id);
    notifyListeners();
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
