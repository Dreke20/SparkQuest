import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/profile.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'quest_progression_service.dart';

class RealtimeChatService extends ChangeNotifier {
  static final RealtimeChatService instance = RealtimeChatService._internal();
  RealtimeChatService._internal();

  final Map<String, List<ChatMessage>> _conversations = {};
  final Map<String, bool> _typingStates = {};
  List<MatchConversation>? _matchList;
  String? pendingOpenMatchName;
  Function(String sender, String text)? onIncomingNotification;

  /// Phase 5: Live Call Signaling via Supabase Realtime
  Function(Map<String, dynamic> callSignal)? onIncomingCall;
  String callSignalState = 'idle'; // 'idle' | 'ringing' | 'connected' | 'declined' | 'ended'
  String? activeCallRoomId;

  List<MatchConversation> getConversations() {
    if (_matchList == null) {
      final seeds = List<MatchConversation>.from(
        MatchConversation.seedConversations,
      );
      final saved = StorageService.instance.getSavedMatches();
      for (final item in saved) {
        final parsed = MatchConversation.fromJson(item);
        if (!seeds.any((s) => s.id.toLowerCase() == parsed.id.toLowerCase())) {
          seeds.insert(0, parsed);
        }
      }
      _matchList = seeds;
    }

    final blocked = StorageService.instance.getBlockedUsers();
    return _matchList!
        .where((c) => !blocked.contains(c.id.toLowerCase()))
        .toList();
  }

  MatchConversation addMatchFromProfile(Profile profile) {
    final list = getConversations();
    final existing = list.where(
      (c) =>
          c.id.toLowerCase() == profile.id.toLowerCase() ||
          c.name.toLowerCase() == profile.name.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final newConvo = MatchConversation(
      id: profile.id,
      name: profile.name,
      photoAsset: profile.photoAsset,
      lastMessage: 'It’s a Spark! Say hello to ${profile.name} ✨',
      time: 'Just now',
      unreadCount: 1,
      tags: profile.tags,
      messages: [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text:
              'Hey! We matched (${profile.compatPct}% compatibility) 🔥 Down for a co-op quest?',
          time: 'Just now',
          isSentByMe: false,
        ),
      ],
    );

    _matchList ??= List<MatchConversation>.from(
      MatchConversation.seedConversations,
    );
    _matchList!.insert(0, newConvo);
    _persistMatchList();
    notifyListeners();
    return newConvo;
  }

  void markConversationRead(String matchName) {
    if (_matchList == null) return;
    for (final c in _matchList!) {
      if (c.name.toLowerCase() == matchName.toLowerCase()) {
        c.unreadCount = 0;
      }
    }
    _persistMatchList();
    notifyListeners();
  }

  void _persistMatchList() {
    if (_matchList == null) return;
    StorageService.instance.saveMatches(
      _matchList!.map((c) => c.toJson()).toList(),
    );
  }

  List<ChatMessage> getMessages(String matchName, [List<ChatMessage>? seedMessages]) {
    if (!_conversations.containsKey(matchName)) {
      final cached = StorageService.instance.getCachedMessages(matchName);
      if (cached.isNotEmpty) {
        _conversations[matchName] = cached.map((e) => ChatMessage.fromJson(e)).toList();
      } else if (seedMessages != null && seedMessages.isNotEmpty) {
        _conversations[matchName] = List.from(seedMessages);
      } else {
        _conversations[matchName] = [
          ChatMessage(
            id: '1',
            text: 'Hey! Loved your profile photo from the sunset hike 🌄',
            time: '2:15 PM',
            isSentByMe: false,
          ),
          ChatMessage(
            id: '2',
            text: 'Thanks! That was at Skyline Peak. Have you done that trail?',
            time: '2:18 PM',
            isSentByMe: true,
          ),
          ChatMessage(
            id: '3',
            text: 'Yes! The scramble at the end is so fun. Ready for our co-op coffee quest?',
            time: '2:20 PM',
            isSentByMe: false,
          ),
        ];
      }
    }
    return _conversations[matchName] ?? [];
  }

  bool isTyping(String matchName) => _typingStates[matchName] ?? false;

