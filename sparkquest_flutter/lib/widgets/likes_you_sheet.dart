import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile.dart';
import '../services/iap_service.dart';
import '../services/realtime_chat_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LikesYouSheet extends StatefulWidget {
  final VoidCallback onOpenChat;
  final Function(int embersDelta)? onSpendOrEarnEmbers;

  const LikesYouSheet({
    super.key,
    required this.onOpenChat,
    this.onSpendOrEarnEmbers,
  });

  @override
  State<LikesYouSheet> createState() => _LikesYouSheetState();
}

class _LikesYouSheetState extends State<LikesYouSheet> {
  late Set<String> _revealedIds;

  @override
  void initState() {
    super.initState();
    _revealedIds = StorageService.instance.getRevealedAdmirers().toSet();
    if (IAPService.instance.isGoldVip) {
      for (final a in _admirers) {
        _revealedIds.add(a.id);
      }
    }
  }

  final List<Profile> _admirers = const [
    Profile(
      id: 'jordan',
      name: 'Jordan',
      age: 28,
      occupation: 'Music Producer',
      distance: '1 mi away',
      photoAsset: 'assets/images/jordan.png',
      tags: ['🎵 Music', '🎬 Film', '🍷 Wine'],
      compatPct: 94,
      compatLevel: 'high',
      voicePromptText: 'Liked your Co-Op Trivia badge ⚡',
    ),
    Profile(
      id: 'taylor',
      name: 'Taylor',
      age: 26,
      occupation: 'Product Designer',
      distance: '3 mi away',
      photoAsset: 'assets/images/taylor.png',
      tags: ['🎨 Design', '☕ Coffee', '🎸 Guitar'],
      compatPct: 91,
      compatLevel: 'high',
      voicePromptText: 'Super-Sparked your Sunday morning prompt 🌟',
    ),
    Profile(
      id: 'riley',
      name: 'Riley',
      age: 24,
      occupation: 'Med Student',
      distance: '2 mi away',
      photoAsset: 'assets/images/riley.png',
      tags: ['🏃 Running', '🐕 Dogs', '📖 Reading'],
      compatPct: 88,
      compatLevel: 'high',
      voicePromptText: 'Liked your rooftop sunset photo 🌅',
    ),
    Profile(
      id: 'sophia',
      name: 'Sophia',
      age: 24,
      occupation: 'Photographer',
      distance: '2 mi away',
      photoAsset: 'assets/images/sophia.png',
      tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'],
      compatPct: 92,
      compatLevel: 'high',
      voicePromptText: 'Waved from Neon Roasters ☕',
    ),
  ];

  void _revealSingle(Profile admirer) {
    if (!IAPService.instance.isGoldVip) {
      if (!StorageService.instance.canAffordEmbers(30)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Need 30🔥 Embers (or Gold VIP) to unblur this admirer!'),
            backgroundColor: AppTheme.sparkCoral,
          ),
        );
        return;
      }
      widget.onSpendOrEarnEmbers?.call(-30);
    }
    HapticFeedback.selectionClick();
    setState(() => _revealedIds.add(admirer.id));
    StorageService.instance.saveRevealedAdmirers(_revealedIds.toList());
  }

  void _revealAll() {
    if (!IAPService.instance.isGoldVip) {
      if (!StorageService.instance.canAffordEmbers(75)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Need 75🔥 Embers (or Gold VIP) to unblur all 4 admirers!'),
            backgroundColor: AppTheme.sparkCoral,
          ),
        );
        return;
      }
      widget.onSpendOrEarnEmbers?.call(-75);
    }
    HapticFeedback.mediumImpact();
    setState(() {
      for (final a in _admirers) {
        _revealedIds.add(a.id);
      }
    });
    StorageService.instance.saveRevealedAdmirers(_revealedIds.toList());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔮 All Secret Admirers unblurred! Tap any card to match.'),
        backgroundColor: AppTheme.questGold,
      ),
    );
  }

  void _matchBack(Profile admirer) {
    HapticFeedback.heavyImpact();
    RealtimeChatService.instance.addMatchFromProfile(admirer);
    RealtimeChatService.instance.sendMessage(
      admirer.name,
      '⚡ Instant Spark Back! Saw that you liked my profile — ready for a Co-Op Quest?',
    );
    RealtimeChatService.instance.pendingOpenMatchName = admirer.name;
    Navigator.pop(context);
    widget.onOpenChat();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppTheme.textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('💘 ', style: TextStyle(fontSize: 22)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admirer Vault (4 Liked You)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Explorers who already sent you a Spark',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_revealedIds.length < _admirers.length)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.questGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _revealAll,
                    icon: const Icon(Icons.visibility, size: 15),
                    label: Text(
                      IAPService.instance.isGoldVip
                          ? 'Unblur All (VIP)'
                          : 'Unblur All (75🔥)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: GridView.builder(
                itemCount: _admirers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (ctx, i) {
                  final admirer = _admirers[i];
                  final isRevealed = _revealedIds.contains(admirer.id);
                  return GestureDetector(
                    onTap: () {
                      if (!isRevealed) {
                        _revealSingle(admirer);
                      } else {
                        _matchBack(admirer);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRevealed
                              ? AppTheme.neonCyan
                              : AppTheme.sparkCoral.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: isRevealed ? 0 : 14,
                              sigmaY: isRevealed ? 0 : 14,
                            ),
                            child: Image.asset(
                              admirer.photoAsset,
                              fit: BoxFit.cover,
                              cacheWidth: 360,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${admirer.compatPct}%⚡',
                                style: const TextStyle(
                                  color: AppTheme.neonCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (!isRevealed)
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_open,
                                    color: AppTheme.questGold,
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to Reveal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRevealed
                                      ? '${admirer.name}, ${admirer.age}'
                                      : 'Secret Admirer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  admirer.voicePromptText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isRevealed
                                          ? AppTheme.sparkCoral
                                          : AppTheme.electricViolet,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (!isRevealed) {
                                        _revealSingle(admirer);
                                      } else {
                                        _matchBack(admirer);
                                      }
                                    },
                                    child: Text(
                                      isRevealed
                                          ? 'Spark Back 💬'
                                          : 'Unblur (30🔥)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

