// Payment & Billing Service - Google Play Billing & Web Sandbox Architecture
import { Capacitor } from '@capacitor/core';
import DB_Service from './db-service.js';

const PaymentService = {
    // Google Play Store & App Store Product SKUs
    products: {
        'embers100': {
            id: 'embers100',
            sku: 'com.sparkquest.app.embers100',
            name: '100 Embers',
            priceStr: '$0.99',
            price: 0.99,
            amount: 100,
            type: 'inapp',
            category: 'embers'
        },
        'embers500': {
            id: 'embers500',
            sku: 'com.sparkquest.app.embers500',
            name: '500 Embers',
            priceStr: '$4.99',
            price: 4.99,
            amount: 500,
            type: 'inapp',
            category: 'embers'
        },
        'embers1200': {
            id: 'embers1200',
            sku: 'com.sparkquest.app.embers1200',
            name: '1,200 Embers',
            priceStr: '$9.99',
            price: 9.99,
            amount: 1200,
            type: 'inapp',
            category: 'embers'
        },
        'boost': {
            id: 'boost',
            sku: 'com.sparkquest.app.boost5',
            name: '5x Profile Boost',
            priceStr: '$7.99',
            price: 7.99,
            amount: 5,
            type: 'inapp',
            category: 'boost'
        },
        'superlike': {
            id: 'superlike',
            sku: 'com.sparkquest.app.superlike10',
            name: '10x Super-Likes',
            priceStr: '$9.99',
            price: 9.99,
            amount: 10,
            type: 'inapp',
            category: 'superlike'
        },
        'sub_silver': {
            id: 'sub_silver',
            sku: 'com.sparkquest.app.sub_silver_monthly',
            name: 'Spark Silver (Monthly)',
            priceStr: '$14.99/mo',
            price: 14.99,
            type: 'subs',
            category: 'subscription',
            tier: 'silver'
        },
        'sub_gold': {
            id: 'sub_gold',
            sku: 'com.sparkquest.app.sub_gold_monthly',
            name: 'Spark Gold (Monthly)',
            priceStr: '$29.99/mo',
            price: 29.99,
            type: 'subs',
            category: 'subscription',
            tier: 'gold'
        },
        'sub_platinum': {
            id: 'sub_platinum',
            sku: 'com.sparkquest.app.sub_platinum_monthly',
            name: 'Spark Platinum (Monthly)',
            priceStr: '$49.99/mo',
            price: 49.99,
            type: 'subs',
            category: 'subscription',
            tier: 'platinum'
        }
    },

    // Initialize native store connection if on Android/iOS
    async init() {
        console.log('[PaymentService] Initializing Billing Service...');
        if (Capacitor.isNativePlatform()) {
            console.log('[PaymentService] Running on native platform. Ready for Google Play Billing.');
        } else {
            console.log('[PaymentService] Running in Web Sandbox mode.');
        }
    },

    // Main checkout method
    async checkout(productId) {
        const product = this.products[productId];
        if (!product) {
            console.error('[PaymentService] Invalid product ID:', productId);
            if (typeof window.showToast === 'function') {
                window.showToast('Invalid item selected', 'spend');
            }
            return { error: 'Invalid product' };
        }

        console.log(`[PaymentService] Initiating purchase for: ${product.name} (${product.sku})`);

        if (Capacitor.isNativePlatform()) {
            try {
                if (!window.Capacitor?.Plugins?.InAppPurchases) {
                    if (typeof window.showToast === 'function') {
                        window.showToast('Google Play Billing unavailable in this build. Use the Flutter Android release.', 'spend');
                    }
                    return { error: 'In-app billing plugin unavailable' };
                }

                const result = await window.Capacitor.Plugins.InAppPurchases.purchase({
                    productId: product.sku
                });
                const purchaseToken = result?.purchaseToken || result?.receipt;
                if (!purchaseToken) {
                    return { error: 'Missing purchase receipt token' };
                }

                const verified = await this.verifyServerPurchase(product.sku, purchaseToken);
                if (!verified?.verified) {
                    if (typeof window.showToast === 'function') {
                        window.showToast('Purchase verification failed. No charge applied.', 'spend');
                    }
                    return { error: verified?.error || 'Receipt verification failed' };
                }

                await this.syncVerifiedEntitlements(verified, product);
                return { status: 'success', receipt: purchaseToken, verified: true };
            } catch (err) {
                console.error('[PaymentService] Native purchase failed:', err);
                if (typeof window.showToast === 'function') {
                    window.showToast('Purchase canceled or unavailable.', 'info');
                }
                return { error: err.message };
            }
        } else {
            if (typeof window.showToast === 'function') {
                window.showToast('In-app purchases require Google Play Billing on Android.', 'info');
            }
            return { error: 'Store billing unavailable on web preview' };
        }
    },

    async verifyServerPurchase(productId, purchaseToken) {
        try {
            const client = window.supabaseClient || window.DB_Service?.getClient?.();
            if (!client) return { verified: false, error: 'Authentication required' };
            const { data: { session } } = await client.auth.getSession();
            if (!session?.access_token) return { verified: false, error: 'Sign-in required' };

            const { data, error } = await client.functions.invoke('verify-purchase', {
                body: {
                    product_id: productId,
                    purchase_token: purchaseToken,
                    platform: 'android'
                }
            });
            if (error) return { verified: false, error: error.message };
            return data || { verified: false };
        } catch (err) {
            return { verified: false, error: err?.message || 'Verification failed' };
        }
    },

    async syncVerifiedEntitlements(verifiedData, product) {
        if (typeof verifiedData?.embers === 'number') {
            window.embers = verifiedData.embers;
            if (typeof window.updateEmberDisplay === 'function') window.updateEmberDisplay();
        }
        if (verifiedData?.is_vip) {
            window.isPremium = true;
        }
        if (typeof window.showToast === 'function' && product) {
            window.showToast(`Verified & unlocked ${product.name}!`, 'earn');
        }
        if (typeof window.SoundService?.playReward === 'function') {
            window.SoundService.playReward();
        }
    },

    // Mandatory Store Requirement: Restore Purchases
    async restorePurchases() {
        console.log('[PaymentService] Restoring previous purchases...');
        if (typeof window.showToast === 'function') {
            window.showToast('Checking active subscriptions...', 'info');
        }

        if (window.currentUserUid && window.DB_Service) {
            const data = await window.DB_Service.getUserData(window.currentUserUid);
            if (data?.isPremium) {
                window.isPremium = true;
                if (typeof window.showToast === 'function') {
                    window.showToast('Subscription active: Spark Premium 👑', 'info');
                }
                return true;
            }
        }

        setTimeout(() => {
            if (typeof window.showToast === 'function') {
                window.showToast('No active subscriptions found to restore.', 'info');
            }
        }, 1200);
        return false;
    }
};

export default PaymentService;
window.PaymentService = PaymentService;
