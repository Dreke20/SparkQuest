import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/vibe_radar_dialog.dart';

class MatchesChatScreen extends StatefulWidget {
  final VoidCallback onOpenDateShield;

  const MatchesChatScreen({super.key, required this.onOpenDateShield});

  @override
  State<MatchesChatScreen> createState() => _MatchesChatScreenState();
}

class _MatchesChatScreenState extends State<MatchesChatScreen> {
  final List<MatchConversation> _conversations = MatchConversation.seedConversations;

  void _openChatDetail(MatchConversation convo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChatDetailScreen(
          conversation: convo,
          onOpenDateShield: widget.onOpenDateShield,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New Matches Stories Row
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
          child: const Text(
            'New Sparks & Stories',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _conversations.length,
            itemBuilder: (ctx, i) {
              final c = _conversations[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.sparkCoral, AppTheme.neonCyan],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage(c.photoAsset),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(c.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(color: Colors.white12, height: 24),
        // Active Chats List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: const Text(
            'Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _conversations.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (ctx, i) {
              final c = _conversations[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage(c.photoAsset),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(c.time, style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
                  ],
                ),
                subtitle: Text(
                  c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.unreadCount > 0 ? AppTheme.neonCyan : AppTheme.textSecondary,
                    fontWeight: c.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: c.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.sparkCoral,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${c.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: () => _openChatDetail(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final MatchConversation conversation;
  final VoidCallback onOpenDateShield;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
    required this.onOpenDateShield,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);
  }

  void _sendMessage([String? textToSend]) {
    final text = textToSend ?? _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        time: 'Now',
        isSentByMe: true,
      ));
    });
    _msgController.clear();
  }

  void _openDateItinerary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.questGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'SparkQuest Itinerary: ${widget.conversation.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _itineraryStep('☕ 4:30 PM', 'Artisan Pour-Over', 'Blue Velvet Atelier'),
            _itineraryStep('🎨 5:45 PM', 'Indie Gallery Stroll', 'Arts District Collective'),
            _itineraryStep('🍸 7:15 PM', 'Rooftop Stargazing', 'Skyline Pergola'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sparkCoral,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _sendMessage('✨ I asked Sparky to plan our first quest! ☕ Pour-over → 🎨 Gallery → 🍸 Rooftop drinks. What do you think?');
              },
              child: const Text('Send Itinerary to Chat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itineraryStep(String time, String title, String loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(loc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(widget.conversation.photoAsset),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('🔥 Spark: Flowing Smoothly', style: TextStyle(fontSize: 11, color: AppTheme.neonCyan)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.neonCyan),
            tooltip: '6-Axis Vibe Radar',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => VibeRadarDialog(matchName: widget.conversation.name),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.questGold),
            tooltip: 'Plan Date Quest',
            onPressed: _openDateItinerary,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppTheme.neonCyan),
            tooltip: 'Date Shield',
            onPressed: widget.onOpenDateShield,
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Vibe Heatmeter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.bgCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('⚡ Chemistry: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                    Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.88,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('88% (Date Ready!)', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => VibeRadarDialog(matchName: widget.conversation.name),
                  ),
                  child: const Text('📊 Vibe Radar', style: TextStyle(fontSize: 11, color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Co-Op Quest Mini Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.bgSurface,
            child: Row(
              children: [
                const Text('🤝 Co-Op Quest: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.questGold)),
                const Text('Send 5 messages (4/5) · +25🔥', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.isSentByMe ? AppTheme.electricViolet : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: m.isSentByMe ? AppTheme.electricViolet : Colors.white10,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(m.time, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Sparky AI Wingman Suggestions Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppTheme.bgDeep,
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.questGold, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _suggestionChip('Ask about favorite coffee spot ☕'),
                        _suggestionChip('Challenge to a trivia duel 🎮'),
                        _suggestionChip('What’s the story behind your bio? ✨'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.bgSurface,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: AppTheme.neonCyan),
                    onPressed: () {
                      _sendMessage('📷 [Photo attached]');
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type something thoughtful...',
                        hintStyle: const TextStyle(color: AppTheme.textDim),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.sparkCoral,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: AppTheme.bgSurface,
        side: const BorderSide(color: AppTheme.electricViolet, width: 0.8),
        label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }
}
