# SparkQuest — Official Version Release Notes & Update Guide

This document maintains the version history, short release notes, and future roadmap for **SparkQuest** (`com.sparkquest.sparkquest`).

---

## 📋 Release Summary

| Version | Build | Release Date | Channel | Status | Key Highlights |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **v2.0.0** | `+9` | Nov 2026 | Production / Closed Beta | 🟢 **Live** | Production Google AdMob Credentials (Live App ID & Ad Unit IDs for Banner, Interstitial, and Rewarded Ads), Signed Release Build |
| **v2.0.0** | `+8` | Nov 2026 | Production / Closed Beta | ⚪ Archive | Google Maps Tiles (Roadmap & Satellite Hybrid), Profile Sign Out Button, Zero UI Overlaps & Discovery Hub AppBar |
| **v2.0.0** | `+7` | Nov 2026 | Production / Closed Beta | ⚪ Archive | Google AdMob Ads (Rewarded Videos for Free Embers & Bonus Wheel Spins, Quests Banner, Deck Interstitials, Gold VIP Ad-Free Guarantee) |
| **v2.0.0** | `+6` | Nov 2026 | Production / Closed Beta | ⚪ Archive | Google Play Reviewer Hardening, Manifest Backup Disabled, Clean UI |
| **v2.1.0** | `+10` | Q1 2027 | Internal Testing | 🟡 Planned | Drop-in Audio Lounges, Guild Boss Battles, AR Moment Prompts |

---

## 🚀 Live Release: v2.0.0+9 (Production Google AdMob Credentials)

### 💰 1. Production AdMob Integration
- **Live Google AdMob Application ID**: Configured production App ID `ca-app-pub-3920607003046699~4123861578` in `AndroidManifest.xml`.
- **Live Banner Ad Unit**: Bound `ca-app-pub-3920607003046699/7588463864` on the Quests screen banner.
- **Live Interstitial Ad Unit**: Bound `ca-app-pub-3920607003046699/1094548563` for natural Explore deck breaks.
- **Live Rewarded Ad Unit**: Bound `ca-app-pub-3920607003046699/1262728662` in the Embers Vault (+25🔥) and Daily Fortune Wheel bonus spins.
- **Account Protection Safety Guard**: Automatically serves Google test ad units during development/testing (`kDebugMode`) to shield your AdMob account from invalid traffic strikes, switching to live production ad units in signed release packages.

---

## 📦 Previous Release: v2.0.0+8 (Google Maps, Sign Out & UI Polish)

### 🗺️ 1. Google Maps Integration & Layer Switcher
- **Google Maps Roadmap by Default**: Replaced CartoDB tiles with high-performance Google Maps raster tiles (`https://mt{s}.google.com/vt/lyrs=m...`), completely eliminating Carto API key requirements and watermarks.
- **Dynamic Map Layer Switcher**: New `Icons.layers` control allows users to switch between **Google Maps (Roadmap)**, **Google Satellite Hybrid**, and **OpenStreetMap Standard** on the fly, with selections persisted to local storage.

### 🚪 2. In-App Sign Out & Account Cloud Sync
- **Dedicated Sign Out Button**: Added prominent Sign Out button with confirmation dialog on the Profile screen, cleanly invalidating active session tokens while keeping local cache safe.
- **Account Status Indicator**: Displays live authenticated email address and cloud sync verification badge.

### 📐 3. UI Alignment & Overlap Fixes
- **Unified AppBar Discovery Hub**: Streamlined the top navigation bar from 6 crowded action buttons into 3 perfectly spaced elements: Embers Vault Chip, Date Guard SOS Shield, and a sleek `Widgets` Discovery Hub menu (Wheel, Spark Pass, Voice Lounges, BLE Radar).
- **Sequential Map Top Header**: Combined the Proximity Beacon alert and category filter chips into a single vertical column with guaranteed spacing, preventing overlap on narrow screens.
- **Explore Action Buttons Alignment**: Wrapped card swipe controls in `SafeArea` with calibrated button sizes for edge-to-edge Android displays.

---

## 🚀 Live Release: v2.0.0+7 (Google AdMob & Production Release)

### 📢 1. Google AdMob Integration & Rewarded Economy
- **Rewarded Video Ads (Embers Vault)**: Watch opt-in sponsored video ads in the Embers Vault to earn `+25🔥` Embers for free without in-app purchases.
- **Bonus Fortune Wheel Spins**: Exhausted your daily free spin? Watch a sponsored video ad to unlock an instant bonus spin on the Daily Fortune Wheel.
- **Non-Intrusive Quests Banner Ad**: Clean, standard 320x50 banner ad integrated at the base of the Quests screen with compliant "SPONSORED" badge.
- **Natural Deck Break Interstitials**: Frequency-capped interstitial ads after extended Exploration deck browsing (every 15 passes), never interrupting match celebrations or active chats.
- **100% Ad-Free Guarantee for Gold VIP**: All banner and interstitial ads are automatically suppressed for Gold VIP subscribers.

