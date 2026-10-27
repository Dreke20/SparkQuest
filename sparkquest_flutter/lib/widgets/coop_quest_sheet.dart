import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

class CoopQuestSheet extends StatefulWidget {
  final String matchName;
  final Function(int embers) onCompleted;
  const CoopQuestSheet({
    super.key,
    required this.matchName,
    required this.onCompleted,
  });

  @override
  State<CoopQuestSheet> createState() => _CoopQuestSheetState();
}

class _CoopQuestSheetState extends State<CoopQuestSheet> {
  late ConfettiController _confettiController;
  int _progress = 50;
  bool _isClaimed = false;

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

  void _progressQuest() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_progress < 100) {
        _progress = (_progress + 25).clamp(0, 100);
      }
    });

    if (_progress == 100 && !_isClaimed) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
      widget.onCompleted(300);
      setState(() => _isClaimed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF13182C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('🤝', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Co-Op Match Quest',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Partner: ${widget.matchName}',
                            style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quest Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      const Color(0xFFEC4899).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '☕ Neon Espresso Expedition',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+300 ✦',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Both visit Neon Roasters and order the secret quest drink within 48 hours.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    // Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shared Synergy Progress', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('$_progress / 100%', style: const TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _progress / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                      borderRadius: BorderRadius.circular(6),
                      minHeight: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action button
              if (_isClaimed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text(
                        'Quest Completed! Badge: ☕ Double Shot Duo',
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _progressQuest,
                  child: Text(
                    _progress < 100 ? '📍 Simulate Check-in Step (+25%)' : '🎉 Claim 300 Embers',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
              Color(0xFF10B981),
            ],
          ),
        ],
      ),
    );
  }
}