  void sendMessage(String matchName, String text) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      time: timeStr,
      isSentByMe: true,
    );

    _conversations.putIfAbsent(matchName, () => []).add(userMsg);
    _updateConversationPreview(matchName, text, timeStr, isIncoming: false);
    _persist(matchName);
    QuestProgressionService.instance.incrementQuest('engage2', xpGain: 20);
    notifyListeners();

    // Trigger simulated match typing indicator and reply
    _simulateMatchReply(matchName, text);
  }

  void _updateConversationPreview(
    String matchName,
    String lastMsg,
    String timeStr, {
    required bool isIncoming,
  }) {
    getConversations();
    if (_matchList == null) return;
    for (final c in _matchList!) {
      if (c.name.toLowerCase() == matchName.toLowerCase()) {
        c.lastMessage = lastMsg;
        c.time = timeStr;
        if (isIncoming) {
          c.unreadCount += 1;
        }
      }
    }
    _persistMatchList();
  }

  void _simulateMatchReply(String matchName, String userText) {
    // 1. Start typing after 1.2s
    Timer(const Duration(milliseconds: 1200), () {
      _typingStates[matchName] = true;
      notifyListeners();

      // 2. Stop typing and send reply after 2.8s
      Timer(const Duration(milliseconds: 2800), () {
        _typingStates[matchName] = false;

        final replyText = _generateSmartReply(userText, matchName);
        final now = DateTime.now();
        final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

        final replyMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: replyText,
          time: timeStr,
          isSentByMe: false,
        );

        _conversations.putIfAbsent(matchName, () => []).add(replyMsg);
        _updateConversationPreview(
          matchName,
          replyText,
          timeStr,
          isIncoming: true,
        );
        _persist(matchName);
        notifyListeners();

        // Trigger in-app push notification
        onIncomingNotification?.call(matchName, replyText);
      });
    });
  }

  String _generateSmartReply(String input, String name) {
    final lower = input.toLowerCase();
    if (lower.contains('coffee') || lower.contains('drink') || lower.contains('meet')) {
      return 'That sounds amazing! How about this Thursday around 6 PM? ☕✨';
    }
    if (lower.contains('quest') || lower.contains('game') || lower.contains('level')) {
      return 'I accept the quest! We get double XP if we solve the riddle together 🛡️';
    }
    if (lower.contains('hike') || lower.contains('outdoor') || lower.contains('trail')) {
      return 'I know an awesome secret viewpoint on that trail! We definitely have to check it out 🌿';
    }
    return 'Haha absolutely! I was thinking the exact same thing 😊';
  }

  void _persist(String matchName) {
    final list = _conversations[matchName]?.map((m) => m.toJson()).toList() ?? [];
    StorageService.instance.saveCachedMessages(matchName, list);
  }

  // ==========================================
  // PHASE 5: LIVE CALL SIGNALING
  // ==========================================

  Future<void> initiateCallSignal({
    required String matchName,
    required String matchAvatar,
    required bool isVoiceOnly,
  }) async {
    final roomId = 'spark_call_${matchName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
    activeCallRoomId = roomId;
    callSignalState = 'ringing';
    notifyListeners();

    await SupabaseService.instance.createCallSignal(
      roomId: roomId,
      callerName: 'Alex Explorer',
      callerAvatar: matchAvatar,
      calleeId: matchName,
      callType: isVoiceOnly ? 'voice' : 'video',
    );

    Timer(const Duration(milliseconds: 1600), () async {
      if (activeCallRoomId == roomId && callSignalState == 'ringing') {
        callSignalState = 'connected';
        notifyListeners();
        await SupabaseService.instance.updateCallSignalStatus(
          roomId: roomId,
          status: 'accepted',
        );
      }
    });
  }

  Future<void> endCallSignal() async {
    final roomId = activeCallRoomId;
    callSignalState = 'ended';
    activeCallRoomId = null;
    notifyListeners();
    if (roomId != null) {
      await SupabaseService.instance.updateCallSignalStatus(
        roomId: roomId,
        status: 'ended',
      );
    }
  }

  void triggerIncomingCall({
    required String callerName,
    required String callerAvatar,
    bool isVoiceOnly = false,
  }) {
    final roomId = 'incoming_${callerName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
    activeCallRoomId = roomId;
    callSignalState = 'ringing';
    notifyListeners();

    SupabaseService.instance.createCallSignal(
      roomId: roomId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      calleeId: SupabaseService.instance.currentUserId ?? 'user_me',
      callType: isVoiceOnly ? 'voice' : 'video',
    );

    onIncomingCall?.call({
      'room_id': roomId,
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'is_voice_only': isVoiceOnly,
    });
  }
}
