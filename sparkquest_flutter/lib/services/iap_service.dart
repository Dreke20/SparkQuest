import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class IAPProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String icon;
  final bool isSubscription;
  final int embersReward;

  const IAPProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.icon,
    this.isSubscription = false,
    this.embersReward = 0,
  });
}

/// Official Google Play Billing Service for SparkQuest
class IAPService extends ChangeNotifier {
  static final IAPService instance = IAPService._internal();
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isInitialized = false;
  bool isGoldVip = false;
  bool isBillingAvailable = false;
  final Map<String, ProductDetails> serverProducts = {};

  final List<IAPProduct> products = const [
    IAPProduct(
      id: 'sparkquest_gold_monthly',
      title: 'SparkQuest Gold VIP',
      description: 'Unlimited Rewinds, Free Admirer Unblur, 2x Embers & VIP Frames',
      price: '\$14.99/mo',
      rawPrice: 14.99,
      icon: '👑',
      isSubscription: true,
    ),
    IAPProduct(
      id: 'sparkquest_embers_100',
      title: 'Starter Pouch (150 Embers)',
      description: 'Send 6 Super-Sparks or 3 Standout Roses',
      price: '\$1.99',
      rawPrice: 1.99,
      icon: '✦',
      embersReward: 150,
    ),
    IAPProduct(
      id: 'sparkquest_embers_500',
      title: 'Adventurer Chest (600 Embers)',
      description: 'Best Value! Includes +20% Bonus Embers',
      price: '\$5.99',
      rawPrice: 5.99,
      icon: '🔥',
      embersReward: 600,
    ),
    IAPProduct(
      id: 'sparkquest_embers_1500',
      title: 'Sovereign Vault (1,500 Embers)',
      description: 'Whale Pack • Includes +50% Bonus Embers & 1 Free Boost',
      price: '\$12.99',
      rawPrice: 12.99,
      icon: '👑',
      embersReward: 1500,
    ),
    IAPProduct(
      id: 'sparkquest_spotlight_boost',
      title: '30-Minute Spotlight Boost',
      description: 'Boost your profile to the front of local exploration decks',
      price: '\$2.99',
      rawPrice: 2.99,
      icon: '⚡',
    ),
  ];

  Future<void> initialize() async {
    isGoldVip = StorageService.instance.isGoldVip();
    if (_isInitialized) return;

    try {
      isBillingAvailable = await _iap.isAvailable();
      if (isBillingAvailable) {
        final productIds = products.map((p) => p.id).toSet();
        final response = await _iap.queryProductDetails(productIds);
        for (final detail in response.productDetails) {
          serverProducts[detail.id] = detail;
        }

        _subscription = _iap.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (e) => debugPrint('IAP purchase stream error: $e'),
        );
      }
    } catch (e) {
      debugPrint('Google Play Billing init notice: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Pending confirmation
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _deliverProduct(purchaseDetails.productID);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
    notifyListeners();
  }

  Future<void> _deliverProduct(String productId) async {
    if (productId == 'sparkquest_gold_monthly') {
      isGoldVip = true;
      await StorageService.instance.setGoldVip(true);
      try {
        await SupabaseService.instance.updateProfileField('is_vip', true);
      } catch (_) {}
    } else if (productId == 'sparkquest_spotlight_boost') {
      await StorageService.instance.addInventoryItem('spotlight', 1);
    } else if (productId == 'sparkquest_embers_100') {
      await StorageService.instance.addEmbers(150);
    } else if (productId == 'sparkquest_embers_500') {
      await StorageService.instance.addEmbers(600);
    } else if (productId == 'sparkquest_embers_1500') {
      await StorageService.instance.addEmbers(1500);
      await StorageService.instance.addInventoryItem('spotlight', 1);
    }
  }

  /// Purchase an IAP product via Google Play Billing
  Future<bool> purchase(
    IAPProduct product, {
    Function(int embers)? onEmbersAdded,
  }) async {
    if (isBillingAvailable && serverProducts.containsKey(product.id)) {
      final productDetails = serverProducts[product.id]!;
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      if (product.isSubscription) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    }

    // Sandbox / Closed Beta mode fallback when products are not yet active on Play Console:
    await Future.delayed(const Duration(milliseconds: 600));
    await _deliverProduct(product.id);
    if (product.embersReward > 0) {
      onEmbersAdded?.call(product.embersReward);
    }
    notifyListeners();
    return true;
  }

  /// Restore Google Play purchases
  Future<bool> restorePurchases() async {
    if (isBillingAvailable) {
      try {
        await _iap.restorePurchases();
        return true;
      } catch (e) {
        debugPrint('Restore purchases error: $e');
      }
    }
    isGoldVip = StorageService.instance.isGoldVip();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
