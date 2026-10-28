import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import 'storage_service.dart';

class RealtimeChatService extends ChangeNotifier {
  static final RealtimeChatService instance = RealtimeChatService._internal();
  RealtimeChatService._internal();

  final Map<String, List<ChatMessage>> _conversations = {};
  final Map<String, bool> _typingStates = {};
  Function(String sender, String text)? onIncomingNotification;

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
    _persist(matchName);
    notifyListeners();

    // Trigger simulated match typing indicator and reply
    _simulateMatchReply(matchName, text);
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
}
