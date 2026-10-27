import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

class LivenessVerificationDialog extends StatefulWidget {
  final VoidCallback onVerified;
  const LivenessVerificationDialog({super.key, required this.onVerified});

  @override
  State<LivenessVerificationDialog> createState() =>
      _LivenessVerificationDialogState();
}

class _LivenessVerificationDialogState
    extends State<LivenessVerificationDialog> {
  late ConfettiController _confettiController;
  int _step = 0;
  bool _isComplete = false;
  Timer? _stepTimer;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Position Face in Oval',
      'desc': 'Hold camera at eye level and align your face',
      'icon': '👤',
    },
    {
      'title': 'Tilt Head Slightly Left',
      'desc': 'Proving you are a living 3D human',
      'icon': '↪️',
    },
    {
      'title': 'Smile Warmly!',
      'desc': 'Looking great! Capturing biometric liveness',
      'icon': '😊',
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _startStepSequence();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startStepSequence() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (!mounted) return;
      if (_step < _steps.length - 1) {
        HapticFeedback.lightImpact();
        setState(() {
          _step++;
        });
      } else {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _confettiController.play();
        setState(() {
          _isComplete = true;
        });
        widget.onVerified();
      }
    });
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
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFF06B6D4), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Selfie Verification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Camera Simulation Viewport
                Container(
                  width: 200,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _isComplete
                          ? const Color(0xFF10B981)
                          : const Color(0xFF06B6D4),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isComplete
                                ? const Color(0xFF10B981)
                                : const Color(0xFF06B6D4))
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isComplete
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🔥', style: TextStyle(fontSize: 60)),
                              SizedBox(height: 8),
                              Text(
                                'VERIFIED!',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _steps[_step]['icon']!,
                                style: const TextStyle(fontSize: 54),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Step ${_step + 1} of 3',
                                style: const TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                // Step Instructions
                if (!_isComplete) ...[
                  Text(
                    _steps[_step]['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[_step]['desc']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_step + 1) / _steps.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF06B6D4),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ] else ...[
                  const Text(
                    'Blue Flame Verified Badge Unlocked!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '+50 Embers credited • Your profile will receive 2x more visibility!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Awesome! ✨',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF06B6D4),
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
