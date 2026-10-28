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
}
