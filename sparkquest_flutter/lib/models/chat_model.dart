class ChatMessage {
  final String id;
  final String text;
  final String? mediaAsset;
  final String time;
  final bool isSentByMe;

  ChatMessage({
    required this.id,
    required this.text,
    this.mediaAsset,
    required this.time,
    required this.isSentByMe,
  });
}

class MatchConversation {
  final String id;
  final String name;
  final String photoAsset;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final List<String> tags;
  final List<ChatMessage> messages;

  MatchConversation({
    required this.id,
    required this.name,
    required this.photoAsset,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.tags,
    required this.messages,
  });

  static List<MatchConversation> get seedConversations => [
    MatchConversation(
      id: 'sophia',
      name: 'Sophia',
      photoAsset: 'assets/images/sophia.png',
      lastMessage: 'Hey! I love your hiking photos 🏔️ Where was that last trail?',
      time: '2:34 PM',
      unreadCount: 1,
      tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'],
      messages: [
        ChatMessage(
          id: '1',
          text: 'Hey! I love your hiking photos 🏔️ Where was that last trail?',
          time: '2:34 PM',
          isSentByMe: false,
        ),
      ],
    ),
    MatchConversation(
      id: 'jordan',
      name: 'Jordan',
      photoAsset: 'assets/images/jordan.png',
      lastMessage: 'Are we heading to the vinyl lounge this weekend? 🎵',
      time: 'Yesterday',
      unreadCount: 0,
      tags: ['🎵 Music', '🎬 Film', '🍷 Wine'],
      messages: [
        ChatMessage(
          id: '1',
          text: 'Are we heading to the vinyl lounge this weekend? 🎵',
          time: 'Yesterday',
          isSentByMe: false,
        ),
        ChatMessage(
          id: '2',
          text: 'Definitely, I heard they have great matcha too!',
          time: 'Yesterday',
          isSentByMe: true,
        ),
      ],
    ),
    MatchConversation(
      id: 'maya',
      name: 'Maya',
      photoAsset: 'assets/images/maya.png',
      lastMessage: 'Let’s do sunrise yoga at the overlook! 🌅',
      time: 'Oct 25',
      unreadCount: 0,
      tags: ['🧘 Yoga', '🌱 Vegan', '✈️ Travel'],
      messages: [
        ChatMessage(
          id: '1',
          text: 'Let’s do sunrise yoga at the overlook! 🌅',
          time: 'Oct 25',
          isSentByMe: false,
        ),
      ],
    ),
  ];
}
