import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/realtime_chat_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String matchName;
  final String photoAsset;
  final bool isVoiceOnly;
  final VoidCallback onOpenDateShield;

  const VideoCallScreen({
    super.key,
    required this.matchName,
    required this.photoAsset,
    this.isVoiceOnly = false,
    required this.onOpenDateShield,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isCamOff = false;
  bool _isMysteryBlurActive = true;
  int _promptIndex = 0;

  final List<String> _aiCallPrompts = [
    '💡 Sparky Tip: Ask about the story behind their favorite travel photo ✈️',
    '💡 Sparky Tip: Play a quick 3-second rapid-fire "Coffee or Matcha?" round ☕',
    '💡 Sparky Tip: Ask what their ultimate Sunday morning looks like 🌅',
    '💡 Sparky Tip: Plan your Safe Haven coffee check-in for 15% off 🛡️',
  ];

  @override
  void initState() {
    super.initState();
    _isCamOff = widget.isVoiceOnly;
    RealtimeChatService.instance.addListener(_onSignalChanged);
    RealtimeChatService.instance.initiateCallSignal(
      matchName: widget.matchName,
      matchAvatar: widget.photoAsset,
      isVoiceOnly: widget.isVoiceOnly,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
          if (_seconds == 8 && _isMysteryBlurActive) {
            // Auto-reduce blur after warm-up if video call
            _isMysteryBlurActive = false;
          }
        });
      }
    });
  }

  void _onSignalChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    RealtimeChatService.instance.removeListener(_onSignalChanged);
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Match Video Stream Simulation
          Image.asset(
            widget.photoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppTheme.bgDeep),
          ),

          // Mystery Comfort Blur Filter or Voice Mode Backdrop
          if (_isMysteryBlurActive || widget.isVoiceOnly)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.isVoiceOnly ? 26.0 : 14.0,
                sigmaY: widget.isVoiceOnly ? 26.0 : 14.0,
              ),
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

          // Center Avatar if Voice Call or Mystery Blur
          if (widget.isVoiceOnly || _isMysteryBlurActive)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.neonCyan, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: AssetImage(widget.photoAsset),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.matchName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.electricViolet.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      widget.isVoiceOnly
                          ? '🎙️ Crystal Voice Spark Call Active'
                          : '🔮 Comfort Blur Active • Tap Unblur below when ready',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Top HUD Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: RealtimeChatService.instance.callSignalState == 'ringing'
                                    ? AppTheme.questGold
                                    : AppTheme.emeraldGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              RealtimeChatService.instance.callSignalState == 'ringing'
                                  ? 'Ringing ${widget.matchName} (Realtime)...'
                                  : '${widget.matchName} • $_formattedTime',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (!widget.isVoiceOnly)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.65),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(
                                  () => _isMysteryBlurActive =
                                      !_isMysteryBlurActive,
                                );
                              },
                              icon: Icon(
                                _isMysteryBlurActive
                                    ? Icons.visibility
                                    : Icons.blur_on,
                                color: AppTheme.neonCyan,
                                size: 16,
                              ),
                              label: Text(
                                _isMysteryBlurActive ? 'Unblur HD' : 'Blur',
                                style: const TextStyle(
                                  color: AppTheme.neonCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.65),
                            ),
                            icon: const Icon(
                              Icons.shield,
                              color: AppTheme.neonCyan,
                              size: 20,
                            ),
                            tooltip: 'Date Shield Safety',
                            onPressed: widget.onOpenDateShield,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sparky AI Live Wingman Prompt Banner
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _promptIndex =
                            (_promptIndex + 1) % _aiCallPrompts.length;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.questGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _aiCallPrompts[_promptIndex],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.refresh,
                            color: AppTheme.questGold,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Self PIP Preview (Bottom Right above controls)
          if (!_isCamOff)
            Positioned(
              right: 18,
              bottom: 118,
              child: Container(
                width: 96,
                height: 136,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/alex.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.person, color: Colors.white54),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Call Controls Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _callControlBtn(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Muted' : 'Mute',
                      active: _isMuted,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isMuted = !_isMuted);
                      },
                    ),
                    _callControlBtn(
                      icon: _isCamOff ? Icons.videocam_off : Icons.videocam,
                      label: _isCamOff ? 'Cam Off' : 'Video',
                      active: _isCamOff,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isCamOff = !_isCamOff);
                      },
                    ),
                    _callControlBtn(
                      icon: Icons.auto_awesome,
                      label: 'Next Tip',
                      active: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _promptIndex =
                              (_promptIndex + 1) % _aiCallPrompts.length;
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        RealtimeChatService.instance.endCallSignal();
                        Navigator.pop(context, _seconds);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sparkCoral,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.sparkCoral.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _callControlBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? AppTheme.electricViolet : AppTheme.bgCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppTheme.neonCyan : Colors.white12,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Phase 5: Incoming Call Signaling Dialog over Supabase Realtime
class IncomingCallDialog extends StatelessWidget {
  final String roomId;
  final String callerName;
  final String callerAvatar;
  final bool isVoiceOnly;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallDialog({
    super.key,
    required this.roomId,
    required this.callerName,
    required this.callerAvatar,
    this.isVoiceOnly = false,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isVoiceOnly
                    ? '🎙️ INCOMING VOICE SPARK (REALTIME)'
                    : '📹 INCOMING VIDEO SPARK (REALTIME)',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.electricViolet, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricViolet.withValues(alpha: 0.45),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 44,
                backgroundImage: callerAvatar.startsWith('http')
                    ? NetworkImage(callerAvatar) as ImageProvider
                    : AssetImage(callerAvatar),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Comfort Blur will start enabled for your safety 🛡️',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sparkCoral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    SupabaseService.instance.updateCallSignalStatus(
                      roomId: roomId,
                      status: 'declined',
                    );
                    Navigator.pop(context);
                    onDecline();
                  },
                  icon: const Icon(Icons.call_end, size: 18),
                  label: const Text('Decline'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    SupabaseService.instance.updateCallSignalStatus(
                      roomId: roomId,
                      status: 'accepted',
                    );
                    Navigator.pop(context);
                    onAccept();
                  },
                  icon: Icon(
                    isVoiceOnly ? Icons.phone_in_talk : Icons.videocam,
                    size: 18,
                  ),
                  label: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


