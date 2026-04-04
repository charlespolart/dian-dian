import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Reusable in-app purchase service.
/// Wraps `in_app_purchase` package with a clean API.
///
/// Usage:
///   final service = PurchaseService();
///   await service.init();
///   service.onPurchaseUpdated = (isPremium) { ... };
///   await service.buyPremium();
///   await service.restorePurchases();
///   service.dispose();
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Product IDs — configure these in App Store Connect / Google Play Console
  String _premiumMonthlyId = '';
  String _premiumYearlyId = '';
  Set<String> _productIds = {};

  /// Configure product IDs before calling init().
  void configure({required String monthlyId, required String yearlyId}) {
    _premiumMonthlyId = monthlyId;
    _premiumYearlyId = yearlyId;
    _productIds = {monthlyId, yearlyId};
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _available = false;

  /// Called when purchase status changes. true = premium active.
  void Function(bool isPremium)? onPurchaseUpdated;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _available;

  /// Initialize the purchase service. Call once at app start.
  Future<void> init() async {
    if (kIsWeb) return; // Not available on web

    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('PurchaseService: Store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('PurchaseService: Stream error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('PurchaseService: Error loading products: ${response.error}');
      return;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('PurchaseService: Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    debugPrint('PurchaseService: Loaded ${_products.length} products');
  }

  /// Buy the premium subscription (monthly by default, or specify productId).
  Future<bool> buyPremium({String? productId}) async {
    if (!_available || _products.isEmpty) {
      debugPrint('PurchaseService: Not available or no products');
      return false;
    }

    final id = productId ?? _premiumMonthlyId;
    final product = _products.cast<ProductDetails?>().firstWhere(
      (p) => p!.id == id,
      orElse: () => _products.isNotEmpty ? _products.first : null,
    );

    if (product == null) {
      debugPrint('PurchaseService: Product $id not found');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Use buyNonConsumable for subscriptions
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('PurchaseService: Buy failed: $e');
      return false;
    }
  }

  /// Restore previous purchases (required by Apple).
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Verify the purchase
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          onPurchaseUpdated?.call(true);
        }
        break;

      case PurchaseStatus.error:
        debugPrint('PurchaseService: Purchase error: ${purchase.error}');
        onPurchaseUpdated?.call(false);
        break;

      case PurchaseStatus.canceled:
        debugPrint('PurchaseService: Purchase canceled');
        break;

      case PurchaseStatus.pending:
        debugPrint('PurchaseService: Purchase pending');
        break;
    }

    // Complete the purchase (required by both stores)
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Verify purchase receipt.
  /// For production: send receipt to your backend for server-side verification.
  /// For now: trust the local purchase status.
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implement server-side receipt verification
    // Send purchase.verificationData to your backend
    // Backend verifies with Apple/Google servers
    // Return true if valid

    // For now, trust the purchase
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  /// Check if there's an active subscription.
  /// Called at app start to restore premium status.
  Future<bool> checkActiveSubscription() async {
    if (kIsWeb || !_available) return false;

    // On iOS, restorePurchases will trigger the purchase stream
    // which will call onPurchaseUpdated
    await restorePurchases();

    // Give the stream a moment to process
    await Future.delayed(const Duration(seconds: 2));

    return false; // The actual result comes via onPurchaseUpdated callback
  }

  void dispose() {
    _subscription?.cancel();
  }
}
