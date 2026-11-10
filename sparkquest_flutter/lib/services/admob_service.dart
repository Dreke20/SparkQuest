import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

class AdMobService {
  static final AdMobService instance = AdMobService._internal();
  AdMobService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;

  int _swipeCounter = 0;
  static const int _interstitialSwipeThreshold = 15;

  // --- Official Google Test Ad Unit IDs ---
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      preloadInterstitial();
      preloadRewarded();
    } catch (e) {
      debugPrint('AdMobService initialization error: $e');
    }
  }

  // --- Interstitial Ads (Card Deck Swipes) ---

  void preloadInterstitial() {
    if (!isSupportedPlatform || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void recordSwipeAndMaybeShowInterstitial() {
    // Gold VIP users receive a 100% ad-free experience
    if (StorageService.instance.isGoldVip()) return;
    if (!isSupportedPlatform) return;

    _swipeCounter++;
    if (_swipeCounter >= _interstitialSwipeThreshold) {
      _swipeCounter = 0;
      showInterstitialAd();
    }
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (StorageService.instance.isGoldVip()) {
      onAdClosed?.call();
      return;
    }
    if (_interstitialAd == null) {
      preloadInterstitial();
      onAdClosed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
        onAdClosed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // --- Rewarded Ads (Embers Store & Fortune Wheel) ---

  void preloadRewarded() {
    if (!isSupportedPlatform || _isRewardedLoading || _rewardedAd != null) {
      return;
    }
    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(int amount) onRewarded,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
    BuildContext? context,
  }) {
    if (!isSupportedPlatform) {
      // Mock reward for simulator/test environments without Google Play services
      onRewarded(25);
      onAdClosed?.call();
      return;
    }

    if (_rewardedAd != null) {
      final adToShow = _rewardedAd!;
      _rewardedAd = null;

      adToShow.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preloadRewarded();
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('RewardedAd failed to show: $error');
          ad.dispose();
          preloadRewarded();
          onAdFailed?.call();
        },
      );

      adToShow.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded(reward.amount.toInt());
        },
      );
    } else {
      // Load on-demand and show immediately
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                preloadRewarded();
                onAdClosed?.call();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('RewardedAd failed to show on-demand: $error');
                ad.dispose();
                preloadRewarded();
                onAdFailed?.call();
              },
            );

            ad.show(
              onUserEarnedReward: (ad, reward) {
                onRewarded(reward.amount.toInt());
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('RewardedAd on-demand load failed: $error');
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Video ad could not be loaded. Please try again later.'),
                ),
              );
            }
            onAdFailed?.call();
            preloadRewarded();
          },
        ),
      );
    }
  }
}

