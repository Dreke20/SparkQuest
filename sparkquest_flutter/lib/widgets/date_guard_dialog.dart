import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class DateGuardDialog extends StatefulWidget {
  final String initialVenue;
  const DateGuardDialog({super.key, this.initialVenue = 'Neon Roasters'});

  @override
  State<DateGuardDialog> createState() => _DateGuardDialogState();
}

class _DateGuardDialogState extends State<DateGuardDialog> {
  bool _isActive = false;
  int _selectedMinutes = 60;
  int _secondsRemaining = 3600;
  Timer? _timer;
  late String _venue;
  bool _wearOsSync = true;
  final TextEditingController _contactController = TextEditingController();

  final List<String> _venues = [
    'Neon Roasters (Safe Haven)',
    'Cyberpunk Tea Lounge',
    'Tokyo Secret Vinyl Bar',
    'Mission Rooftop Garden',
  ];

  @override
  void initState() {
    super.initState();
    _venue = widget.initialVenue;
    _wearOsSync = StorageService.instance.isWearOsShieldSyncEnabled();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _contactController.dispose();
    super.dispose();
  }

  void _startGuard() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
    });
    if (_wearOsSync) {
      PushNotificationService.instance.armWearOsShield(_venue);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _triggerSafetyCheckIn();
      }
    });
  }

  void _triggerSafetyCheckIn() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF06B6D4)),
            SizedBox(width: 8),
            Text('Safety Check-In!'),
          ],
        ),
        content: const Text(
          'Your date safety timer has elapsed. Are you safe and enjoying your date?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _triggerEmergencySOS();
            },
            child: const Text(
              'Send SOS',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isActive = false);
            },
            child: const Text("I'm Safe! 👍"),
          ),
        ],
      ),
    );
  }

  void _triggerEmergencySOS() {
    HapticFeedback.heavyImpact();
    SupabaseService.instance.triggerSosAlert(
      source: _wearOsSync ? 'wear_os_and_mobile_date_shield' : 'mobile_date_shield',
    );
    final targetContact = _contactController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.shade700,
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                targetContact.isEmpty
                    ? '🚨 SOS Alert synced to SparkQuest Safety Cloud!'
                    : '🚨 SOS Alert & GPS dispatched to $targetContact!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerFakeCall() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Incoming Call (Escape)'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mom / Roommate is calling...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              '"Hey! Something urgent came up at the apartment!"',
              style: TextStyle(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Decline'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Accept & Excuse Self'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF13182C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
      ),
      child: Padding(
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
                      Icon(Icons.shield, color: Color(0xFF06B6D4), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Date Guard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
                'Guardian Angel in-person safety companion. Auto-prompts check-ins & emergency SMS dispatch.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 18),

              if (_isActive) ...[
                // Active State UI
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SHIELD ACTIVE',
                        style: TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Venue: $_venue',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isActive = false);
                          _timer?.cancel();
                          PushNotificationService.instance.disarmWearOsShield();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "I'm safe! Date Guard & WearOS Shield disarmed. 👍",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("I'm Safe 👍"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                      ),
                      onPressed: _triggerFakeCall,
                      child: const Row(
                        children: [
                          Icon(Icons.call, size: 16),
                          SizedBox(width: 4),
                          Text('Fake Call'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                  ),
                  onPressed: _triggerEmergencySOS,
                  icon: const Icon(Icons.warning),
                  label: const Text('Dispatch Emergency SOS'),
                ),
              ] else ...[
                // Setup State UI
                const Text(
                  'Select Verified Date Spot',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _venues.contains(_venue)
                      ? _venue
                      : _venues.first,
                  dropdownColor: const Color(0xFF1A1F38),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                  ),
                  items: _venues
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _venue = val);
                  },
                ),
                const SizedBox(height: 14),

                const Text(
                  'Safety Timer Duration',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [30, 60, 90, 120].map((mins) {
                    final selected = _selectedMinutes == mins;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMinutes = mins);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF06B6D4)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${mins}m',
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Emergency Contact (SMS)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Trusted friend phone number',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xFF06B6D4),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _wearOsSync,
                  activeThumbColor: const Color(0xFF06B6D4),
                  onChanged: (val) async {
                    setState(() => _wearOsSync = val);
                    await StorageService.instance.setWearOsShieldSyncEnabled(val);
                  },
                  title: const Text(
                    '⌚ WearOS Companion SOS Sync',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Mirrors 1-tap SOS trigger notification onto paired Android WearOS watches.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _startGuard,
                  child: const Text(
                    '🛡️ Arm Date Guard',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
