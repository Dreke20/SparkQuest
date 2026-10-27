import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/quest.dart';
import '../theme/app_theme.dart';

class QuestsScreen extends StatefulWidget {
  final int streakDays;
  final VoidCallback onClaimEmber;

  const QuestsScreen({
    super.key,
    required this.streakDays,
    required this.onClaimEmber,
  });

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  final List<QuestItem> _quests = QuestItem.initialQuests;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _claim(QuestItem quest) {
    if (quest.isClaimed || !quest.isCompleted) return;
    setState(() => quest.isClaimed = true);
    widget.onClaimEmber();
    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed +${quest.reward} Embers! 🎁'),
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
          colors: const [AppTheme.questGold, AppTheme.sparkCoral, AppTheme.neonCyan],
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Streak Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.questGold.withOpacity(0.2),
                    AppTheme.sparkCoral.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.questGold.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.streakDays}-Day Spark Streak',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '1.25x Ember Multiplier Active',
                          style: TextStyle(fontSize: 12, color: AppTheme.questGold, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.questGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Claimed', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Resets in 6h 42m',
                  style: TextStyle(fontSize: 12, color: AppTheme.textDim),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quests List
            ..._quests.map((q) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: q.isCompleted && !q.isClaimed ? AppTheme.emeraldGreen : Colors.white10,
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
                        Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (q.current / q.target).clamp(0.0, 1.0),
                            backgroundColor: AppTheme.bgInput,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              q.isCompleted ? AppTheme.emeraldGreen : AppTheme.neonCyan,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${q.current} / ${q.target}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (q.isClaimed)
                    const Text('Done ✓', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold))
                  else if (q.isCompleted)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _claim(q),
                      child: Text('+${q.reward}🔥', style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgInput,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('+${q.reward}🔥', style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                    ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            // RPG Stats Radar Header
            const Text(
              'Explorer Attributes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          ],
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
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
          Text('${(val * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
