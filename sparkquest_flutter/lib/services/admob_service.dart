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

  // --- Google AdMob Ad Unit IDs ---
  // In debug mode, official Google test ad unit IDs are used to protect your account from invalid traffic penalties.
  // In release builds, your live production ad units are loaded automatically.
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return 'ca-app-pub-3920607003046699/7588463864';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return 'ca-app-pub-3920607003046699/1094548563';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return 'ca-app-pub-3920607003046699/1262728662';
  }

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Builds an AdRequest respecting user consent (GDPR / ePrivacy)
  AdRequest buildAdRequest() {
    final personalized = StorageService.instance.isPersonalizedAdsEnabled();
    return AdRequest(nonPersonalizedAds: !personalized);
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
    if (!isSupportedPlatform ||
        _isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: buildAdRequest(),
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
      request: buildAdRequest(),
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
      final isGoldVip = StorageService.instance.isGoldVip();
      const base = 5; // 5 from AdMob
      final amount = isGoldVip ? base * 2 : base; // VIP gets 10
      onRewarded(amount);
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
          final isGoldVip = StorageService.instance.isGoldVip();
          final base = reward.amount.toInt() > 0
              ? reward.amount.toInt()
              : 5; // 5 from AdMob
          final amount = isGoldVip ? base * 2 : base; // VIP gets 10
          onRewarded(amount);
        },
      );
    } else {
      // Load on-demand and show immediately
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: buildAdRequest(),
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
                final isGoldVip = StorageService.instance.isGoldVip();
                final base = reward.amount.toInt() > 0
                    ? reward.amount.toInt()
                    : 5; // 5 from AdMob
                final amount = isGoldVip ? base * 2 : base; // VIP gets 10
                onRewarded(amount);
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('RewardedAd on-demand load failed: $error');
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⚠️ Video ad could not be loaded. Please try again later.',
                  ),
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

  // --- EU/UK GDPR & ePrivacy Consent Choices ---

  void showPrivacyChoicesDialog(BuildContext context) {
    // 1. Attempt official Google UMP consent form
    if (isSupportedPlatform) {
      try {
        ConsentForm.showPrivacyOptionsForm((
          FormError? formError,
        ) {
          if (formError != null) {
            debugPrint('Google UMP privacy form notice: ${formError.message}');
          }
        });
      } catch (e) {
        debugPrint(
          'UMP showPrivacyOptionsForm not supported in test environment: $e',
        );
      }
    }

    // 2. Open interactive Privacy Choices modal
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool personalized = StorageService.instance
              .isPersonalizedAdsEnabled();
          bool locationMeasurement = StorageService.instance
              .isAdLocationMeasurementEnabled();

          return AlertDialog(
            backgroundColor: const Color(0xFF131D33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFF06B6D4), width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF06B6D4), size: 22),
                SizedBox(width: 8),
                Text(
                  'Privacy choices',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SparkQuest shows ads through Google AdMob, which may use your device\'s advertising ID and approximate location to show and measure ads.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'EU/UK and global users can change or withdraw their choices anytime.',
                    style: TextStyle(
                      color: Color(0xFF06B6D4),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Personalized Advertising',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Allow Google AdMob to use your advertising ID for ads tailored to your interests.',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                          activeThumbColor: const Color(0xFF06B6D4),
                          value: personalized,
                          onChanged: (val) async {
                            await StorageService.instance
                                .setPersonalizedAdsEnabled(val);
                            setDialogState(() {
                              personalized = val;
                            });
                          },
                        ),
                        const Divider(color: Colors.white12, height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Approximate Location Measurement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Allow AdMob to measure ad delivery using approximate city/region coordinates.',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                          activeThumbColor: const Color(0xFF06B6D4),
                          value: locationMeasurement,
                          onChanged: (val) async {
                            await StorageService.instance
                                .setAdLocationMeasurementEnabled(val);
                            setDialogState(() {
                              locationMeasurement = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      minimumSize: const Size.fromHeight(38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (isSupportedPlatform) {
                        try {
                          ConsentForm.loadAndShowConsentFormIfRequired((
                            FormError? formError,
                          ) {
                            if (formError != null) {
                              debugPrint(
                                'Consent form error: ${formError.message}',
                              );
                            }
                          });
                        } catch (e) {
                          debugPrint('ConsentForm not available in test: $e');
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🇪🇺 Reloading Google CMP Consent Form...',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      'Re-open Google Consent Form',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '🛡️ Privacy choices saved. Ad preferences updated.',
                      ),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                child: const Text(
                  'Save Choices',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