---

## 📦 Previous Release: v2.0.0+6 (Review Hardening)

### 🗺️ 1. Live OpenStreetMap & CartoDB Dark Radar Map
- **True Interactive Geographic Mapping**: Migrated from a static abstract grid to a full-featured `FlutterMap` layer using high-performance CartoDB Dark Matter / OSM tiles with smooth pinch-to-zoom, pan, and real street-level navigation.
- **Anchored Venue Markers**: Safe Haven cafes, cocktail lounges, and rooftop venues are anchored to precise GPS coordinates across San Francisco (and custom Teleport destinations).
- **500m Privacy Radius Blur**: Visual cyan geofence circle shows the active privacy-blurred zone around the user's location to prevent stalking.
- **Interactive Map Drops**: Tap to claim live Ember Drops (+50🔥, +100🔥) with haptic feedback, check in at Safe Havens (+40 XP), or trigger Co-Op Date Check-ins (+50🔥, +80 XP).
- **Proximity Beacon Radar**: Real-time beacon detection alerting users when compatible matches are within 300 ft, with one-tap Wave greetings.

### 🎨 2. Restored Brand Identity
- **Original Neon Flaming-Heart Logo**: Restored high-res neon logo asset across `assets/images/logo.jpg`, top navigation `AppBar`, Explorer Onboarding dialog, Cloud Auth screen, and all Android launcher icon densities (`mipmap-hdpi` through `mipmap-xxxhdpi`).

### ⚖️ 3. Economy & Monetization Balancing
- **Starter Balance**: Calibrated to `150🔥` (down from 325) for a realistic game economy.
- **Anti-Cheat Spend Guards**: `canAffordEmbers()` and `spendEmbers()` prevent negative balance exploits.
- **Daily Spark Grant Cooldown**: Restricted to 1 claim per calendar day (`CLAIMED ✓`).
- **Persistent Tavern Inventory**: Purchased Roses, Spotlight Boosts, and Streak Freezes persist across restarts.
- **Gold VIP Entitlements**: Automatic `2x` multiplier on earned embers, unlimited rewinds, and free admirer unblurring.

### 🛡️ 4. Fortress Safety & Store Compliance
- **Date Shield 2.0**: Safety check-in alerts, discreet Emergency Fake Escape Call, and community Safe Haven passes.
- **Google Play Compliance**: 3D Anti-Catfish liveness selfie check, user reporting with categorization, permanent blocking, and instant Account Deletion.

---

## 🔮 Upcoming Release: v2.1.0 (Q1 2027)

### Short Release Notes (Draft)
- **🎙️ Live Audio Lounges**: Drop-in voice chat rooms to talk with local singles before formal date matching.
- **⚔️ Co-Op Guild Raids**: Weekend team quests encouraging groups of adventurers to visit local partner cafes and art walks together.
- **📸 In-App AR Moments**: Interactive icebreaker camera mini-games when two matches check in at the same venue.
- **⚡ Proximity Wave 2.0**: BLE (Bluetooth Low Energy) beacon discovery when two SparkQuest users cross paths within 50 meters.

---

## 🔮 Future Roadmap: v2.2.0 (Q2 2027)

### Short Release Notes (Draft)
- **⌚ WearOS & Apple Watch Companion**: Discrete emergency panic button and heart-rate spike SOS alert.
- **🌐 Global Passport 2.0**: Seamless multi-city teleportation with real-time translation for international travelers.
- **🎟️ Direct Venue Reservations**: In-app reservations at curated community meetup spots and cafes.

---

## 🛠️ How to Update Version Labeling for Future Releases

When publishing future updates:
1. **Update `pubspec.yaml`**:
   ```yaml
   version: 2.1.0+5 # Increment version and build number
   ```
2. **Update `sparkquest_flutter/lib/widgets/release_notes_dialog.dart`**:
   - Move `v2.1.0` into the `CURRENT RELEASE` card.
   - Update the top version string (`v2.1.0+5`).
3. **Update `sparkquest_flutter/lib/screens/profile_screen.dart`**:
   - Update the version chip to `v2.1.0+5`.
4. **Append to `RELEASE_NOTES.md`** with the new version bullet points.
5. **Run release build script**:
   ```powershell
   ./scratch/v2_0_0_4_final_package.cmd
   ```

