import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/profile.dart';
import '../theme/app_theme.dart';

class MysteryBlindMatchDialog extends StatefulWidget {
  final Function(int) onAwardEmbers;
  final VoidCallback onOpenChat;

  const MysteryBlindMatchDialog({
    super.key,
    required this.onAwardEmbers,
    required this.onOpenChat,
  });

  @override
  State<MysteryBlindMatchDialog> createState() => _MysteryBlindMatchDialogState();
}

class _MysteryBlindMatchDialogState extends State<MysteryBlindMatchDialog> {
  int _step = 0;
  int _score = 0;
  double _blurSigma = 24.0;
  bool _revealed = false;
  late Profile _mysteryProfile;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _questions = [
    {
      'q': 'Friday 11:00 PM plan?',
      'optA': '🌮 Midnight taco run & city drive',
      'optB': '🛋️ Blanket cocoon & cozy anime',
      'matchPick': 'A',
    },
    {
      'q': 'First date venue vibe?',
      'optA': '🍸 Hidden jazz speakeasy',
      'optB': '🕹️ Retro arcade & air hockey',
      'matchPick': 'B',
    },
    {
      'q': 'Dream weekend escape?',
      'optA': '🌲 Forest cabin & stargazing',
      'optB': '🏖️ Sun-drenched beach & surfing',
      'matchPick': 'A',
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _mysteryProfile = Profile.seedProfiles.first; // Sophia
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _choose(String choice) {
    final cur = _questions[_step];
    final isMatch = (choice == cur['matchPick']);
    if (isMatch) _score += 33;

    setState(() {
      _blurSigma = (_step == 0) ? 14.0 : ((_step == 1) ? 6.0 : 0.0);
    });

    if (_step < _questions.length - 1) {
      setState(() => _step++);
    } else {
      // Completed! Reveal match
      setState(() {
        _revealed = true;
        _blurSigma = 0.0;
      });
      widget.onAwardEmbers(30);
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = _questions[_step];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppTheme.questGold, AppTheme.sparkCoral, AppTheme.neonCyan],
          ),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.electricViolet.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricViolet.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.electricViolet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.electricViolet.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Text('🔮 ', style: TextStyle(fontSize: 14)),
                          Text(
                            'MYSTERY BLIND MATCH',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textDim),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 14),

                // Mystery Blurred Avatar
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _revealed ? AppTheme.neonCyan : AppTheme.electricViolet, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (_revealed ? AppTheme.neonCyan : AppTheme.electricViolet).withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
                          child: Image.asset(
                            _mysteryProfile.photoAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (!_revealed)
                          const Center(
                            child: Text('🎭', style: TextStyle(fontSize: 42)),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (!_revealed) ...[
                  Text(
                    'Question ${_step + 1} of 3',
                    style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cur['q'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _choose('A'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bgCard,
                      foregroundColor: AppTheme.textPrimary,
                      minimumSize: const Size(double.infinity, 44),
                      side: BorderSide(color: AppTheme.neonCyan.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(cur['optA'] as String, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _choose('B'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bgCard,
                      foregroundColor: AppTheme.textPrimary,
                      minimumSize: const Size(double.infinity, 44),
                      side: BorderSide(color: AppTheme.sparkCoral.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(cur['optB'] as String, style: const TextStyle(fontSize: 13)),
                  ),
                ] else ...[
                  Text(
                    '${_mysteryProfile.name}, ${_mysteryProfile.age}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_mysteryProfile.occupation} • ${(_score > 0 ? _score : _mysteryProfile.compatPct)}% Chemistry!',
                    style: const TextStyle(fontSize: 13, color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🎉 Mutual resonance unlocked! You both chose spontaneous city escapades & hidden speakeasies.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('Start Chatting (💬)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sparkCoral,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onOpenChat();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
