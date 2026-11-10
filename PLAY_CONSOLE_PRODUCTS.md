# Google Play Console In-App Products & Subscriptions Setup Guide

This guide details the exact Product IDs, types, pricing, and configurations required in the Google Play Console for SparkQuest (`com.sparkquest.sparkquest`).

---

## 📋 Product Catalog Summary

| Product ID | Type | Price (USD) | Title | In-App Reward |
| :--- | :--- | :--- | :--- | :--- |
| `sparkquest_gold_monthly` | **Subscription** | \$14.99 / mo | SparkQuest Gold VIP | Unlimited Rewinds, Admirer Unblur, 2x Embers & VIP Frames |
| `sparkquest_embers_100` | **In-App Product** (Consumable) | \$1.99 | Starter Pouch (150 Embers) | +150 Spark Embers 🔥 |
| `sparkquest_embers_500` | **In-App Product** (Consumable) | \$5.99 | Adventurer Chest (600 Embers) | +600 Spark Embers 🔥 (+20% Bonus) |
| `sparkquest_embers_1500` | **In-App Product** (Consumable) | \$12.99 | Sovereign Vault (1,500 Embers) | +1,500 Spark Embers 🔥 & +1 Spotlight Boost |
| `sparkquest_spotlight_boost` | **In-App Product** (Consumable) | \$2.99 | 30-Minute Spotlight Boost | +1 Spotlight Boost (5x local deck priority) |

---

## 🛠️ Step-by-Step Creation Instructions

### 1. Prerequisite: Upload Signed AAB
Google Play Console requires at least one App Bundle with `com.android.vending.BILLING` to be uploaded to an active track (Closed Testing) before In-app products and Subscriptions can be activated.
- Upload `sparkquest_flutter/build/app/outputs/bundle/release/app-release.aab` to your **Closed testing** track.

---

### 2. Configure In-App Products (Embers & Boosts)
Navigate to: **Google Play Console** &rarr; Select **SparkQuest** &rarr; **Monetize** &rarr; **Products** &rarr; **In-app products** &rarr; Click **Create product**.

#### Product 1: Starter Pouch
- **Product ID**: `sparkquest_embers_100`
- **Name**: `Starter Pouch (150 Embers)`
- **Description**: `Send 6 Super-Sparks or 3 Standout Roses`
- **Default price**: `$1.99`
- Click **Save** &rarr; Click **Activate**.

#### Product 2: Adventurer Chest
- **Product ID**: `sparkquest_embers_500`
- **Name**: `Adventurer Chest (600 Embers)`
- **Description**: `Best Value! Includes +20% Bonus Embers`
- **Default price**: `$5.99`
- Click **Save** &rarr; Click **Activate**.

#### Product 3: Sovereign Vault
- **Product ID**: `sparkquest_embers_1500`
- **Name**: `Sovereign Vault (1,500 Embers)`
- **Description**: `Whale Pack • Includes +50% Bonus Embers & 1 Free Boost`
- **Default price**: `$12.99`
- Click **Save** &rarr; Click **Activate**.

#### Product 4: Spotlight Boost
- **Product ID**: `sparkquest_spotlight_boost`
- **Name**: `30-Minute Spotlight Boost`
- **Description**: `Boost your profile to the front of local exploration decks`
- **Default price**: `$2.99`
- Click **Save** &rarr; Click **Activate**.

---

### 3. Configure Subscription (SparkQuest Gold VIP)
Navigate to: **Monetize** &rarr; **Products** &rarr; **Subscriptions** &rarr; Click **Create subscription**.

- **Subscription ID**: `sparkquest_gold_monthly`
- **Name**: `SparkQuest Gold VIP`
- **Description**: `Unlimited Rewinds, Free Admirer Unblur, 2x Embers & VIP Frames`
- Click **Save**.

#### Add Base Plan:
- Under **Base plans**, click **Add base plan**.
- **Base plan ID**: `gold-monthly`
- **Type**: `Auto-renewing`
- **Billing period**: `1 month`
- **Grace period**: `16 days` (or 7 days)
- Under **Price and availability**:
  - Click **Set prices** &rarr; Select countries &rarr; Set default to `$14.99` USD.
- Click **Save** &rarr; Click **Activate** on both the base plan and subscription.

---

### 4. Enable Zero-Cost License Testing (For Closed Testers)
To ensure the 12 testers are **never charged real money** when testing the IAP store:
1. In Google Play Console root navigation (left sidebar), scroll down to **Setup** &rarr; **License testing**.
2. Under **License testers**, add the Gmail accounts of your 12 testers (comma-separated).
3. Under **License response**, ensure `RESPOND_NORMALLY` is selected.
4. Click **Save changes**.
5. When testers tap to purchase in the app, Google Play displays a green badge:
   `"Test card, always approves"` with zero real credit card charge.

