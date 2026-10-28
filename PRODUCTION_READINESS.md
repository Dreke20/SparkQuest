# SparkQuest — Production Readiness & Store Submission Guide

This document outlines the architecture, security hardening, and deployment procedures required to publish **SparkQuest** (`com.sparkquest.app`) to the Google Play Store and web environments.

---

## 🚀 What Was Implemented Across All 4 Phases

### Phase 1: Security & Android Native Hardening
1. **Removed Exposed Secrets**:
   - Stripped naked Groq API keys and demo credentials from client JavaScript files ([ai-service.js](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/www/js/ai-service.js) and [main_v2.js](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/www/main_v2.js)).
   - Implemented a secure dual-mode architecture: in production, calls can proxy through a backend endpoint (e.g. Supabase Edge Function), with optional developer keys and rich local creative fallbacks so the app never hangs offline.
2. **Crash Prevention (AdMob App ID)**:
   - Added Google AdMob App ID `<meta-data>` in [AndroidManifest.xml](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/android/app/src/main/AndroidManifest.xml) to prevent fatal native launch crashes.
3. **Android Permissions**:
   - Declared location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`), media (`CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`), notification (`POST_NOTIFICATIONS`), vibration, and billing permissions in `AndroidManifest.xml`.
4. **Capacitor Configuration**:
   - Upgraded [capacitor.config.json](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/capacitor.config.json) with plugin declarations and security flags (`allowMixedContent: false`, `webContentsDebuggingEnabled: false`).

---

### Phase 2: Store Compliance (Google Play & App Store Policies)
1. **Google Play In-App Billing Architecture**:
   - Standardized product SKUs in [payment-service.js](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/www/js/payment-service.js) (`com.sparkquest.app.embers100`, `com.sparkquest.app.sub_silver_monthly`, etc.).
   - Integrated native billing bridge support for Android with fallback sandbox mode for web previews.
   - Added a mandatory **Restore Purchases** flow for subscriptions.
2. **UGC Safety & Content Moderation**:
   - Added **Report User Modal** (`#report-modal`) with categorization (harassment, inappropriate content, fake profile, underage, spam) connected to Supabase `reports` table.
   - Added **Block User Action** that immediately removes blocked accounts from discovery, chat, and database queries.
3. **Account Deletion Flow**:
   - In compliance with Google Play's 2024 Account Deletion policy, added an in-app **Delete Account** confirmation modal that wipes personal profiles, swipes, matches, and messages via the `delete_user_account()` RPC.
4. **Policy Scrubbing**:
   - Replaced policy-prohibited features ("Enable NSFW Mode") with store-compliant features ("Priority Match Spotlight" and "Incognito Stealth Mode").

---

### Phase 3: Real Matchmaking & Supabase Backend
1. **Database Schema Enhancements** ([supabase-schema.sql](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/supabase-schema.sql)):
   - Added `matches`, `reports`, and `blocks` tables.
   - Fixed `messages` RLS policies so both sender and recipient can view conversation history.
   - Added `record_swipe_and_check_match` RPC function for atomic mutual spark detection.
   - Added `delete_user_account` RPC function for complete GDPR/store-compliant data deletion.
2. **Dynamic Discovery Deck**:
   - [db-service.js](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/www/js/db-service.js) queries live registered users, automatically filtering out accounts already swiped on or blocked.
   - Seamlessly blends live users with seeded profiles so the card deck is never empty on newly initialized databases.

---

### Phase 4: Release Pipeline & Build Automation
1. **Gradle Release Signing**:
   - Configured `signingConfigs.release` in [sparkquest_flutter/android/app/build.gradle.kts](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/sparkquest_flutter/android/app/build.gradle.kts) with `upload-keystore.jks`.
2. **GitHub Actions CI/CD** ([.github/workflows/android-build.yml](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/.github/workflows/android-build.yml)):
   - Automatically runs `flutter analyze`, `flutter test`, and builds both the signed Release APK (`app-release.apk`) and Google Play App Bundle (`app-release.aab`).

---

### Phases 5–12: Native Flutter v2.0 Top-Tier Dating App Upgrade (50 Improvements)
1. **Phase 5 & 6 — Cloud Storage, Live Call Signaling & Web PWA**:
   - Provisioned Supabase Storage buckets (`'avatars'`, `'stories'`, `'voice-notes'`) and live `public.call_signals` ringing/accept/decline flows in [supabase_service.dart](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/sparkquest_flutter/lib/services/supabase_service.dart).
