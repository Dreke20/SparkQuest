import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/vibe_radar_dialog.dart';
import '../widgets/coop_quest_sheet.dart';
import '../widgets/icebreaker_games_sheet.dart';
import '../widgets/video_call_screen.dart';
import '../widgets/story_viewer_dialog.dart';
import '../widgets/moderation_dialogs.dart';
import '../services/supabase_service.dart';
import '../services/realtime_chat_service.dart';

class MatchesChatScreen extends StatefulWidget {
  final VoidCallback onOpenDateShield;
  final Function(int embers)? onAwardEmbers;

  const MatchesChatScreen({
    super.key,
    required this.onOpenDateShield,
    this.onAwardEmbers,
  });

  @override
  State<MatchesChatScreen> createState() => _MatchesChatScreenState();
}

class _MatchesChatScreenState extends State<MatchesChatScreen> {
  final Map<String, String> _cloudStoryCaptions = {};

  @override
  void initState() {
    super.initState();
    RealtimeChatService.instance.addListener(_onServiceUpdated);
    _loadCloudStories();
  }

  Future<void> _loadCloudStories() async {
    final rows = await SupabaseService.instance.fetchStories();
    if (!mounted || rows.isEmpty) return;
    setState(() {
      for (final row in rows) {
        final name = (row['user_name'] ?? '').toString().split(' ').first.toLowerCase();
        final caption = (row['caption'] ?? '').toString();
        if (name.isNotEmpty && caption.isNotEmpty) {
          _cloudStoryCaptions[name] = caption;
        }
      }
    });
  }

  @override
  void dispose() {
    RealtimeChatService.instance.removeListener(_onServiceUpdated);
    super.dispose();
  }

