# SparkQuest — Native Flutter Application (`sparkquest_flutter`)

Gamified RPG Social Discovery & Dating App built with Flutter, Supabase Cloud (`kqvjntbiagzywstijtsz`), and Google Play Billing.

---

## 🚀 Complete 4-Phase Architecture

### Phase 1: Persistence, Biometric Security & Realtime Chat
- **Local Storage Persistence (`lib/services/storage_service.dart`)**: Persists Embers, daily streaks, PIN & biometric lock settings, Ghost/Incognito mode, blocked users, discovery filters, quest progress, and offline message caches via `shared_preferences`.
- **Biometric App Lock (`lib/widgets/biometric_lock_screen.dart`)**: Full-screen security lock overlay supporting simulated Fingerprint scan and 4-digit PIN keypad.
- **Realtime Chat Engine (`lib/services/realtime_chat_service.dart` & `lib/widgets/notification_banner.dart`)**: Live typing indicators, smart contextual match replies, and slide-down in-app push notification banners.

### Phase 2: Interactive Arcade, Video Dates, Stories & Store Compliance
- **Spark Arcade Mini-Games (`lib/widgets/icebreaker_games_sheet.dart`)**: In-chat **Trivia Duel ⚡**, **2 Truths & 1 Lie 🎭**, **Would You Rather 🔥**, and **Emoji Charades 🧩** with Ember rewards.
- **Live Video & Voice Spark Calling (`lib/widgets/video_call_screen.dart`)**: Privacy-first **Comfort Blur-to-Clear** video filter, live Sparky AI conversation prompts, PIP camera preview, and Date Shield SOS trigger.
- **Fullscreen Match Stories Viewer (`lib/widgets/story_viewer_dialog.dart`)**: Animated progress bar, vibe tags, 1-tap emoji reactions, and direct story replies routed to chat.
- **Discovery Radar Filters & AI Bio Coach (`lib/widgets/discovery_filter_sheet.dart` & `lib/widgets/sparky_ai_wingman_sheet.dart`)**: Filter the Explore deck by Vibe tags, Age range, Distance, and Liveness verification; analyze and rewrite your bio with live AI Magnetism scoring (0–100).
- **Google Play & App Store UGC Moderation (`lib/widgets/moderation_dialogs.dart`)**: Report & Block User modal (`reports` & `blocks` tables) and mandatory in-app Account & Data Deletion (`delete_user_account` RPC).

### Phase 3: Connected Gameplay, Onboarding & Live Community Raids
- **Dynamic Match-to-Chat Pipeline**: Right-swiping any profile in `ExploreScreen` immediately adds them to your active **Matches & Stories** list and opens their chat thread.
- **Live Quest & Season Pass XP Engine (`lib/services/quest_progression_service.dart`)**: Swiping, messaging, checking in on the map, collecting drops, and playing arcade games automatically advance Daily Quests and Season 1 Spark Pass XP.
- **First-Time Explorer Onboarding (`lib/widgets/onboarding_ftue_dialog.dart`)**: 3-step RPG Dating Archetype & Vibe Signal selector with a +100 Ember & +100 XP Starter Chest.
- **Neon Night Community Raids (`lib/screens/map_screen.dart`)**: Map category filters (*All*, *Live Events*, *Safe Havens*, *Ember Drops*) and interactive Group Event RSVP & Check-In bottom sheets.

### Phase 4: Automated Verification & Release Build
- **Widget & Service Unit Tests (`test/widget_test.dart`)**: Automated verification of 5-tab navigation, `QuestProgressionService`, `RealtimeChatService`, and `StorageService` moderation.
- **Android Release Packaging**: Configured in `android/app/build.gradle.kts` for signed release APK and Play Store App Bundle builds.

---

## 🛠️ Commands

```bash
# Analyze codebase (0 issues)
flutter analyze

# Run automated test suite
flutter test

# Build production Android APK
flutter build apk --release
```
