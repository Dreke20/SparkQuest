# Google Play Reviewer Account & App Access Instructions

Google Play Console requires developers to provide demo credentials if any part of the app requires login or verification (**Policy: App Access**).

Follow the steps below to copy-paste these credentials into your **Google Play Console**.

---

## 1. Where to Enter This in Google Play Console

1. Log in to [Google Play Console](https://play.google.com/console).
2. Select your app: **SparkQuest**.
3. In the left navigation menu, scroll down to **Policy and programs &rarr; App content**.
4. Find **App access** and click **Manage** (or **Start**).
5. Select: **All or some functionality is restricted**.
6. Click **+ Add new instructions** and enter the details below.

---

## 2. Reviewer Account Details to Copy-Paste

| Field | Value to Enter |
| :--- | :--- |
| **Title / Instruction Name** | `Play Store Reviewer Test Account` |
| **Username / Email** | `reviewer@sparkquest.app` |
| **Password** | `PlayReviewer2026!` |
| **Phone Number (Alternative)** | `+1 (555) 019-2026` |
| **Static OTP Code** | `123456` |

---

## 3. Explanation / Instructions for Google Reviewers

Copy and paste this exact text into the **"Explanation for Google"** / **"Any other instructions"** box:

```text
To review SparkQuest with full access to all features:

1. Launch SparkQuest on the device.
2. Navigate to the Profile tab and tap "Auth / SMS" (or tap the Auth icon in the header).
3. Switch to the "🛡️ Reviewer" tab on the sign-in modal.
4. Tap the "Enter as Play Reviewer 🚀" button (or log in with reviewer@sparkquest.app / PlayReviewer2026!).
5. This reviewer account immediately unlocks:
   - 500 Embers starter currency to test discovery, rewinds, and cosmetics.
   - SparkQuest Gold VIP active status to test subscription benefits.
   - Pre-loaded mutual matches (Maya, Sophia, Alex) to test chat, voice/video calls, and date safe guard.
   - Drop-In Voice Lounges and BLE Proximity Discovery Radar without requiring physical travel or real carrier SMS OTP.
   - Google Play Billing sandbox products.
```

---

## 4. In-App Implementation

* **Reviewer Tab**: Located inside `AuthDialog` (`sparkquest_flutter/lib/widgets/auth_dialog.dart`) under the `🛡️ Reviewer` tab.
* **Reviewer Service**: Powered by `SupabaseService.instance.signInAsReviewer()` (`sparkquest_flutter/lib/services/supabase_service.dart`).
* **Bypasses SMS Carrier Delivery**: Completely eliminates SMS gateway failure risks during Google's automated or Dublin/Mountain View manual reviews.

