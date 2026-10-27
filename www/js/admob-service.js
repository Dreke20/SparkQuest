import { AdMob, RewardAdPluginEvents } from '@capacitor-community/admob';
import { Capacitor } from '@capacitor/core';

export const AdMobService = {
  isInitialized: false,
  rewardListener: null,

  async initialize() {
    if (this.isInitialized) return;
    try {
      if (Capacitor.isNativePlatform()) {
        await AdMob.initialize({
          requestTrackingAuthorization: true,
          testingDevices: [],
          initializeForTesting: true,
        });
        this.isInitialized = true;
        console.log('[AdMobService] Initialized natively');
      } else {
        this.isInitialized = true;
        console.log('[AdMobService] Running on web, AdMob is in web emulation mode.');
      }
    } catch (e) {
      console.error('[AdMobService] Initialization failed:', e);
    }
  },

  async showRewardedAd(onRewardCallback) {
    if (Capacitor.isNativePlatform()) {
      try {
        const adId = Capacitor.getPlatform() === 'ios'
          ? (window.SPARK_CONFIG?.ADMOB_IOS_REWARD_ID || 'ca-app-pub-3940256099942544/1712485313')
          : (window.SPARK_CONFIG?.ADMOB_ANDROID_REWARD_ID || 'ca-app-pub-3940256099942544/5224354917');

        // Remove previous listener if exists to prevent duplicates
        if (this.rewardListener) {
          await this.rewardListener.remove();
        }

        this.rewardListener = await AdMob.addListener(RewardAdPluginEvents.Rewarded, (rewardItem) => {
          console.log('[AdMobService] User earned reward:', rewardItem);
          if (onRewardCallback) onRewardCallback(rewardItem.amount || 25);
        });

        await AdMob.prepareRewardVideoAd({ adId });
        await AdMob.showRewardVideoAd();
      } catch (e) {
        console.error('[AdMobService] Failed to show rewarded ad:', e);
        if (typeof window.showToast === 'function') {
          window.showToast('Ad unavailable right now. Try again soon.', 'info');
        }
      }
    } else {
      // Clean web preview simulation without blocking browser alert
      if (typeof window.showToast === 'function') {
        window.showToast('Playing sponsored video...', 'info');
      }
      setTimeout(() => {
        if (typeof window.showToast === 'function') {
          window.showToast('Reward claimed! +25 Embers 🔥', 'earn', '+25');
        }
        if (onRewardCallback) onRewardCallback(25);
      }, 1200);
    }
  }
};

window.AdMobService = AdMobService;
