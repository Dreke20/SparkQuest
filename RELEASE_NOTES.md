# SparkQuest — Official Version Release Notes & Update Guide

This document maintains the version history, short release notes, and future roadmap for **SparkQuest** (`com.sparkquest.sparkquest`).

---

## 📋 Release Summary

| Version | Build | Release Date | Channel | Status | Key Highlights |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **v2.0.0** | `+4` | Oct 2026 | Production / Closed Beta | 🟢 **Live** | Live Map, Restored Neon Logo, 50 Dating App Improvements, Balanced Economy |
| **v2.1.0** | `+5` | Q1 2027 | Internal Testing | 🟡 Planned | Drop-in Audio Lounges, Guild Boss Battles, AR Moment Prompts |
| **v2.2.0** | `+6` | Q2 2027 | Conceptual / Backlog | ⚪ Roadmap | Wearable Heart-Rate SOS, Global Passport 2.0, In-App Venue Reservations |

---

## 🚀 Live Release: v2.0.0+5 (Production Release)

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

