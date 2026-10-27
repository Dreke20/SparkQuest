import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../services/supabase_service.dart';

class AuthDialog extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthDialog({super.key, required this.onAuthenticated});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  final TextEditingController _phoneController = TextEditingController(text: '+1 (555) 839-2049');
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _sendPhoneCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await SupabaseService.instance.sendPhoneOtp(phone);

    setState(() {
      _isLoading = false;
      _isCodeSent = true;
      _resendCountdown = 30;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length < 4) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final res = await SupabaseService.instance.verifyPhoneOtp(_phoneController.text, code);
    setState(() => _isLoading = false);

    if (res != null) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
      widget.onAuthenticated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Verified! Welcome to SparkQuest Cloud.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _signInWithGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final res = await SupabaseService.instance.signInWithGoogleToken('google_mock_id_token_2026');
    setState(() => _isLoading = false);

    if (res != null) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
      widget.onAuthenticated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Google Sign-In successful! Welcome back.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF13182C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
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
                          Text('🔥', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 8),
                          Text(
                            'Supabase Auth',
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
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to sync your profile, matches & quests across devices.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF06B6D4),
                      labelColor: const Color(0xFF06B6D4),
                      unselectedLabelColor: Colors.white54,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: '📱 Phone SMS'),
                        Tab(text: '🌐 Google'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    height: 240,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Phone SMS
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_isCodeSent) ...[
                              const Text('Enter Mobile Number', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF06B6D4)),
                                  hintText: '+1 (555) 000-0000',
                                  hintStyle: const TextStyle(color: Colors.white30),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF06B6D4),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _sendPhoneCode,
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Send 6-Digit Code 💬', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ] else ...[
                              Text('Code sent to ${_phoneController.text}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                                maxLength: 6,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  counterText: '',
                                  hintText: '• • • • • •',
                                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _verifyCode,
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Verify & Enter App 🚀', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Tap to resend code',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Tab 2: Google Sign-In
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                              label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: _isLoading ? null : _signInWithGoogle,
                            ),
                            const SizedBox(height: 14),
                            const Center(
                              child: Text(
                                'Secure Single Sign-On powered by Supabase Auth',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF06B6D4),
              Color(0xFF8B5CF6),
              Color(0xFF10B981),
            ],
          ),
        ],
      ),
    );
  }
}
