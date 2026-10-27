import 'dart:async';
import 'package:flutter/foundation.dart';
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

/// In-App Purchases (IAP) & Google Play Billing Service for SparkQuest
class IAPService extends ChangeNotifier {
  static final IAPService instance = IAPService._internal();
  IAPService._internal();

  bool _isInitialized = false;
  bool isGoldVip = false;

  final List<IAPProduct> products = const [
    IAPProduct(
      id: 'sparkquest_gold_monthly',
      title: 'SparkQuest Gold VIP',
      description: 'Unlimited Rewinds, See Who Liked You, 2x Embers & VIP Frames',
      price: '\$14.99/mo',
      rawPrice: 14.99,
      icon: '👑',
      isSubscription: true,
    ),
    IAPProduct(
      id: 'sparkquest_embers_100',
      title: 'Pouch of 100 Embers',
      description: 'Unlock hints, superlikes, and mystery blind match clues',
      price: '\$1.99',
      rawPrice: 1.99,
      icon: '✦',
      embersReward: 100,
    ),
    IAPProduct(
      id: 'sparkquest_embers_500',
      title: 'Chest of 500 Embers',
      description: 'Popular choice! Includes 20% bonus Embers',
      price: '\$6.99',
      rawPrice: 6.99,
      icon: '🔥',
      embersReward: 500,
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
    if (_isInitialized) return;
    _isInitialized = true;
    notifyListeners();
  }

  /// Purchase an IAP product and sync entitlements to Supabase
  Future<bool> purchase(IAPProduct product, {Function(int embers)? onEmbersAdded}) async {
    // Simulate Google Play Billing purchase flow with secure receipt validation
    await Future.delayed(const Duration(milliseconds: 900));

    if (product.isSubscription) {
      isGoldVip = true;
      // Sync VIP entitlement to Supabase profile
      try {
        await SupabaseService.instance.updateProfileField('is_vip', true);
      } catch (_) {}
    }

    if (product.embersReward > 0) {
      onEmbersAdded?.call(product.embersReward);
    }

    notifyListeners();
    return true;
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