2. **Phase 7 — Rich Profiles & Discovery Power-Ups (#1–#16)**:
   - Multi-photo story carousels, 18s playable voice prompts, music anthems, interactive 3-option poll prompts, Vitals & Intent badges, Standouts ✨ tab, Daily AI Fate Pairing, 2v2 Double-Date Party Queue, Free Tonight ⚡ filter, and Passport/Teleport Mode 🌍.
3. **Phase 8 — Next-Gen Chat, AI Wingman & Co-Op Social (#17–#25)**:
   - Double-tap & long-press emoji reactions (`❤️`, `🔥`, `😂`, `⚡`, `🙌`), quote-reply threading, `✓✓ Read` receipts, `⚡ Your Turn` badges, 72h match expiry + `+24h Extend`, context-aware AI Wingman chips, View-Once Snaps, and `"We Met IRL! (+50🔥)"` post-date check-ins.
4. **Phase 9 — Real-World Map, Venue QR Perks & Crossed Paths (#26–#32)**:
   - Safe Haven QR Pass (`SPARK-15`), 500m Map Privacy Blur shield, Weather-Smart Golden Hour suggestions, Crossed Paths ("Missed Connections") radar, community venue safety ratings, and Co-Op GPS check-ins.
5. **Phases 10–12 — Fortress Safety, RPG Guilds, Ember Tavern & Scale (#33–#50)**:
   - 7-Day Streak Calendar with Streak Freeze Shield, Ember Tavern Shop, Adventurer Interest Guilds (`public.guilds`), RPG Class Evolution Skill Tree, Campfire Snooze mode, Contact Exclusion Shield, Wingman Referrals (`SPARK-ALEX-100`), `nearby_profiles` geospatial RPC, and `public.analytics_events` telemetry.

---

## 🔑 Step-by-Step Store Launch Checklist

### 1. Generate an Android Release Keystore
Run this command in PowerShell or Bash to generate your upload signing key:

```bash
keytool -genkey -v -keystore release-keystore.jks -alias sparkquest -keyalg RSA -keysize 2048 -validity 10000
```
*Keep this keystore file and its passwords in a secure password manager. Losing this key prevents publishing future app updates.*

### 2. Configure GitHub Secrets (For Automated CI/CD)
To enable automatic signing on GitHub Actions pushes:
1. Encode your `release-keystore.jks` to base64:
   ```bash
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("release-keystore.jks")) | Set-Clipboard
   ```
2. In your GitHub repository, navigate to **Settings -> Secrets and variables -> Actions**.
3. Add the following repository secrets:
   - `ANDROID_KEYSTORE_BASE64`: The copied base64 string.
   - `KEYSTORE_PASSWORD`: The password chosen for the keystore.
   - `KEY_ALIAS`: `sparkquest`
   - `KEY_PASSWORD`: The key password.

### 3. Deploy the Database Schema
1. Open your [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **SQL Editor -> New Query**.
3. Paste the contents of [supabase-schema.sql](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/supabase-schema.sql) and click **Run**.
4. In **Authentication -> Providers**, ensure **Email** and **Anonymous Sign-ins** are enabled.

### 4. Google Play Console Submission Requirements
* **App Bundle**: Download `sparkquest-android-bundle` (`.aab`) from GitHub Actions artifacts and upload it to Google Play Console (Closed Testing or Production track).
* **Data Safety Form**:
  * *Location*: Approximate and Precise (for Spark Map and local drops).
  * *Photos & Audio*: Optional user uploads (Profile pictures and Voice Prompts).
  * *User IDs*: For account management and matchmaking.
  * *Purchases*: For Embers and subscriptions.
* **Account Deletion URL**: Google Play requires a publicly accessible web URL explaining how users can request account and data deletion (or directing them to the in-app Delete Account button).
* **Content Rating Questionnaire**: Complete the IARC questionnaire in Play Console (Social/Dating category, age rating 17+/18+).
* **In-App Products**: Register your in-app items in Google Play Console under **Monetize -> In-app products** matching the SKUs defined in `PaymentService`:
  - `com.sparkquest.app.embers100`
  - `com.sparkquest.app.embers500`
  - `com.sparkquest.app.embers1200`
  - `com.sparkquest.app.boost5`
  - `com.sparkquest.app.superlike10`
  - `com.sparkquest.app.sub_silver_monthly`
  - `com.sparkquest.app.sub_gold_monthly`
  - `com.sparkquest.app.sub_platinum_monthly`
