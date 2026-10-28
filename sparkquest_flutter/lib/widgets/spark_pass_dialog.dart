import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

class SparkPassDialog extends StatefulWidget {
  final int currentXP;
  final Function(int embers) onRewardClaimed;
  const SparkPassDialog({
    super.key,
    this.currentXP = 450,
    required this.onRewardClaimed,
  });

  @override
  State<SparkPassDialog> createState() => _SparkPassDialogState();
}

class _SparkPassDialogState extends State<SparkPassDialog> {
  late ConfettiController _confettiController;
  late int _xp;
  final Set<int> _claimedTiers = {1, 2, 3};

  final List<Map<String, dynamic>> _tiers = [
    {
      'tier': 1,
      'title': 'Novice Wanderer',
      'xp': 0,
      'reward': '50 Embers',
      'icon': '🔥',
      'embers': 50,
      'vip': false,
    },
    {
      'tier': 2,
      'title': 'Matchmaker Initiate',
      'xp': 100,
      'reward': '100 Embers',
      'icon': '🔥',
      'embers': 100,
      'vip': false,
    },
    {
      'tier': 3,
      'title': 'Cyberpunk Glow',
      'xp': 250,
      'reward': '⚡ Cyberpunk Ring',
      'icon': '⚡',
      'embers': 0,
      'vip': false,
    },
    {
      'tier': 4,
      'title': 'Explorer Keen',
      'xp': 450,
      'reward': '2x Booster (1h)',
      'icon': '🚀',
      'embers': 50,
      'vip': false,
    },
    {
      'tier': 5,
      'title': 'Phoenix Rising',
      'xp': 700,
      'reward': '🔥 Phoenix Flame',
      'icon': '🔥',
      'embers': 0,
      'vip': false,
    },
    {
      'tier': 6,
      'title': 'Quest Veteran',
      'xp': 1000,
      'reward': '250 Embers',
      'icon': '🔥',
      'embers': 250,
      'vip': false,
    },
    {
      'tier': 7,
      'title': 'Golden Spotlight',
      'xp': 1400,
      'reward': 'Spotlight (30m)',
      'icon': '🌟',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 8,
      'title': 'Galactic Aura',
      'xp': 1900,
      'reward': '🌌 Galactic Aura',
      'icon': '🌌',
      'embers': 0,
      'vip': false,
    },
    {
      'tier': 9,
      'title': 'Urban Legend',
      'xp': 2500,
      'reward': '500 Embers',
      'icon': '🔥',
      'embers': 500,
      'vip': false,
    },
    {
      'tier': 10,
      'title': 'Neon Sovereign',
      'xp': 3200,
      'reward': '👑 Neon Crown',
      'icon': '👑',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 11,
      'title': 'Night Scout',
      'xp': 4000,
      'reward': '150 Embers',
      'icon': '🔥',
      'embers': 150,
      'vip': false,
    },
    {
      'tier': 12,
      'title': 'Prism Mirage',
      'xp': 4900,
      'reward': '💎 Diamond Badge',
      'icon': '💎',
      'embers': 0,
      'vip': false,
    },
    {
      'tier': 13,
      'title': 'Date Maestro',
      'xp': 5900,
      'reward': '3x Super Sparks',
      'icon': '✨',
      'embers': 100,
      'vip': true,
    },
    {
      'tier': 14,
      'title': 'Cosmic Voyager',
      'xp': 7000,
      'reward': '350 Embers',
      'icon': '🔥',
      'embers': 350,
      'vip': false,
    },
    {
      'tier': 15,
      'title': 'Celestial Spark',
      'xp': 8200,
      'reward': '✨ Stardust Frame',
      'icon': '✨',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 16,
      'title': 'Vibe Master',
      'xp': 9500,
      'reward': '200 Embers',
      'icon': '🔥',
      'embers': 200,
      'vip': false,
    },
    {
      'tier': 17,
      'title': 'Double Rainbow',
      'xp': 11000,
      'reward': '5x Rewinds',
      'icon': '⏪',
      'embers': 0,
      'vip': false,
    },
    {
      'tier': 18,
      'title': 'Midnight Legend',
      'xp': 12600,
      'reward': '600 Embers',
      'icon': '🔥',
      'embers': 600,
      'vip': false,
    },
    {
      'tier': 19,
      'title': 'Solar Flare',
      'xp': 14300,
      'reward': '☀️ Solar Frame',
      'icon': '☀️',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 20,
      'title': 'Grandmaster Seeker',
      'xp': 16100,
      'reward': '1,000 Embers',
      'icon': '🏆',
      'embers': 1000,
      'vip': false,
    },
    {
      'tier': 21,
      'title': 'Neon Phantom',
      'xp': 18000,
      'reward': '300 Embers',
      'icon': '🔥',
      'embers': 300,
      'vip': false,
    },
    {
      'tier': 22,
      'title': 'Chronos Shifter',
      'xp': 20000,
      'reward': 'Unlimited Rewinds',
      'icon': '⏳',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 23,
      'title': 'Aurora Borealis',
      'xp': 22200,
      'reward': '🌈 Aurora Frame',
      'icon': '🌈',
      'embers': 0,
      'vip': false,
    },
    {
      'tier': 24,
      'title': 'High Roller',
      'xp': 24500,
      'reward': '500 Embers',
      'icon': '🔥',
      'embers': 500,
      'vip': false,
    },
    {
      'tier': 25,
      'title': 'Quantum Spark',
      'xp': 27000,
      'reward': '⚛️ Quantum Ring',
      'icon': '⚛️',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 26,
      'title': 'Elite Trailblazer',
      'xp': 29600,
      'reward': '750 Embers',
      'icon': '🔥',
      'embers': 750,
      'vip': false,
    },
    {
      'tier': 27,
      'title': 'Heartstring Harmonizer',
      'xp': 32400,
      'reward': '10x Super Sparks',
      'icon': '💖',
      'embers': 200,
      'vip': true,
    },
    {
      'tier': 28,
      'title': 'Mythic Ranger',
      'xp': 35300,
      'reward': '1,200 Embers',
      'icon': '🔥',
      'embers': 1200,
      'vip': false,
    },
    {
      'tier': 29,
      'title': 'Stellar Ascension',
      'xp': 38400,
      'reward': '🌠 Shooting Star Frame',
      'icon': '🌠',
      'embers': 0,
      'vip': true,
    },
    {
      'tier': 30,
      'title': 'SparkQuest Godtier',
      'xp': 42000,
      'reward': '👑 Ascendant Crown & 2,500 ✦',
      'icon': '🔱',
      'embers': 2500,
      'vip': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _xp = widget.currentXP;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _claim(int tierNum, int embers) {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    setState(() {
      _claimedTiers.add(tierNum);
    });
    if (embers > 0) {
      widget.onRewardClaimed(embers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF13182C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 8),
                        Text(
                          'Season 1: Spark Pass',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // XP Progress Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Level 4: Explorer Keen',
                            style: TextStyle(
                              color: Color(0xFFA78BFA),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$_xp / 700 XP',
                            style: const TextStyle(
                              color: Color(0xFFEC4899),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_xp / 700).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEC4899),
                        ),
                        borderRadius: BorderRadius.circular(5),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 30 Tiers List
                const Text(
                  'Seasonal Track (30 Tiers)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: _tiers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _tiers[index];
                      final int tierNum = item['tier'];
                      final int reqXP = item['xp'];
                      final bool isUnlocked = _xp >= reqXP;
                      final bool isClaimed = _claimedTiers.contains(tierNum);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnlocked
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['icon'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Tier $tierNum: ${item['title']}',
                                        style: TextStyle(
                                          color: isUnlocked
                                              ? Colors.white
                                              : Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item['vip'] == true) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'VIP',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${item['reward']} • ${item['xp']} XP',
                                    style: const TextStyle(
                                      color: Color(0xFFA78BFA),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isClaimed)
                              const Text(
                                'Claimed ✓',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (isUnlocked)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC4899),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    _claim(tierNum, item['embers']),
                                child: const Text(
                                  'Claim',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const Text(
                                '🔒 Locked',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
              Color(0xFF06B6D4),
              Color(0xFFF59E0B),
            ],
          ),
        ],
      ),
    );
  }
}
