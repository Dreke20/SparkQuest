# SparkQuest — Google Play Store Launch Kit & Compliance Guide

## 1. Release Artifacts & Signing Configuration
* **Application ID / Package**: `com.sparkquest.sparkquest`
* **Version**: `2.0.0+4` (`versionName: 2.0.0`, `versionCode: 4`)
* **Category**: Dating / Social Communication
* **Target Audience**: **18+ Strictly (Adults Only)**
* **Official Upload Keystore**: `sparkquest_flutter/android/app/upload-keystore.jks` (configured via `key.properties`, ignored by git)
* **Signed Google Play App Bundle (`.aab`)**: `sparkquest_flutter/build/app/outputs/bundle/release/app-release.aab`
* **Signed Release APK (`.apk`)**: `sparkquest_flutter/build/app/outputs/flutter-apk/app-release.apk`
* **Linked Cloud Backend**: Supabase Project `kqvjntbiagzywstijtsz` (`https://kqvjntbiagzywstijtsz.supabase.co`)

---

## 2. Public URLs (Required for Play Console Submission)

* **Privacy Policy URL**:
  `https://dreke20.github.io/SparkQuest/privacy.html`
* **Child Safety Standards Policy URL**:
  `https://dreke20.github.io/SparkQuest/child-safety.html`
* **Account Deletion Web Portal**:
  `https://dreke20.github.io/SparkQuest/delete-account.html`
* **Terms of Service & UGC Standards**:
  `https://dreke20.github.io/SparkQuest/terms.html`
* **Landing Page**:
  `https://dreke20.github.io/SparkQuest/`
* **Support Email**: `support@sparkquest.app`
* **Safety & Child Protection Email**: `safety@sparkquest.app`

---

## 3. Store Listing Copy

### App Title (30 characters max)
`SparkQuest: Date & Co-Op Quests`

### Short Description (80 characters max)
`Turn first dates into real-world co-op adventures, trivia duels & local quests!`

### Full Description
Welcome to **SparkQuest** — the adventure dating app built to replace endless, repetitive swiping with real-world chemistry, gamified co-op quests, and safety-first meetups.

**🔥 KEY FEATURES:**
- **Live Dark Radar & Vibe Filters**: Pan and zoom real city streets using high-contrast CartoDB Dark Matter maps with 500m privacy blur protection. Discover nearby singles who share your exact dating archetype and active vibe.
- **In-Chat Icebreaker Arcade**: Skip "hey, how's your week?" and challenge your match to live 2-player **Trivia Duels**, **2 Truths & 1 Lie**, **Would You Rather**, or **Emoji Charades**.
- **Comfort Blur Calls**: Jump on a voice or video date directly in chat. Video dates start with gentle **Comfort Blur** that only reveals when both of you are ready, accompanied by **Sparky AI Wingman** prompts.
- **Safe Haven Partners**: Check in at verified local coffee shops, cocktail lounges, and bouldering gyms offering QR discounts (`SPARK-15`) and safety-trained angel-shot staff.
- **Date Shield 2.0 & Anti-Catfish Scan**: Built-in 3D liveness face verification, discreet Emergency Fake Escape Call, and live GPS sharing with trusted guardian friends.
- **Fair Play Economy**: Powered by Google Play In-App Billing for certified safe, transparent subscriptions and digital spark embers.

---

## 4. Google Play Compliance & Policies

| Policy Requirement | Implementation Status | Source Reference |
| :--- | :---: | :--- |
| **UGC Reporting (Zero Tolerance)** | ✅ Implemented & Cloud-Synced (`public.reports`) | `lib/widgets/moderation_dialogs.dart` |
| **User Blocking (Immediate Feed Removal)** | ✅ Implemented & Cloud-Synced (`public.blocks`) | `lib/widgets/moderation_dialogs.dart` |
| **In-App Account & Data Deletion** | ✅ Implemented via Cascading RPC (`delete_user_account`) | `lib/widgets/moderation_dialogs.dart` |
| **External Web Account Deletion URL** | ✅ Hosted via GitHub Pages | `docs/delete-account.html` |
| **Public Privacy Policy URL** | ✅ Hosted via GitHub Pages | `docs/privacy.html` |
| **Target Audience** | ✅ 18+ Strictly (Adults Only) | `DATA_SAFETY.md` |
| **Google Play Billing** | ✅ Integrated (`in_app_purchase: 3.3.1`) | `lib/services/iap_service.dart` |
| **Permissions Declared** | ✅ Location, Camera, Audio, Billing, Biometrics | `AndroidManifest.xml` |
| **Child Safety Standards Policy URL** | ✅ Hosted via GitHub Pages | `docs/child-safety.html` |
| **Child Safety In-App Reporting** | ✅ Implemented with P0 Escalation | `lib/widgets/moderation_dialogs.dart` |
| **Reviewer Demo Account** | ✅ Pre-configured (`reviewer@sparkquest.app`) | `GOOGLE_PLAY_REVIEWER_INSTRUCTIONS.md` |

---

## 5. Play Console App Access (Reviewer Credentials)

Under **Policy and programs &rarr; App content &rarr; App access**:
* **Email**: `reviewer@sparkquest.app`
* **Password**: `PlayReviewer2026!`
* **Phone / OTP**: `+1 (555) 019-2026` / `123456`
* See [`GOOGLE_PLAY_REVIEWER_INSTRUCTIONS.md`](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/GOOGLE_PLAY_REVIEWER_INSTRUCTIONS.md) for full review setup details.

---

## 6. Closed Testing Instructions (Personal Accounts)

1. Navigate to **Google Play Console &rarr; Testing &rarr; Closed testing**.
2. Create an **Alpha** or **Closed Beta** track and upload `app-release.aab`.
3. Add at least **12 testers** to an email list and share the opt-in URL:
   `https://play.google.com/apps/testing/com.sparkquest.sparkquest`
4. Testers must remain enrolled for **14 consecutive days** prior to applying for Production release.
