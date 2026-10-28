import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Embers & Economy ---
  int getEmbers() => _prefs?.getInt('user_embers') ?? 325;
  Future<void> saveEmbers(int count) async => await _prefs?.setInt('user_embers', count);

  int getStreak() => _prefs?.getInt('user_streak') ?? 3;
  Future<void> saveStreak(int streak) async => await _prefs?.setInt('user_streak', streak);

  // --- Security & Biometrics ---
  bool isBiometricLockEnabled() => _prefs?.getBool('biometric_lock_enabled') ?? false;
  Future<void> setBiometricLockEnabled(bool enabled) async => await _prefs?.setBool('biometric_lock_enabled', enabled);

  String getPinCode() => _prefs?.getString('user_security_pin') ?? '1234';
  Future<void> setPinCode(String pin) async => await _prefs?.setString('user_security_pin', pin);

  // --- Privacy & Modes ---
  bool isGhostMode() => _prefs?.getBool('ghost_mode_active') ?? false;
  Future<void> setGhostMode(bool active) async => await _prefs?.setBool('ghost_mode_active', active);

  // --- Offline Matches & Messages Cache ---
  List<Map<String, dynamic>> getCachedMessages(String matchId) {
    final raw = _prefs?.getString('chat_cache_$matchId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedMessages(String matchId, List<Map<String, dynamic>> messages) async {
    await _prefs?.setString('chat_cache_$matchId', jsonEncode(messages));
  }

  // --- UGC Safety: Blocked Users ---
  List<String> getBlockedUsers() {
    return _prefs?.getStringList('blocked_user_ids') ?? [];
  }

  Future<void> blockUser(String userId) async {
    final blocked = List<String>.from(getBlockedUsers());
    if (!blocked.contains(userId.toLowerCase())) {
      blocked.add(userId.toLowerCase());
      await _prefs?.setStringList('blocked_user_ids', blocked);
    }
  }

  Future<void> unblockUser(String userId) async {
    final blocked = List<String>.from(getBlockedUsers());
    blocked.remove(userId.toLowerCase());
    await _prefs?.setStringList('blocked_user_ids', blocked);
  }

  // --- User Profile Customization ---
  String getUserBio() =>
      _prefs?.getString('user_bio') ??
      'Building cool apps by day, chasing rooftop sunsets & co-op quests by night ✨';
  Future<void> saveUserBio(String bio) async =>
      await _prefs?.setString('user_bio', bio);

  String getUserOccupation() =>
      _prefs?.getString('user_occupation') ?? 'Software Engineer';
  Future<void> saveUserOccupation(String occupation) async =>
      await _prefs?.setString('user_occupation', occupation);

  String getUserArchetype() =>
      _prefs?.getString('user_archetype') ?? '🌌 Night Owl Strategist';
  Future<void> saveUserArchetype(String archetype) async =>
      await _prefs?.setString('user_archetype', archetype);

  String getSelectedFrame() =>
      _prefs?.getString('selected_avatar_frame') ?? 'cyber_cyan';
  Future<void> saveSelectedFrame(String frame) async =>
      await _prefs?.setString('selected_avatar_frame', frame);

  // --- Discovery Filter Preferences ---
  int getMinAge() => _prefs?.getInt('filter_min_age') ?? 18;
  int getMaxAge() => _prefs?.getInt('filter_max_age') ?? 38;
  int getMaxDistance() => _prefs?.getInt('filter_max_distance') ?? 25;
  bool getVerifiedOnly() => _prefs?.getBool('filter_verified_only') ?? false;
  String getSelectedVibe() => _prefs?.getString('filter_vibe') ?? 'All Vibes';

  Future<void> saveDiscoveryFilters({
    required int minAge,
    required int maxAge,
    required int maxDistance,
    required bool verifiedOnly,
    required String vibe,
  }) async {
    await _prefs?.setInt('filter_min_age', minAge);
    await _prefs?.setInt('filter_max_age', maxAge);
    await _prefs?.setInt('filter_max_distance', maxDistance);
    await _prefs?.setBool('filter_verified_only', verifiedOnly);
    await _prefs?.setString('filter_vibe', vibe);
  }

  // --- Account Deletion / Wipe ---
  Future<void> clearAllData() async {
    await _prefs?.clear();
  }

  // --- Phase 3: Dynamic Matches, Quests, XP & Onboarding ---
  List<Map<String, dynamic>> getSavedMatches() {
    final raw = _prefs?.getString('saved_match_conversations');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMatches(List<Map<String, dynamic>> matches) async {
    await _prefs?.setString('saved_match_conversations', jsonEncode(matches));
  }

  int getSeasonXp() => _prefs?.getInt('season_spark_xp') ?? 450;
  Future<void> saveSeasonXp(int xp) async =>
      await _prefs?.setInt('season_spark_xp', xp);

  Map<String, dynamic> getQuestProgressMap() {
    final raw = _prefs?.getString('daily_quests_progress');
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveQuestProgressMap(Map<String, dynamic> progress) async {
    await _prefs?.setString('daily_quests_progress', jsonEncode(progress));
  }

  bool isFtueCompleted() => _prefs?.getBool('ftue_completed') ?? false;
  Future<void> setFtueCompleted(bool completed) async =>
      await _prefs?.setBool('ftue_completed', completed);

  List<String> getUserVibeTags() =>
      _prefs?.getStringList('user_vibe_tags') ??
      ['🎮 Gaming', '☕ Coffee', '🏔️ Hiking'];
  Future<void> saveUserVibeTags(List<String> tags) async =>
      await _prefs?.setStringList('user_vibe_tags', tags);

  List<String> getRsvpedEvents() =>
      _prefs?.getStringList('rsvped_map_events') ?? [];
  Future<void> addRsvpedEvent(String eventId) async {
    final list = List<String>.from(getRsvpedEvents());
    if (!list.contains(eventId)) {
      list.add(eventId);
      await _prefs?.setStringList('rsvped_map_events', list);
    }
  }
}
