# Google Play Reviewer Account & App Access Instructions

Google Play Console requires developers to provide demo credentials if any part of the app requires login or verification (**Policy: App Access**).

Follow the steps below to configure your reviewer credentials in **Supabase** and copy-paste them into your **Google Play Console**.

---

## 1. Set Your Reviewer Password in Supabase

1. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/kqvjntbiagzywstijtsz).
2. Go to **Authentication** &rarr; **Users**.
3. Locate or create the account with email: `reviewer@sparkquest.app`.
4. Click the three dots (`...`) next to the user &rarr; select **Reset Password** (or **Send password reset** / set a strong password such as `PlayTest#2026!`).
5. Keep note of this password to enter in the Google Play Console below.

---

## 2. Where to Enter This in Google Play Console

1. Log in to [Google Play Console](https://play.google.com/console).
2. Select your app: **SparkQuest**.
3. In the left navigation menu, scroll down to **Policy and programs &rarr; App content**.
4. Find **App access** and click **Manage** (or **Start**).
5. Select: **All or some functionality is restricted**.
6. Click **+ Add new instructions** and enter the details below.

---

## 3. Reviewer Account Details to Copy-Paste

| Field | Value to Enter |
| :--- | :--- |
| **Title / Instruction Name** | `Play Store Reviewer Test Account` |
| **Username / Email** | `reviewer@sparkquest.app` |
| **Password** | *[Enter the password you configured in Supabase in Step 1]* |
| **Phone Number (Alternative)** | `+1 (555) 019-2026` |
| **Static OTP Code** | `123456` |

---

## 4. Explanation / Instructions for Google Reviewers

Copy and paste this text into the **"Explanation for Google"** / **"Any other instructions"** box:

```text
To review SparkQuest:

1. Launch SparkQuest on the device.
2. Navigate to the Profile tab and tap "Account & Cloud Sync (Sign In)".
3. Select the "✉️ Email" tab on the sign-in modal.
4. Enter the credentials provided above (reviewer@sparkquest.app and password) and tap "Sign In 🚀".
5. This reviewer account allows testing of:
   - Profile exploration, Discovery Radar, and interactive OSM maps.
   - Pre-loaded mutual matches (Maya, Sophia, Alex) to test chat messaging and Date Shield safety.
   - Drop-In Voice Lounges and BLE Proximity Discovery Radar.
   - Google Play Billing sandbox products (Embers & Gold VIP subscriptions).
```

---

## 5. Security & Store Policy Compliance

* **No Public Bypasses**: The release app contains no public "Reviewer" buttons or bypass switches that grant free currency or VIP status, ensuring 100% compliance with Google Play Payments Policy.
* **Standard Authentication**: Reviewers authenticate through standard Supabase email & password authentication, exactly as real users do.
