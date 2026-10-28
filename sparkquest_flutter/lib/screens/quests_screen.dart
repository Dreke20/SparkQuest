import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/quest.dart';
import '../theme/app_theme.dart';
import '../services/quest_progression_service.dart';

class QuestsScreen extends StatefulWidget {
  final int streakDays;
  final Function(int amount) onClaimEmber;

  const QuestsScreen({
    super.key,
    required this.streakDays,
    required this.onClaimEmber,
  });

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  late ConfettiController _confettiController;
  bool _streakShieldArmed = true;
  String _selectedSubclass = '🌌 Astral Navigator (+15% Chemistry Boost)';
  final Set<String> _joinedGuilds = {
    '🏔️ SF Summit Hikers',
    '🕹️ Co-Op Arcade Guild',
  };

  List<QuestItem> get _quests => QuestProgressionService.instance.quests;

  @override
  void initState() {
    super.initState();
    QuestProgressionService.instance.loadFromStorage();
    QuestProgressionService.instance.addListener(_onProgressUpdated);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    QuestProgressionService.instance.removeListener(_onProgressUpdated);
    _confettiController.dispose();
    super.dispose();
  }

  void _onProgressUpdated() {
    if (mounted) setState(() {});
  }

  void _claim(QuestItem quest) {
    if (quest.isClaimed || !quest.isCompleted) return;
    QuestProgressionService.instance.claimQuest(quest.id);
    widget.onClaimEmber(quest.reward);
    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed +${quest.reward} Embers & +50 Season XP! 🎁'),
        backgroundColor: AppTheme.questGold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            AppTheme.questGold,
            AppTheme.sparkCoral,
            AppTheme.neonCyan,
          ],
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Streak Banner + #44 7-Day Streak Calendar & Streak Shield
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.questGold.withValues(alpha: 0.2),
                    AppTheme.sparkCoral.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.questGold.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.streakDays}-Day Spark Streak',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1.25x Multiplier • Season Pass: ${QuestProgressionService.instance.seasonXp} XP ⭐',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.questGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _streakShieldArmed = !_streakShieldArmed,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _streakShieldArmed
                                    ? '🛡️ Streak Freeze Armed: Your streak is protected for 24h!'
                                    : '⚠️ Streak Freeze Disarmed',
                              ),
                              backgroundColor: AppTheme.neonCyan,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _streakShieldArmed
                                ? AppTheme.neonCyan
                                : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _streakShieldArmed ? '🛡️ Protected' : 'Arm Shield',
                            style: TextStyle(
                              fontSize: 11,
                              color: _streakShieldArmed
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final done = dayNum <= widget.streakDays;
                      final isChest = dayNum == 7;
                      return Container(
                        width: 38,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.questGold.withValues(alpha: 0.25)
                              : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: done ? AppTheme.questGold : Colors.white12,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isChest ? '🎁' : (done ? '🔥' : '•'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'D$dayNum',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: done
                                    ? AppTheme.questGold
                                    : AppTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Quests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Resets in 6h 42m',
                  style: TextStyle(fontSize: 12, color: AppTheme.textDim),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quests List
            ..._quests.map(
              (q) => Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: q.isCompleted && !q.isClaimed
                        ? AppTheme.emeraldGreen
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Text(q.icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (q.current / q.target).clamp(0.0, 1.0),
                              backgroundColor: AppTheme.bgInput,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                q.isCompleted
                                    ? AppTheme.emeraldGreen
                                    : AppTheme.neonCyan,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${q.current} / ${q.target}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (q.isClaimed)
                      const Text(
                        'Done ✓',
                        style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (q.isCompleted)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _claim(q),
                        child: Text(
                          '+${q.reward}🔥',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgInput,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${q.reward}🔥',
                          style: const TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // RPG Stats Radar Header
            const Text(
              'Explorer Attributes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _statRow('Charisma', 0.85, AppTheme.sparkCoral),
                  _statRow('Intellect', 0.70, AppTheme.neonCyan),
                  _statRow('Adventure', 0.92, AppTheme.questGold),
                  _statRow('Empathy', 0.80, AppTheme.electricViolet),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Achievements Trophy Case
            const Text(
              'Achievements Trophy Case 🏆',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _achievementBadge(
                  icon: '⚡',
                  title: 'First Spark',
                  unlocked: true,
                ),
                _achievementBadge(
                  icon: '🎮',
                  title: 'Arcade Champ',
                  unlocked: true,
                ),
                _achievementBadge(
                  icon: '🛡️',
                  title: 'Safe Haven VIP',
                  unlocked: true,
                ),
                _achievementBadge(
                  icon: '🎙️',
                  title: 'Voice Pioneer',
                  unlocked: true,
                ),
                _achievementBadge(
                  icon: '🔮',
                  title: 'Blind Matcher',
                  unlocked: false,
                ),
                _achievementBadge(
                  icon: '👑',
                  title: '7-Day Legend',
                  unlocked: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Weekly City Leaderboard
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'San Francisco Weekly Leaderboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Top 3 win +250🔥',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.questGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _leaderboardRow(
                    rank: 1,
                    name: 'Chloe Sterling',
                    xp: 1250,
                    avatar: 'assets/images/riley.png',
                    isMe: false,
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _leaderboardRow(
                    rank: 2,
                    name: 'Kaelen Mercer',
                    xp: 980,
                    avatar: 'assets/images/jordan.png',
                    isMe: false,
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _leaderboardRow(
                    rank: 3,
                    name: 'Maya Lin',
                    xp: 780,
                    avatar: 'assets/images/maya.png',
                    isMe: false,
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _leaderboardRow(
                    rank: 4,
                    name: 'You (Alex Explorer)',
                    xp: QuestProgressionService.instance.seasonXp,
                    avatar: 'assets/images/alex.png',
                    isMe: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // #43: Ember Tavern Shop
            const Text(
              'Ember Tavern Shop 🏪',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _tavernShopCard(
                    icon: '🌹',
                    title: 'Standout Rose',
                    cost: 40,
                    desc: '2x Match Chance',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tavernShopCard(
                    icon: '⚡',
                    title: '1h Spotlight',
                    cost: 60,
                    desc: '5x Profile Views',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tavernShopCard(
                    icon: '🛡️',
                    title: 'Streak Freeze',
                    cost: 35,
                    desc: 'Protect 7D Streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // #42: Interest Guilds / Adventurer Clubs
            const Text(
              'Adventurer Interest Guilds 🛡️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              {
                'name': '🏔️ SF Summit Hikers',
                'members': '412 Adventurers • Weekend Trail Quests',
              },
              {
                'name': '🕹️ Co-Op Arcade Guild',
                'members': '628 Adventurers • Friday Boss Battles',
              },
              {
                'name': '☕ Espresso Alchemists',
                'members': '519 Adventurers • Third-Wave Cafe Crawls',
              },
              {
                'name': '🎨 Indie Gallery Hoppers',
                'members': '284 Adventurers • First Thursday Art Walks',
              },
            ].map((g) {
              final gName = g['name']!;
              final joined = _joinedGuilds.contains(gName);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: joined ? AppTheme.neonCyan : Colors.white10,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            g['members']!,
                            style: const TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: joined
                            ? AppTheme.neonCyan.withValues(alpha: 0.15)
                            : Colors.transparent,
                        foregroundColor:
                            joined ? AppTheme.neonCyan : Colors.white70,
                        side: BorderSide(
                          color: joined ? AppTheme.neonCyan : Colors.white24,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (joined) {
                            _joinedGuilds.remove(gName);
                          } else {
                            _joinedGuilds.add(gName);
                          }
                        });
                      },
                      child: Text(
                        joined ? 'Joined ✓' : 'Join Guild',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // #41: RPG Class Evolution & Subclass Skill Tree
            const Text(
              'RPG Class Evolution Tree (Lv. 5 Perks) ✨',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              '🌌 Astral Navigator (+15% Chemistry Boost)',
              '⚡ Cyber Tactician (+20% Quest Embers)',
              '🎵 Harmonic Bard (1 Free Super-Spark / Day)',
            ].map((sub) {
              final active = _selectedSubclass == sub;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSubclass = sub);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ Equipped Subclass Perk: $sub'),
                      backgroundColor: AppTheme.electricViolet,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppTheme.questGold : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sub,
                          style: TextStyle(
                            color: active ? AppTheme.questGold : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (active)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.questGold,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  Widget _tavernShopCard({
    required String icon,
    required String title,
    required int cost,
    required String desc,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onClaimEmber(-cost);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🏪 Purchased $title ($icon) from the Ember Tavern! (-$cost🔥)',
            ),
            backgroundColor: AppTheme.questGold,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.questGold.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.questGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$cost🔥',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementBadge({
    required String icon,
    required String title,
    required bool unlocked,
  }) {
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: unlocked ? AppTheme.bgCard : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppTheme.questGold.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unlocked ? icon : '🔒',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
              color: unlocked ? Colors.white : AppTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardRow({
    required int rank,
    required String name,
    required int xp,
    required String avatar,
    required bool isMe,
  }) {
    final badgeColor = rank == 1
        ? AppTheme.questGold
        : (rank == 2
              ? AppTheme.neonCyan
              : (rank == 3 ? AppTheme.sparkCoral : AppTheme.textSecondary));
    return Row(
      children: [
        Container(
          width: 24,
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 16,
          backgroundImage: AssetImage(avatar),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: isMe ? AppTheme.neonCyan : Colors.white,
              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.neonCyan.withValues(alpha: 0.15)
                : AppTheme.bgInput,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$xp XP ⭐',
            style: TextStyle(
              color: isMe ? AppTheme.neonCyan : AppTheme.questGold,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: AppTheme.bgInput,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(val * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
