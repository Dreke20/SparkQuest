import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class DailySpinWheelDialog extends StatefulWidget {
  final Function(int) onAwardEmbers;

  const DailySpinWheelDialog({super.key, required this.onAwardEmbers});

  @override
  State<DailySpinWheelDialog> createState() => _DailySpinWheelDialogState();
}

class _DailySpinWheelDialogState extends State<DailySpinWheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ConfettiController _confettiController;
  bool _isSpinning = false;
  bool _hasSpunToday = false;
  double _currentAngle = 0;
  String _resultText = 'Spin the wheel for free daily Embers & perks!';

  final List<Map<String, dynamic>> _slices = [
    {'label': '✦ 50', 'icon': '✦', 'color': Color(0xFF1E293B), 'reward': 50},
    {
      'label': '🔥 Boost',
      'icon': '🔥',
      'color': AppTheme.sparkCoral,
      'reward': 75,
    },
    {
      'label': '💎 150',
      'icon': '💎',
      'color': AppTheme.neonCyan,
      'reward': 150,
    },
    {
      'label': '⭐ 2x Super',
      'icon': '⭐',
      'color': AppTheme.questGold,
      'reward': 100,
    },
    {
      'label': '🛡️ Shield',
      'icon': '🛡️',
      'color': AppTheme.electricViolet,
      'reward': 80,
    },
    {
      'label': '✦ 100',
      'icon': '✦',
      'color': AppTheme.emeraldGreen,
      'reward': 100,
    },
    {
      'label': '🎁 2x Day',
      'icon': '🎁',
      'color': Color(0xFFE11D48),
      'reward': 120,
    },
    {
      'label': '👑 Crown',
      'icon': '👑',
      'color': Color(0xFFF59E0B),
      'reward': 200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _hasSpunToday = StorageService.instance.hasUsedFreeDailySpinToday();
    if (_hasSpunToday) {
      _resultText = 'Daily free spin claimed! VIP Bonus Spin unlocked ✨';
    }
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _resultText = 'Spinning for destiny... 🎡';
    });

    final targetIndex = Random().nextInt(_slices.length);
    final sliceAngle = (2 * pi) / _slices.length;
    // Pointer is at the top (angle 3*pi/2 or -pi/2)
    final targetOffset =
        (3 * pi / 2) - (targetIndex * sliceAngle + sliceAngle / 2);
    final extraSpins = (5 + Random().nextInt(3)) * 2 * pi;
    final endAngle =
        _currentAngle +
        extraSpins +
        (targetOffset - (_currentAngle % (2 * pi)));

    final startAngle = _currentAngle;

    _animation =
        Tween<double>(begin: startAngle, end: endAngle).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {
            _currentAngle = _animation.value;
          });
        });

    _controller.forward(from: 0).then((_) {
      final winningSlice = _slices[targetIndex];
      final reward = winningSlice['reward'] as int;

      widget.onAwardEmbers(reward);
      StorageService.instance.markFreeDailySpinUsedToday();
      _confettiController.play();

      setState(() {
        _isSpinning = false;
        _hasSpunToday = true;
        _resultText = '🎉 You won ${winningSlice['label']}! (+$reward Embers)';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
            colors: const [
              AppTheme.questGold,
              AppTheme.sparkCoral,
              AppTheme.neonCyan,
            ],
          ),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
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
                    const Row(
                      children: [
                        Text('🎡 ', style: TextStyle(fontSize: 22)),
                        Text(
                          'DAILY FORTUNE WHEEL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textDim),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _resultText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _isSpinning ? AppTheme.neonCyan : AppTheme.questGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Wheel Container with Pointer
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pointer at Top
                      Positioned(
                        top: 0,
                        child: CustomPaint(
                          size: const Size(20, 20),
                          painter: _PointerPainter(),
                        ),
                      ),
                      // Rotating Wheel Canvas
                      Transform.rotate(
                        angle: _currentAngle,
                        child: CustomPaint(
                          size: const Size(240, 240),
                          painter: _WheelPainter(slices: _slices),
                        ),
                      ),
                      // Center Cap
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.bgDeep,
                          border: Border.all(
                            color: AppTheme.neonCyan,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '✦',
                            style: TextStyle(
                              color: AppTheme.questGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Spin Button
                ElevatedButton(
                  onPressed: _isSpinning ? null : _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sparkCoral,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isSpinning
                        ? 'SPINNING...'
                        : (_hasSpunToday
                              ? 'VIP BONUS SPIN 🎯'
                              : 'SPIN FOR FREE 🎯'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1,
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
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.sparkCoral
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;

  _WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final sliceAngle = (2 * pi) / slices.length;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final startAngle = i * sliceAngle;

      final paint = Paint()
        ..color = slice['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..color = AppTheme.bgSurface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // Draw label
      final textAngle = startAngle + sliceAngle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final textSpan = TextSpan(
        text: slice['label'] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius - 55, -textPainter.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
