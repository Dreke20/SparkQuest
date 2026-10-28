import 'dart:async';
import 'package:flutter/foundation.dart';
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
    _isInitialized = true;
    notifyListeners();
  }

  /// Purchase an IAP product and sync entitlements to Supabase
  Future<bool> purchase(IAPProduct product, {Function(int embers)? onEmbersAdded}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (product.isSubscription) {
      isGoldVip = true;
      await StorageService.instance.setGoldVip(true);
      try {
        await SupabaseService.instance.updateProfileField('is_vip', true);
      } catch (_) {}
    }

    if (product.id == 'sparkquest_spotlight_boost' || product.id == 'sparkquest_embers_1500') {
      await StorageService.instance.addInventoryItem('spotlight', 1);
    }

    if (product.embersReward > 0) {
      onEmbersAdded?.call(product.embersReward);
    }

    notifyListeners();
    return true;
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(milliseconds: 500));
    isGoldVip = StorageService.instance.isGoldVip();
    notifyListeners();
    return true;
  }
}