  void _onServiceUpdated() {
    if (!mounted) return;
    setState(() {});
    final pending = RealtimeChatService.instance.pendingOpenMatchName;
    if (pending != null) {
      RealtimeChatService.instance.pendingOpenMatchName = null;
      final list = RealtimeChatService.instance.getConversations();
      final match = list.where(
        (c) => c.name.toLowerCase() == pending.toLowerCase(),
      );
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openChatDetail(match.first);
        });
      }
    }
  }

  List<MatchConversation> get _visibleConversations =>
      RealtimeChatService.instance.getConversations();

  void _openStoryViewer(MatchConversation convo) {
    HapticFeedback.selectionClick();
    final key = convo.name.split(' ').first.toLowerCase();
    showDialog(
      context: context,
      builder: (ctx) => StoryViewerDialog(
        matchName: convo.name,
        photoAsset: convo.photoAsset,
        tags: convo.tags,
        customCaption: _cloudStoryCaptions[key],
        onReplySent: (replyText) {
          RealtimeChatService.instance.sendMessage(convo.name, replyText);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent story reply to ${convo.name}! ✨'),
              backgroundColor: AppTheme.neonCyan,
            ),
          );
          _openChatDetail(convo);
        },
      ),
    );
  }

  void _openPostStoryDialog() {
    final captionCtrl = TextEditingController(
      text: 'Grabbing an espresso at Neon Roasters ☕ Who is nearby?',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.neonCyan),
        ),
        title: const Text(
          '📸 Post 24h Spark Story',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uploads photo to Supabase Storage ("stories" bucket) & broadcasts to nearby matches for 24h.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'What quest are you on right now?',
                hintStyle: const TextStyle(color: AppTheme.textDim),
                filled: true,
                fillColor: AppTheme.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textDim),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final caption = captionCtrl.text.trim();
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              final cloudUrl = await SupabaseService.instance.uploadAssetToBucket(
                bucket: 'stories',
                assetPath: 'assets/images/alex.png',
                customFileName: 'story_alex.png',
              );
              await SupabaseService.instance.postStory(
                userName: 'Alex Explorer',
                avatarUrl: cloudUrl ?? 'assets/images/alex.png',
                imageUrl: cloudUrl ?? 'assets/images/alex.png',
                caption: caption.isEmpty ? 'Out on a Spark Quest ⚡' : caption,
              );
              widget.onAwardEmbers?.call(15);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      cloudUrl != null
                          ? '☁️ Story uploaded to Supabase Storage & posted! (+15🔥)'
                          : '📸 24h Story posted! (+15🔥)',
                    ),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              }
            },
            icon: const Icon(Icons.cloud_upload, size: 16),
            label: const Text(
              'Upload & Post',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openChatDetail(MatchConversation convo) async {
    RealtimeChatService.instance.markConversationRead(convo.name);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChatDetailScreen(
          conversation: convo,
          onOpenDateShield: widget.onOpenDateShield,
          onAwardEmbers: widget.onAwardEmbers,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _visibleConversations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New Matches Stories Row
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
          child: const Text(
            'New Sparks & Stories (Tap to View)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: conversations.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: _openPostStoryDialog,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.neonCyan,
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundImage: AssetImage(
                                  'assets/images/alex.png',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppTheme.neonCyan,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 13,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your Story',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neonCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final c = conversations[i - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _openStoryViewer(c),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.sparkCoral, AppTheme.neonCyan],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(c.photoAsset),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.name,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, _) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (ctx, i) {
              final c = conversations[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage(c.photoAsset),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      c.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDim,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.unreadCount > 0
                        ? AppTheme.neonCyan
                        : AppTheme.textSecondary,
                    fontWeight: c.unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
  final Function(int embers)? onAwardEmbers;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
    required this.onOpenDateShield,
    this.onAwardEmbers,
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
    _messages = RealtimeChatService.instance.getMessages(
      widget.conversation.name,
      widget.conversation.messages,
    );
    RealtimeChatService.instance.addListener(_onChatUpdated);
  }

  @override
  void dispose() {
    RealtimeChatService.instance.removeListener(_onChatUpdated);
    _msgController.dispose();
    super.dispose();
  }

  void _onChatUpdated() {
    if (mounted) {
      setState(() {
        _messages = RealtimeChatService.instance.getMessages(
          widget.conversation.name,
        );
      });
    }
  }

  void _sendMessage([String? textToSend, bool isVoice = false]) {
    final text = textToSend ?? _msgController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    RealtimeChatService.instance.sendMessage(widget.conversation.name, text);
    _msgController.clear();

    SupabaseService.instance.sendMessage(
      matchId: widget.conversation.id,
      senderId: 'user_me',
      content: text,
      isVoice: isVoice,
    );
  }

  void _openIcebreakerArcade() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IcebreakerGamesSheet(
        matchName: widget.conversation.name,
        onSendGameMessage: (msg) => _sendMessage(msg),
        onAwardEmbers: (embers) {
          widget.onAwardEmbers?.call(embers);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 +$embers Embers earned from Spark Arcade!'),
              backgroundColor: AppTheme.questGold,
            ),
          );
        },
      ),
    );
  }

  Future<void> _startCall({required bool isVoiceOnly}) async {
    HapticFeedback.mediumImpact();
    final durationSecs = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (ctx) => VideoCallScreen(
          matchName: widget.conversation.name,
          photoAsset: widget.conversation.photoAsset,
          isVoiceOnly: isVoiceOnly,
          onOpenDateShield: widget.onOpenDateShield,
        ),
      ),
    );
    if (durationSecs != null && durationSecs > 0 && mounted) {
      final callType = isVoiceOnly ? '🎙️ Voice Call' : '📹 Video Spark Date';
      _sendMessage('$callType completed (${durationSecs}s) ✨');
    }
  }

  void _openModerationModal() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => ReportBlockDialog(
        targetUserId: widget.conversation.id,
        targetUserName: widget.conversation.name,
        onUserBlocked: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🛡️ ${widget.conversation.name} has been blocked and removed.',
                ),
                backgroundColor: AppTheme.sparkCoral,
              ),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _openDateItinerary() {
    String selectedSlot = 'Thu • 6:30 PM';
    String selectedVenue = '☕ Neon Roasters (15% Safe Haven Perk)';
    bool autoArmShield = true;

    final slots = [
      'Thu • 6:30 PM',
      'Fri • 8:00 PM',
      'Sat • 4:00 PM',
      'Sun • 11:00 AM',
    ];
    final venues = [
      '☕ Neon Roasters (15% Safe Haven Perk)',
      '🕹️ Emporium Arcade (+50🔥 Bonus)',
      '🧗‍♂️ Dogpatch Boulders (Co-Op Climb)',
      '🍸 Skyline Pergola (Rooftop Sunset)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: AppTheme.questGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Schedule Co-Op Date: ${widget.conversation.name}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '1. Pick a Day & Time',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) {
                  final active = selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot, style: const TextStyle(fontSize: 11.5)),
                    selected: active,
                    selectedColor: AppTheme.electricViolet,
                    backgroundColor: AppTheme.bgCard,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppTheme.textSecondary,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setModalState(() => selectedSlot = slot);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                '2. Select Verified Safe Haven Venue',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              ...venues.map((v) {
                final active = selectedVenue == v;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setModalState(() => selectedVenue = v);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppTheme.questGold : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            v,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: active
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (active)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.questGold,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: autoArmShield,
                activeThumbColor: AppTheme.neonCyan,
                onChanged: (val) => setModalState(() => autoArmShield = val),
                title: const Text(
                  '🛡️ Auto-arm Date Shield 2.0 Check-in Timer',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkCoral,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onAwardEmbers?.call(25);
                  _sendMessage(
                    '📅 [Co-Op Date Invite] Let’s meet $selectedSlot at $selectedVenue! ${autoArmShield ? "(Date Shield Verified 🛡️)" : ""} ✨',
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text(
                  'Send Date Invite (+25🔥)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(widget.conversation.photoAsset),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.conversation.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '🔥 Flowing',
                  style: TextStyle(fontSize: 10, color: AppTheme.neonCyan),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            icon: const Icon(
              Icons.call_outlined,
              color: AppTheme.neonCyan,
              size: 19,
            ),
            tooltip: 'Voice Spark Call',
            onPressed: () => _startCall(isVoiceOnly: true),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            icon: const Icon(
              Icons.videocam_outlined,
              color: AppTheme.sparkCoral,
              size: 21,
            ),
            tooltip: 'Video Spark Date',
            onPressed: () => _startCall(isVoiceOnly: false),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            icon: const Text('🎮', style: TextStyle(fontSize: 16)),
            tooltip: 'Icebreaker Mini-Games',
            onPressed: _openIcebreakerArcade,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            icon: const Text('🤝', style: TextStyle(fontSize: 16)),
            tooltip: 'Co-Op Match Quest',
            onPressed: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => CoopQuestSheet(
                  matchName: widget.conversation.name,
                  onCompleted: (embers) {
                    widget.onAwardEmbers?.call(embers);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 +$embers Embers from Co-Op Quest!'),
                        backgroundColor: AppTheme.questGold,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            icon: const Icon(
              Icons.map_outlined,
              color: AppTheme.questGold,
              size: 19,
            ),
            tooltip: 'Plan Date Quest',
            onPressed: _openDateItinerary,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            icon: const Icon(
              Icons.flag_outlined,
              color: AppTheme.textSecondary,
              size: 19,
            ),
            tooltip: 'Report or Block User',
            onPressed: _openModerationModal,
          ),
          const SizedBox(width: 4),
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
                    const Text(
                      '⚡ Chemistry: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonCyan,
                      ),
                    ),
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
                    const Text(
                      '88% (Date Ready!)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) =>
                        VibeRadarDialog(matchName: widget.conversation.name),
                  ),
                  child: const Text(
                    '📊 Vibe Radar',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                const Text(
                  '🤝 Co-Op Quest: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.questGold,
                  ),
                ),
                const Text(
                  'Send 5 messages (4/5) · +25🔥',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
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
                final isVoice = m.text.contains('🎙️');
                return Align(
                  alignment: m.isSentByMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isVoice
                          ? const Color(0xFF1E1B4B)
                          : m.isSentByMe
                          ? AppTheme.electricViolet
                          : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isVoice
                            ? const Color(0xFF8B5CF6)
                            : m.isSentByMe
                            ? AppTheme.electricViolet
                            : Colors.white10,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isVoice) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => HapticFeedback.selectionClick(),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B5CF6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ılılıllı|l|lllı|',
                                style: TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '0:09',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          m.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.time,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (RealtimeChatService.instance.isTyping(widget.conversation.name))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.conversation.name} is typing',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('💬', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          // Sparky AI Wingman Suggestions Chips

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppTheme.bgDeep,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.questGold,
                  size: 16,
                ),
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
                    icon: const Icon(Icons.mic, color: Color(0xFF06B6D4)),
                    tooltip: 'Send Voice Note (Uploads to Supabase Storage)',
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final audioUrl = await SupabaseService.instance
                          .uploadVoiceNoteBytes(durationSec: 9);
                      _sendMessage(
                        audioUrl != null
                            ? '🎙️ Voice Note (0:09) • Synced to Cloud Storage'
                            : '🎙️ Voice Note (0:09) "Honestly the espresso tonic there changed my life haha"',
                        true,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: AppTheme.neonCyan,
                    ),
                    tooltip: 'Send Photo (Uploads to Supabase Storage)',
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final photoUrl = await SupabaseService.instance
                          .uploadAssetToBucket(
                            bucket: 'stories',
                            assetPath: 'assets/images/alex.png',
                            customFileName: 'chat_photo.png',
                          );
                      _sendMessage(
                        photoUrl != null
                            ? '📷 [Photo Uploaded to Cloud Storage ✨]'
                            : '📷 [Photo attached]',
                      );
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.sparkCoral,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
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
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
        onPressed: () {
          if (label.contains('trivia duel')) {
            _openIcebreakerArcade();
          } else {
            _sendMessage(label);
          }
        },
      ),
    );
  }
}
