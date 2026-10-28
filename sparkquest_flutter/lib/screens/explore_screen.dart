import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../models/profile.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_blind_match_dialog.dart';
import '../widgets/discovery_filter_sheet.dart';
import '../widgets/moderation_dialogs.dart';
import '../widgets/onboarding_ftue_dialog.dart';
import '../widgets/profile_detail_sheet.dart';
import '../widgets/likes_you_sheet.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/realtime_chat_service.dart';
import '../services/quest_progression_service.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback onEmbersEarned;
  final Function(int amount)? onBonusEmbers;
  final VoidCallback onOpenChat;

  const ExploreScreen({
    super.key,
    required this.onEmbersEarned,
    this.onBonusEmbers,
    required this.onOpenChat,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Profile> _cards = [];
  final List<Profile> _history = [];
  Offset _dragOffset = Offset.zero;
  bool _isPlayingVoice = false;
  String _activeVibe = 'All Vibes';
  String _teleportCity = 'San Francisco, CA';
  bool _freeTonightOnly = false;
  bool _showStandouts = false;
  bool _dismissedFateBanner = false;
  int _topCardPhotoIndex = 0;
  bool _ftueDone = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadFilteredDeck();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  void _loadFilteredDeck() {
    final blocked = StorageService.instance.getBlockedUsers();
    final minAge = StorageService.instance.getMinAge();
    final maxAge = StorageService.instance.getMaxAge();
    final verifiedOnly = StorageService.instance.getVerifiedOnly();
    final vibe = StorageService.instance.getSelectedVibe();
    final intent = StorageService.instance.getSelectedIntent();
    final strict = StorageService.instance.isDealbreakerStrict();
    final city = StorageService.instance.getTeleportCity();
    final freeTonight = StorageService.instance.isFreeTonightFilter();

    setState(() {
      _ftueDone = StorageService.instance.isFtueCompleted();
      _activeVibe = vibe;
      _teleportCity = city;
      _freeTonightOnly = freeTonight;
      _topCardPhotoIndex = 0;

      var filtered = Profile.seedProfiles.where((p) {
        if (blocked.contains(p.id.toLowerCase())) return false;
        if (p.age < minAge || p.age > maxAge) return false;
        if (verifiedOnly && !p.isVerified) return false;
        if (freeTonight && !p.isFreeTonight) return false;
        if (intent != 'All Intents' && p.relationshipIntent != intent) {
          return false;
        }
        if (vibe != 'All Vibes') {
          final vibeKeyword = vibe.split(' ').last.toLowerCase();
          final hasTag = p.tags.any(
            (t) => t.toLowerCase().contains(vibeKeyword),
          );
          if (!hasTag) return false;
        }
        return true;
      }).toList();

      if (filtered.isEmpty && !strict) {
        filtered = Profile.seedProfiles
            .where((p) => !blocked.contains(p.id.toLowerCase()))
            .toList();
      }

      _cards = filtered;
    });

    _syncCloudProfiles();
  }

  Future<void> _syncCloudProfiles() async {
    final remoteRows = await SupabaseService.instance.fetchProfiles();
    if (!mounted || remoteRows.isEmpty) return;

    final blocked = StorageService.instance.getBlockedUsers();
    final minAge = StorageService.instance.getMinAge();
    final maxAge = StorageService.instance.getMaxAge();
    final verifiedOnly = StorageService.instance.getVerifiedOnly();

    final remoteProfiles = remoteRows
        .where((r) => r['user_id']?.toString() != 'user_me')
        .map(Profile.fromCloudMap)
        .where((p) {
          if (blocked.contains(p.id.toLowerCase())) return false;
          if (p.age < minAge || p.age > maxAge) return false;
          if (verifiedOnly && !p.isVerified) return false;
          return !_cards.any(
            (existing) =>
                existing.id.toLowerCase() == p.id.toLowerCase() ||
                existing.name.split(' ').first.toLowerCase() ==
                    p.name.split(' ').first.toLowerCase(),
          );
        })
        .toList();

    if (remoteProfiles.isNotEmpty && mounted) {
      setState(() {
        _cards.addAll(remoteProfiles);
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _swipe(bool isRight) {
    if (_cards.isEmpty) return;
    HapticFeedback.mediumImpact();
    final top = _cards.removeAt(0);
    _history.add(top);
    _dragOffset = Offset.zero;
    _topCardPhotoIndex = 0;
    setState(() {});

    SupabaseService.instance.recordSwipeAndCheckMatch(
      targetId: top.id,
      direction: isRight ? 'right' : 'left',
    );

    if (isRight) {
      RealtimeChatService.instance.addMatchFromProfile(top);
      QuestProgressionService.instance.incrementQuest('engage1', xpGain: 15);
      _showMatchDialog(top);
    }
  }

  void _openProfileDetail(Profile profile) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileDetailSheet(
        profile: profile,
        onLike: () => _swipe(true),
        onPass: () => _swipe(false),
        onSparkPrompt: (promptTitle, replyText) {
          HapticFeedback.heavyImpact();
          if (_cards.isNotEmpty && _cards.first.id == profile.id) {
            _cards.removeAt(0);
            _history.add(profile);
            _topCardPhotoIndex = 0;
            setState(() {});
          }
          widget.onEmbersEarned();
          QuestProgressionService.instance.incrementQuest(
            'engage1',
            xpGain: 25,
          );
          RealtimeChatService.instance.addMatchFromProfile(profile);
          RealtimeChatService.instance.sendMessage(
            profile.name,
            '💬 Replied to "$promptTitle": $replyText',
          );
          RealtimeChatService.instance.pendingOpenMatchName = profile.name;
          widget.onOpenChat();
        },
      ),
    );
  }

  void _openLikesYouVault() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LikesYouSheet(
        onOpenChat: widget.onOpenChat,
        onSpendOrEarnEmbers: widget.onBonusEmbers,
      ),
    );
  }

  // #15: 2v2 Double-Date / Co-Op Party Matching Modal
  void _open2v2PartyModal() {
    HapticFeedback.selectionClick();
    String selectedWingman = StorageService.instance.getPartyWingman().isEmpty
        ? 'Alex (Night Owl Strategist)'
        : StorageService.instance.getPartyWingman();

    final duos = [
      {
        'names': 'Sophia & Maya',
        'classes': '🎨 Creative Alchemist × 🌿 Zen Pathfinder',
        'quest': '🍹 Rooftop Trivia & Tacos at El Techo (Tonight 7:30 PM)',
        'synergy': '96% 2v2 Party Synergy',
        'leadProfile': Profile.seedProfiles.first,
      },
      {
        'names': 'Taylor & Riley',
        'classes': '✨ Arcane Architect × 🛡️ Guardian Healer',
        'quest': '🕹️ Emporium Arcade 2v2 Mario Kart Showdown',
        'synergy': '93% 2v2 Party Synergy',
        'leadProfile': Profile.seedProfiles.last,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.groups, color: AppTheme.questGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '🛡️ 2v2 Double-Date Party Queue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Team up with a wingman for low-pressure 2v2 group dates!',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'YOUR CO-OP WINGMAN',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Alex (Night Owl Strategist)',
                      'Jordan (Maverick Bard)',
                    ].map((w) {
                      final active = selectedWingman == w;
                      return ChoiceChip(
                        label: Text(w),
                        selected: active,
                        selectedColor: AppTheme.neonCyan,
                        backgroundColor: AppTheme.bgCard,
                        labelStyle: TextStyle(
                          color: active ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          StorageService.instance.savePartyWingman(w);
                          setSheetState(() => selectedWingman = w);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AVAILABLE 2v2 DUOS NEARBY',
                    style: TextStyle(
                      color: AppTheme.questGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...duos.map((d) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '👯 ${d['names']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  d['synergy'] as String,
                                  style: const TextStyle(
                                    color: AppTheme.emeraldGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d['classes'] as String,
                            style: const TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d['quest'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.questGold,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final lead = d['leadProfile'] as Profile;
                                Navigator.pop(ctx);
                                widget.onBonusEmbers?.call(25);
                                RealtimeChatService.instance
                                    .addMatchFromProfile(lead);
                                RealtimeChatService.instance.sendMessage(
                                  lead.name,
                                  '🛡️ 2v2 Party Invite! Me + $selectedWingman are down for: ${d['quest']}',
                                );
                                RealtimeChatService
                                    .instance.pendingOpenMatchName = lead.name;
                                widget.onOpenChat();
                              },
                              icon: const Icon(Icons.bolt, size: 16),
                              label: const Text(
                                'Send 2v2 Party Spark (+25🔥)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _rewind() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No previous card to undo')));
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      final last = _history.removeLast();
      _cards.insert(0, last);
      _topCardPhotoIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏪ Second Chance Rewind used! Card restored to deck.'),
      ),
    );
  }

  void _showMatchDialog(Profile profile) {
    HapticFeedback.heavyImpact();
    widget.onEmbersEarned();
    _confettiController.play();

    showDialog(
      context: context,
      builder: (ctx) => Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppTheme.neonCyan,
              AppTheme.sparkCoral,
              AppTheme.questGold,
            ],
          ),
          AlertDialog(
            backgroundColor: AppTheme.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppTheme.sparkCoral, width: 2),
            ),
            title: const Center(
              child: Text(
                'IT’S A SPARK! 💘',
                style: TextStyle(
                  color: AppTheme.sparkCoral,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(profile.photoAsset),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 12),
                Text(
                  'You and ${profile.name} sparked!',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.questGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '+10 Embers Earned 🔥',
                    style: TextStyle(
                      color: AppTheme.questGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Keep Swiping',
                  style: TextStyle(color: AppTheme.textDim),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkCoral,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  RealtimeChatService.instance.pendingOpenMatchName =
                      profile.name;
                  widget.onOpenChat();
                },
                child: const Text(
                  'Send Message',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userTags = StorageService.instance.getUserVibeTags();
    final userArchetype = StorageService.instance.getUserArchetype();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (!_ftueDone)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                showDialog(
                  context: context,
                  builder: (ctx) => OnboardingFtueDialog(
                    onCompleted: (bonusEmbers) {
                      setState(() => _ftueDone = true);
                      widget.onBonusEmbers?.call(bonusEmbers);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🎁 Onboarding Complete! +$bonusEmbers Embers & +100 Season XP unlocked!',
                          ),
                          backgroundColor: AppTheme.questGold,
                        ),
                      );
                    },
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.questGold.withValues(alpha: 0.2),
                      AppTheme.electricViolet.withValues(alpha: 0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.questGold.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('🎁 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Complete Explorer Class Setup (+100🔥)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.questGold,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),

          // #10: Mode Switcher (Swipe Deck vs Standouts ✨ vs 2v2 Party) + Likes & Filter
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Deck vs Standouts Toggle
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showStandouts = !_showStandouts);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _showStandouts
                            ? AppTheme.questGold.withValues(alpha: 0.25)
                            : AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _showStandouts
                              ? AppTheme.questGold
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showStandouts ? '🃏 Swipe Deck' : '✨ Standouts',
                            style: TextStyle(
                              color: _showStandouts
                                  ? AppTheme.questGold
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // #14: Free Tonight Quick Pill
                  InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final next = !_freeTonightOnly;
                      await StorageService.instance.setFreeTonightFilter(next);
                      _loadFilteredDeck();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _freeTonightOnly
                            ? AppTheme.emeraldGreen.withValues(alpha: 0.22)
                            : AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _freeTonightOnly
                              ? AppTheme.emeraldGreen
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        '⚡ Free Tonight',
                        style: TextStyle(
                          color: _freeTonightOnly
                              ? AppTheme.emeraldGreen
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // #15: 2v2 Party Button
                  InkWell(
                    onTap: _open2v2PartyModal,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.electricViolet.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.electricViolet.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '🛡️ 2v2 Party',
                        style: TextStyle(
                          color: AppTheme.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Likes You Vault
                  InkWell(
                    onTap: _openLikesYouVault,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sparkCoral.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.sparkCoral.withValues(alpha: 0.55),
                        ),
                      ),
                      child: const Text(
                        '💘 4 Liked You',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Mystery Match
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => MysteryBlindMatchDialog(
                          onAwardEmbers: (val) {
                            if (widget.onBonusEmbers != null) {
                              widget.onBonusEmbers!(val);
                            } else {
                              widget.onEmbersEarned();
                            }
                          },
                          onOpenChat: widget.onOpenChat,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔮 ', style: TextStyle(fontSize: 11)),
                          Text(
                            'Mystery Match',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Radar Filters
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => DiscoveryFilterSheet(
                          onFiltersChanged: _loadFilteredDeck,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeVibe == 'All Vibes' &&
                                  _teleportCity == 'San Francisco, CA'
                              ? Colors.white12
                              : AppTheme.neonCyan,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune,
                            size: 14,
                            color: AppTheme.neonCyan,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _teleportCity != 'San Francisco, CA'
                                ? '🌍 ${_teleportCity.split(',').first}'
                                : _activeVibe,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // #11: "Most Compatible" Daily AI Fate Pairing Banner
          if (!_dismissedFateBanner && !_showStandouts && _cards.isNotEmpty)
            GestureDetector(
              onTap: () => _openProfileDetail(_cards.first),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.neonCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daily Fate Pairing: ${_cards.first.name} (${_cards.first.computeDynamicChemistry(userTags, userArchetype)}% Class Synergy)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _dismissedFateBanner = true),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: AppTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Main Content: Either Standouts Carousel OR Card Stack
          if (_showStandouts)
            Expanded(child: _buildStandoutsList(userTags, userArchetype))
          else if (_cards.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.radar, size: 72, color: AppTheme.neonCyan),
                    const SizedBox(height: 16),
                    const Text(
                      'All Caught Up on Sparks!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adjust Dealbreaker filters or tap Reload below.',
                      style: TextStyle(color: AppTheme.textDim),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload Profiles'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricViolet,
                      ),
                      onPressed: _loadFilteredDeck,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: Stack(
                children: [
                  if (_cards.length > 1)
                    Transform.scale(
                      scale: 0.94,
                      child: _buildCardContent(
                        _cards[1],
                        isTop: false,
                        userTags: userTags,
                        userArchetype: userArchetype,
                      ),
                    ),
                  GestureDetector(
                    onTapUp: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      final width = box?.size.width ?? 360;
                      final gallery = _cards.first.effectiveGallery;
                      // Upper 55% taps cycle through photo story carousel; lower 45% opens deep-dive sheet
                      if (details.localPosition.dy < 260 &&
                          gallery.length > 1) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (details.localPosition.dx < width / 2) {
                            _topCardPhotoIndex =
                                (_topCardPhotoIndex - 1 + gallery.length) %
                                    gallery.length;
                          } else {
                            _topCardPhotoIndex =
                                (_topCardPhotoIndex + 1) % gallery.length;
                          }
                        });
                      } else {
                        _openProfileDetail(_cards.first);
                      }
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset += details.delta;
                      });
                    },
                    onPanEnd: (details) {
                      if (_dragOffset.dx > 120) {
                        _swipe(true);
                      } else if (_dragOffset.dx < -120) {
                        _swipe(false);
                      } else {
                        setState(() => _dragOffset = Offset.zero);
                      }
                    },
                    child: Transform.translate(
                      offset: _dragOffset,
                      child: Transform.rotate(
                        angle: _dragOffset.dx / 400 * (pi / 12),
                        child: _buildCardContent(
                          _cards.first,
                          isTop: true,
                          userTags: userTags,
                          userArchetype: userArchetype,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  // #10: Daily Standouts View
  Widget _buildStandoutsList(List<String> userTags, String userArchetype) {
    final standouts = Profile.seedProfiles.where((p) => p.isStandout).toList();
    return ListView.builder(
      itemCount: standouts.length,
      itemBuilder: (ctx, i) {
        final p = standouts[i];
        final chem = p.computeDynamicChemistry(userTags, userArchetype);
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.questGold.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openProfileDetail(p),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    p.photoAsset,
                    width: 84,
                    height: 102,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${p.name}, ${p.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified,
                          color: AppTheme.neonCyan,
                          size: 16,
                        ),
                        const Spacer(),
                        Text(
                          '⚡ $chem%',
                          style: const TextStyle(
                            color: AppTheme.questGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${p.rpgClass} • ${p.occupation}',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '"${p.voicePromptText}"',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => _openProfileDetail(p),
                          child: const Text(
                            'Inspect',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sparkCoral,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            RealtimeChatService.instance.addMatchFromProfile(p);
                            RealtimeChatService.instance.sendMessage(
                              p.name,
                              '🌹 Sent a Standout Super-Spark Rose!',
                            );
                            RealtimeChatService.instance.pendingOpenMatchName =
                                p.name;
                            widget.onOpenChat();
                          },
                          icon: const Text('🌹', style: TextStyle(fontSize: 12)),
                          label: const Text(
                            'Send Rose',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardContent(
    Profile profile, {
    required bool isTop,
    required List<String> userTags,
    required String userArchetype,
  }) {
    final gallery = profile.effectiveGallery;
    final activeIdx = isTop ? (_topCardPhotoIndex % gallery.length) : 0;
    final dynamicPct = profile.computeDynamicChemistry(userTags, userArchetype);
    final displayDistance = _teleportCity == 'San Francisco, CA'
        ? profile.distance
        : 'In ${_teleportCity.split(',').first} 🌍';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isTop && _dragOffset.dx > 50
                ? AppTheme.emeraldGreen.withValues(alpha: 0.4)
                : isTop && _dragOffset.dx < -50
                ? AppTheme.sparkCoral.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Current Carousel Image
          Image.asset(
            gallery[activeIdx],
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppTheme.bgSurface),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.2, 0.62, 1.0],
              ),
            ),
          ),
          // #1: Multi-Photo Story Progress Bars
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(gallery.length, (i) {
                return Expanded(
                  child: Container(
                    height: 3.5,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: i == activeIdx
                          ? AppTheme.neonCyan
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Compatibility Pill & Free Tonight Badge
          Positioned(
            top: 22,
            left: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.neonCyan),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: AppTheme.neonCyan,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$dynamicPct% Match',
                        style: const TextStyle(
                          color: AppTheme.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.isFreeTonight) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.questGold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⚡ Free Tonight',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Report / Block Moderation Button on Card (Top Right)
          Positioned(
            top: 22,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                showDialog(
                  context: context,
                  builder: (ctx) => ReportBlockDialog(
                    targetUserId: profile.id,
                    targetUserName: profile.name,
                    onUserBlocked: () {
                      _loadFilteredDeck();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🛡️ ${profile.name} has been blocked and removed from discovery.',
                          ),
                          backgroundColor: AppTheme.sparkCoral,
                        ),
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ),
          // Profile Details at Bottom
          Positioned(
            bottom: 18,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // RPG Class & Intent Mini Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.electricViolet.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.electricViolet.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        profile.rpgClass,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        profile.relationshipIntent,
                        style: const TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Name & Age & Verified
                Row(
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: const TextStyle(
                        fontSize: 27,
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
                    const Spacer(),
                    const Text(
                      'Tap for Prompts ↑',
                      style: TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${profile.occupation} · $displayDistance · ${profile.pronouns}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                // Voice Spark Pill
                if (profile.hasVoicePrompt)
                  GestureDetector(
                    onTap: () {
                      setState(() => _isPlayingVoice = !_isPlayingVoice);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPlayingVoice
                              ? AppTheme.neonCyan
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPlayingVoice
                                ? Icons.pause_circle
                                : Icons.play_circle_fill,
                            color: AppTheme.neonCyan,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profile.voicePromptText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _isPlayingVoice ? 'Playing...' : '18s',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind
          _circleButton(
            icon: Icons.replay,
            color: AppTheme.questGold,
            size: 48,
            onTap: _rewind,
          ),
          // Pass
          _circleButton(
            icon: Icons.close,
            color: AppTheme.sparkCoral,
            size: 60,
            onTap: () => _swipe(false),
          ),
          // SuperLike
          _circleButton(
            icon: Icons.star,
            color: AppTheme.neonCyan,
            size: 52,
            onTap: () => _swipe(true),
          ),
          // Like
          _circleButton(
            icon: Icons.favorite,
            color: AppTheme.emeraldGreen,
            size: 60,
            onTap: () => _swipe(true),
          ),
          // Boost
          _circleButton(
            icon: Icons.bolt,
            color: AppTheme.electricViolet,
            size: 48,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⚡ 1-Hour Super Boost Active! Profile 5x amplified.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.48),
        onPressed: onTap,
      ),
    );
  }
}
