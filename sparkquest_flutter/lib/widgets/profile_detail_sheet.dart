import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProfileDetailSheet extends StatefulWidget {
  final Profile profile;
  final Function(String promptTitle, String replyText) onSparkPrompt;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const ProfileDetailSheet({
    super.key,
    required this.profile,
    required this.onSparkPrompt,
    required this.onLike,
    required this.onPass,
  });

  @override
  State<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<ProfileDetailSheet> {
  int _photoIndex = 0;
  bool _isPlayingVoice = false;
  int _voiceCountdown = 18;
  Timer? _voiceTimer;
  bool _isPlayingAnthem = false;
  int? _selectedPollIndex;

  List<Map<String, String>> get _prompts => [
    {
      'title': 'We’ll instantly click if...',
      'answer':
          'You’re always down for spontaneous coffee quests, rooftop trivia, or rating the best street tacos in the city 🌮✨',
    },
    {
      'title': 'Two truths and a lie 🎭',
      'answer':
          '1. I’ve hiked Half Dome at sunrise.\n2. I can beat anyone at Mario Kart Rainbow Road.\n3. I’ve never had iced matcha.',
    },
    {
      'title': 'Ideal first Co-Op Quest 🛡️',
      'answer': widget.profile.voicePromptText,
    },
  ];

  @override
  void dispose() {
    _voiceTimer?.cancel();
    super.dispose();
  }

  void _toggleVoicePlay() {
    HapticFeedback.selectionClick();
    if (_isPlayingVoice) {
      _voiceTimer?.cancel();
      setState(() => _isPlayingVoice = false);
    } else {
      setState(() {
        _isPlayingVoice = true;
        _voiceCountdown = 18;
      });
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_voiceCountdown <= 1) {
          timer.cancel();
          setState(() {
            _isPlayingVoice = false;
            _voiceCountdown = 18;
          });
        } else {
          setState(() => _voiceCountdown--);
        }
      });
    }
  }

  void _showPromptReplyDialog(
    BuildContext context,
    String promptTitle,
    String promptAnswer,
  ) {
    final controller = TextEditingController(
      text: 'Loved your "$promptTitle"! Count me in 🔥',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.neonCyan),
        ),
        title: Text(
          'Spark ${widget.profile.name}’s Prompt ✨',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promptTitle,
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promptAnswer,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write your reply to spark a match...',
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
              backgroundColor: AppTheme.sparkCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reply = controller.text.trim();
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onSparkPrompt(
                promptTitle,
                reply.isEmpty ? 'Loved your prompt! ✨' : reply,
              );
            },
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text('Send Spark & Match'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final gallery = profile.effectiveGallery;
    final userTags = StorageService.instance.getUserVibeTags();
    final userArchetype = StorageService.instance.getUserArchetype();
    final dynamicPct = profile.computeDynamicChemistry(userTags, userArchetype);
    final synergyReasons = profile.computeSynergyReasons(
      userTags,
      userArchetype,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.65,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // #1: Multi-Photo & Video Loop Carousel
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GestureDetector(
                  onTapUp: (details) {
                    final width = MediaQuery.of(context).size.width - 40;
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (details.localPosition.dx < width / 2) {
                        _photoIndex = (_photoIndex - 1 + gallery.length) %
                            gallery.length;
                      } else {
                        _photoIndex = (_photoIndex + 1) % gallery.length;
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      Image.asset(
                        gallery[_photoIndex],
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 320,
                          color: AppTheme.bgCard,
                          child: const Icon(
                            Icons.person,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      // Story Progress Bars at Top
                      Positioned(
                        top: 10,
                        left: 14,
                        right: 14,
                        child: Row(
                          children: List.generate(gallery.length, (i) {
                            return Expanded(
                              child: Container(
                                height: 3.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _photoIndex
                                      ? AppTheme.neonCyan
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (_photoIndex > 0)
                        Positioned(
                          top: 22,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.neonCyan),
                            ),
                            child: Text(
                              _photoIndex == 1
                                  ? '🎬 Live Quest Loop • Tap right →'
                                  : '📸 Adventure Snapshot ${_photoIndex + 1}/${gallery.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 22,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.emeraldGreen),
                          ),
                          child: Text(
                            '⚡ $dynamicPct% Chemistry',
                            style: const TextStyle(
                              color: AppTheme.emeraldGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 14,
                        right: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (profile.isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: AppTheme.neonCyan,
                                    size: 22,
                                  ),
                              ],
                            ),
                            if (profile.isFreeTonight)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.questGold.withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  '⚡ Free Tonight',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // #4: Relationship Intent & RPG Class Badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${profile.occupation} • ${profile.distance} • ${profile.pronouns}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.electricViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.electricViolet),
                    ),
                    child: Text(
                      profile.rpgClass,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.emeraldGreen.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      profile.relationshipIntent,
                      style: const TextStyle(
                        color: AppTheme.emeraldGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // #5: Horizontal Vitals & Lifestyle Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _vitalChip('📏 ${profile.height}'),
                    _vitalChip(profile.zodiac),
                    _vitalChip('🗣️ ${profile.languages}'),
                    ...profile.lifestyleVitals.map(_vitalChip),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Vibe Tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.tags
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.neonCyan.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // #2: 30-Second Playable Voice Prompt Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isPlayingVoice
                        ? AppTheme.neonCyan
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleVoicePlay,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.neonCyan),
                        ),
                        child: Icon(
                          _isPlayingVoice ? Icons.pause : Icons.play_arrow,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎙️ Voice Prompt (${_isPlayingVoice ? "${_voiceCountdown}s" : "0:18"})',
                            style: const TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.voicePromptText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(18, (index) {
                              final active = _isPlayingVoice &&
                                  index <= (18 - _voiceCountdown);
                              return Expanded(
                                child: Container(
                                  height: (index % 3 == 0) ? 14 : 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppTheme.neonCyan
                                        : Colors.white24,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // #6: Music Anthem / "Quest Theme Song" Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1DB954).withValues(alpha: 0.16),
                      AppTheme.bgCard,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isPlayingAnthem = !_isPlayingAnthem);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1DB954)),
                        ),
                        child: Icon(
                          _isPlayingAnthem ? Icons.graphic_eq : Icons.music_note,
                          color: const Color(0xFF1DB954),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎵 QUEST THEME ANTHEM',
                            style: TextStyle(
                              color: Color(0xFF1DB954),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${profile.anthemTitle} — ${profile.anthemArtist}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showPromptReplyDialog(
                          context,
                          'Quest Anthem: ${profile.anthemTitle}',
                          '${profile.anthemTitle} by ${profile.anthemArtist}',
                        );
                      },
                      child: const Text(
                        'Spark 🎵',
                        style: TextStyle(
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // #8: Interactive Poll Prompt ("My Ideal Sunday" / Vote to Spark)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.questGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.poll_outlined,
                          color: AppTheme.questGold,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'INTERACTIVE POLL • ${profile.pollQuestion}',
                            style: const TextStyle(
                              color: AppTheme.questGold,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(profile.pollOptions.length, (i) {
                      final option = profile.pollOptions[i];
                      final isChosen = _selectedPollIndex == i;
                      final pct = i == 0 ? 48 : (i == 1 ? 35 : 17);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedPollIndex = i);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isChosen
                                ? AppTheme.questGold.withValues(alpha: 0.2)
                                : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChosen
                                  ? AppTheme.questGold
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isChosen
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_selectedPollIndex != null)
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    color: isChosen
                                        ? AppTheme.questGold
                                        : AppTheme.textDim,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_selectedPollIndex != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.questGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            final chosen =
                                profile.pollOptions[_selectedPollIndex!];
                            Navigator.pop(context);
                            widget.onSparkPrompt(
                              profile.pollQuestion,
                              'Voted for "$chosen" — when are we going? 🙌',
                            );
                          },
                          icon: const Icon(Icons.send, size: 15),
                          label: const Text(
                            'Send Vote & Spark Match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // #16: Dynamic Compatibility & RPG Class Synergy Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.electricViolet.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppTheme.questGold,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'DYNAMIC SYNERGY & CLASS BREAKDOWN',
                          style: TextStyle(
                            color: AppTheme.questGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _synergyBar(
                      'Adventure Tempo',
                      (dynamicPct / 100).clamp(0.7, 0.99),
                      AppTheme.neonCyan,
                    ),
                    _synergyBar('Banter & Humor', 0.90, AppTheme.sparkCoral),
                    _synergyBar('Co-Op Quest Style', 0.95, AppTheme.questGold),
                    const SizedBox(height: 8),
                    ...synergyReasons.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.emeraldGreen,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Spark Prompts (Tap 💬 to Reply & Match)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ..._prompts.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p['title']!,
                              style: const TextStyle(
                                color: AppTheme.neonCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showPromptReplyDialog(
                                context,
                                p['title']!,
                                p['answer']!,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.sparkCoral.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.sparkCoral),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Spark 💬',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p['answer']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.sparkCoral,
                        side: const BorderSide(color: AppTheme.sparkCoral),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPass();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Pass'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLike();
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text(
                        'Send Spark',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vitalChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _synergyBar(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppTheme.bgInput,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(pct * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
