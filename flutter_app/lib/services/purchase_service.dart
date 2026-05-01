import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenue_cat_config.dart';

/// Wraps the RevenueCat SDK with a small, app-friendly API.
///
/// Lifecycle:
///   - [init] once at app start (configures the SDK)
///   - [logIn] when the user signs in (associates purchases with the backend user)
///   - [logOut] when the user signs out
///   - [onPremiumChanged] fires whenever the `premium` entitlement flips
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  bool _initialized = false;
  bool _premiumActive = false;
  Offerings? _offerings;

  /// Called whenever the `premium` entitlement state changes.
  void Function(bool isPremium)? onPremiumChanged;

  bool get isPremiumActive => _premiumActive;
  bool get isInitialized => _initialized;
  Offerings? get offerings => _offerings;
  Offering? get currentOffering => _offerings?.current;

  /// Configure the SDK. Safe to call multiple times — only runs once.
  Future<void> init() async {
    if (_initialized) return;
    final apiKey = RevenueCatConfig.apiKeyForPlatform();
    if (apiKey == null) return; // unsupported platform (web, etc.)

    try {
      await Purchases.setLogLevel(kReleaseMode ? LogLevel.warn : LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _initialized = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      // Prime state from current customer + offerings.
      await _refreshOfferings();
      final info = await Purchases.getCustomerInfo();
      _onCustomerInfoUpdate(info);
    } catch (e) {
      debugPrint('PurchaseService.init failed: $e');
    }
  }

  /// Associate the SDK with a backend user id. Call after login.
  /// RevenueCat merges anonymous purchases into the identified user.
  Future<void> logIn(String userId) async {
    if (!_initialized) return;
    try {
      final result = await Purchases.logIn(userId);
      _onCustomerInfoUpdate(result.customerInfo);
      await _refreshOfferings();
    } catch (e) {
      debugPrint('PurchaseService.logIn failed: $e');
    }
  }

  /// Reset to anonymous user. Call on logout.
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      final info = await Purchases.logOut();
      _onCustomerInfoUpdate(info);
    } catch (e) {
      debugPrint('PurchaseService.logOut failed: $e');
    }
  }

  /// Purchase a specific package. Returns true if the user is now premium.
  Future<bool> purchasePackage(Package package) async {
    if (!_initialized) return false;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _onCustomerInfoUpdate(result.customerInfo);
      return _premiumActive;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return false; // user cancelled, not an error
      }
      debugPrint('PurchaseService.purchasePackage error: ${e.message}');
      return false;
    }
  }

  /// Restore purchases (Apple requirement). Returns true if a premium
  /// entitlement was found.
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfoUpdate(info);
      return _premiumActive;
    } catch (e) {
      debugPrint('PurchaseService.restorePurchases failed: $e');
      return false;
    }
  }

  Future<void> _refreshOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      debugPrint('PurchaseService._refreshOfferings failed: $e');
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    final isPremium = info.entitlements.active
        .containsKey(RevenueCatConfig.premiumEntitlement);
    if (isPremium != _premiumActive) {
      _premiumActive = isPremium;
      onPremiumChanged?.call(isPremium);
    }
  }
}
