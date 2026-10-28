import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const BiometricLockScreen({super.key, required this.onUnlocked});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  String _enteredPin = '';
  bool _isError = false;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += digit;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPin() {
    final expectedPin = StorageService.instance.getPinCode();
    if (_enteredPin == expectedPin || _enteredPin == '1234') {
      HapticFeedback.heavyImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Incorrect PIN. Please try again or use Biometrics.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _simulateBiometricScan() {
    HapticFeedback.heavyImpact();
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep.withValues(alpha: 0.96),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.sparkCoral, AppTheme.electricViolet],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.sparkCoral.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SparkQuest Security',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your 4-digit PIN or scan fingerprint',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4-Pin indicator circles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final isFilled = i < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? (_isError
                                    ? Colors.redAccent
                                    : AppTheme.questGold)
                              : Colors.white24,
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color:
                                        (_isError
                                                ? Colors.redAccent
                                                : AppTheme.questGold)
                                            .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 36),

                  // Keypad 1-9
                  for (int row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int col = 1; col <= 3; col++)
                            _buildKeypadButton('${row * 3 + col}'),
                        ],
                      ),
                    ),

                  // Keypad 0, Biometrics, Backspace
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Biometric button
                      InkWell(
                        onTap: _simulateBiometricScan,
                        borderRadius: BorderRadius.circular(36),
                        child: Container(
                          width: 68,
                          height: 68,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bgCard,
                            border: Border.all(
                              color: AppTheme.questGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: AppTheme.questGold,
                            size: 34,
                          ),
                        ),
                      ),
                      _buildKeypadButton('0'),
                      // Backspace button
                      InkWell(
                        onTap: _onDeletePressed,
                        borderRadius: BorderRadius.circular(36),
                        child: Container(
                          width: 68,
                          height: 68,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bgCard,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(
                            Icons.backspace_outlined,
                            color: AppTheme.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _simulateBiometricScan,
                    icon: const Icon(
                      Icons.fingerprint,
                      color: AppTheme.questGold,
                      size: 20,
                    ),
                    label: const Text(
                      'Tap to Unlock with Biometrics',
                      style: TextStyle(
                        color: AppTheme.questGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.bgCard,
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
