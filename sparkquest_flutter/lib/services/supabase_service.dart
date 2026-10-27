import 'dart:convert';
import 'dart:io';

/// Supabase Service for SparkQuest Flutter App
/// Project Ref: kqvjntbiagzywstijtsz
/// Direct PostgREST Client for Live Cloud Profiles, Matches, and Messages.
class SupabaseService {
  static const String projectRef = 'kqvjntbiagzywstijtsz';
  static const String baseUrl = 'https://kqvjntbiagzywstijtsz.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxdmpudGJpYWd6eXdzdGlqdHN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMjMzNzIsImV4cCI6MjEwODY5OTM3Mn0.Hwh0Rkdiu1SuZXmsyxshnbkwAviG46PM-yT8kbvp62E';

  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool isConnected = false;
  final HttpClient _httpClient = HttpClient();

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Test connectivity to linked Supabase project
  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/profiles?select=count');
      final request = await _httpClient.getUrl(uri);
      _headers.forEach((key, val) => request.headers.set(key, val));
      final response = await request.close();
      isConnected = response.statusCode >= 200 && response.statusCode < 300;
      return isConnected;
    } catch (_) {
      isConnected = false;
      return false;
    }
  }

  /// Fetch remote profiles
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/profiles?select=*&order=created_at.desc');
      final request = await _httpClient.getUrl(uri);
      _headers.forEach((key, val) => request.headers.set(key, val));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          isConnected = true;
          return List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch remote matches
  Future<List<Map<String, dynamic>>> fetchMatches() async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/matches?select=*&order=created_at.desc');
      final request = await _httpClient.getUrl(uri);
      _headers.forEach((key, val) => request.headers.set(key, val));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Post a chat message or voice note
  Future<bool> sendMessage({
    required String matchId,
    required String senderId,
    required String content,
    bool isVoice = false,
    int durationSec = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/messages');
      final request = await _httpClient.postUrl(uri);
      _headers.forEach((key, val) => request.headers.set(key, val));
      final payload = jsonEncode({
        'match_id': matchId,
        'sender_id': senderId,
        'content': content,
        'is_voice': isVoice,
        'duration_sec': durationSec,
      });
      request.write(payload);
      final response = await request.close();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Fetch Co-Op Quests
  Future<List<Map<String, dynamic>>> fetchCoopQuests(String matchId) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/coop_quests?match_id=eq.$matchId');
      final request = await _httpClient.getUrl(uri);
      _headers.forEach((key, val) => request.headers.set(key, val));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (_) {}
    return [];
  }
}
