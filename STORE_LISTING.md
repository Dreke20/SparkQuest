# SparkQuest — Google Play & Apple App Store Launch Kit

## 1. Release Artifacts & Signing Configuration
- **Application ID / Bundle ID**: `com.sparkquest.sparkquest`
- **Version**: `1.0.0+1` (`versionName: 1.0.0`, `versionCode: 1`)
- **Upload Keystore**: `sparkquest_flutter/android/app/upload-keystore.jks` (configured via `sparkquest_flutter/android/key.properties`)
- **Signed Google Play App Bundle (`.aab`)**: `sparkquest_flutter/build/app/outputs/bundle/release/app-release.aab`
- **Signed Release APK (`.apk`)**: `sparkquest_flutter/build/app/outputs/flutter-apk/app-release.apk`
- **Linked Cloud Backend**: Supabase Project `kqvjntbiagzywstijtsz` (`https://kqvjntbiagzywstijtsz.supabase.co`)

---

## 2. Store Listing Copy

### App Title (30 characters max)
`SparkQuest: Date & Co-Op Quests`

### Short Description (80 characters max)
`Turn first dates into real-world co-op adventures, trivia duels & local quests!`

### Full Description
Welcome to **SparkQuest** — the gamified social discovery and dating experience designed to replace endless small talk with real-world chemistry, interactive co-op quests, and safety-first meetups.

**🔥 WHY SPARKQUEST?**
- **Interactive Radar & Vibe Filters**: Discover nearby singles who share your exact RPG Dating Archetype and active vibe (Coffee Quests, Trail Running, Night Owl Arcades, Golden Hour).
- **In-Chat Icebreaker Arcade**: Skip "hey, how's your week?" and challenge your match to live 2-player **Trivia Duels**, **2 Truths & 1 Lie**, **Would You Rather**, or **Emoji Charades**.
- **Video & Voice Spark Calls with Comfort Blur**: Jump on a voice or video date directly in chat. Video calls start with a gentle **Comfort Blur** that unblurs only when you're both ready, plus live **Sparky AI Wingman** conversation prompts.
- **24-Hour Spark Stories & Voice Prompts**: Share spontaneous moments from your day or listen to 15-second Voice Sparks before you swipe.
- **Spark Map & Safe Haven Venues**: Explore verified local coffee shops, bouldering gyms, and arcade bars offering real-world check-in perks and +50 Ember drops.
- **Season 1 Spark Pass & Daily Quests**: Earn XP and Embers for authentic engagement, unlock Neon & Phoenix avatar frames, and spin the Daily Fortune Wheel.
- **Date Shield 2.0 & Anti-Catfish Verification**: Built-in Liveness Face Verification, discreet Escape Call simulation, Live GPS link sharing, and 30-minute Guardian Angel check-in timers.

---

## 3. Google Play Data Safety & UGC Compliance Checklist

| Policy Requirement | Implementation Status | Source Reference |
| :--- | :--- | :--- |
| **User-Generated Content (UGC) Reporting** | ✅ Implemented & Cloud-Synced (`public.reports`) | `lib/widgets/moderation_dialogs.dart` (`ReportBlockDialog`) |
| **User Blocking (Immediate Feed & Chat Removal)** | ✅ Implemented & Cloud-Synced (`public.blocks`) | `lib/widgets/moderation_dialogs.dart` (`ReportBlockDialog`) |
| **In-App Account & Data Deletion** | ✅ Implemented via Cascading RPC (`delete_user_account`) | `lib/widgets/moderation_dialogs.dart` (`DeleteAccountDialog`) |
| **Biometric & PIN Privacy Lock** | ✅ Implemented | `lib/widgets/biometric_lock_screen.dart` |
| **In-App Safety & Emergency Toolkit** | ✅ Implemented (`DateGuardDialog` & Escape Call) | `lib/widgets/date_guard_dialog.dart` |
| **Google Play Billing / IAP Products** | ✅ Configured (`sparkquest_embers_100`, `500`, `spotlight_boost`, `gold_vip`) | `lib/services/iap_service.dart` |

