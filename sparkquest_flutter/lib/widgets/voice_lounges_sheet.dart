import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';

class VoiceLoungesSheet extends StatefulWidget {
  final VoidCallback? onLoungeJoined;

  const VoiceLoungesSheet({super.key, this.onLoungeJoined});

  @override
  State<VoiceLoungesSheet> createState() => _VoiceLoungesSheetState();
}

class _VoiceLoungesSheetState extends State<VoiceLoungesSheet> {
  List<Map<String, dynamic>> _lounges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLounges();
  }

  Future<void> _loadLounges() async {
    final lounges = await SupabaseService.instance.fetchVoiceLounges();
    if (mounted) {
      setState(() {
        _lounges = lounges;
        _isLoading = false;
      });
    }
  }

  void _openLoungeRoom(Map<String, dynamic> lounge) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context); // Close sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceLoungeRoomModal(lounge: lounge),
    );
  }

  void _showCreateLoungeDialog() {
    final titleController = TextEditingController();
    final topicController = TextEditingController();
    String selectedVibe = '☕ Cozy Artisan';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppTheme.neonCyan, width: 1.2),
          ),
          title: const Row(
            children: [
              Text('🎙️ ', style: TextStyle(fontSize: 20)),
              Text(
                'Host a Voice Lounge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Open a drop-in audio room for fellow explorers in your neighborhood. Earn +50 Embers when 3 members join!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Lounge Title',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g. Sunset Matcha & Travel Stories',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: topicController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Discussion Topic / Hook',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g. Best pour-over spots in the Mission',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedVibe,
                dropdownColor: AppTheme.bgCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Vibe Archetype',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  '☕ Cozy Artisan',
                  '🌌 Night Owl',
                  '🏔️ Adventurer',
                  '🎵 Indie Curator',
                ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedVibe = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sparkCoral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final newLounge = {
                  'id': 'lounge_${DateTime.now().millisecondsSinceEpoch}',
                  'title': titleController.text.trim(),
                  'topic': topicController.text.trim().isEmpty
                      ? 'Casual coffee chat'
                      : topicController.text.trim(),
                  'vibe': selectedVibe,
                  'host_id': 'user_me',
                  'host_name': StorageService.instance.getUserName().isEmpty
                      ? 'You'
                      : StorageService.instance.getUserName(),
                  'max_listeners': 15,
                  'active_count': 1,
                };
                setState(() => _lounges.insert(0, newLounge));
                _openLoungeRoom(newLounge);
              },
              child: const Text('Go Live 🎙️', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🎙️ ', style: TextStyle(fontSize: 20)),
                      Text(
                        'Drop-In Voice Lounges',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Casual, low-pressure audio rooms • Talk before formal dates',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showCreateLoungeDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Host', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lounges List
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
          else if (_lounges.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('No active lounges right now. Be the first to host one!'),
            )
          else
            ..._lounges.map((lounge) {
              final title = lounge['title'] ?? 'Voice Hangout';
              final topic = lounge['topic'] ?? '';
              final vibe = lounge['vibe'] ?? 'Indie Vibe';
              final host = lounge['host_name'] ?? 'Adventurer';
              final activeCount = lounge['active_count'] ?? 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            vibe,
                            style: const TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$activeCount listening',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (topic.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        topic,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hosted by $host',
                          style: const TextStyle(
                            color: AppTheme.questGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sparkCoral,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => _openLoungeRoom(lounge),
                          child: const Text(
                            'Join Room 🎧',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Interactive Live Voice Lounge Room Modal
class VoiceLoungeRoomModal extends StatefulWidget {
  final Map<String, dynamic> lounge;

  const VoiceLoungeRoomModal({super.key, required this.lounge});

  @override
  State<VoiceLoungeRoomModal> createState() => _VoiceLoungeRoomModalState();
}

class _VoiceLoungeRoomModalState extends State<VoiceLoungeRoomModal>
    with SingleTickerProviderStateMixin {
  bool _isMuted = true;
  bool _handRaised = false;
  late AnimationController _pulseController;
  Timer? _speakerSimulationTimer;
  int _activeSpeakerIndex = 0;

  final List<Map<String, dynamic>> _speakers = [
    {
      'name': 'Maya',
      'role': 'Host 👑',
      'avatar': 'assets/images/maya.png',
      'isSpeaking': true,
    },
    {
      'name': 'Alex',
      'role': 'Speaker',
      'avatar': 'assets/images/alex.png',
      'isSpeaking': false,
    },
    {
      'name': 'Jordan',
      'role': 'Listener',
      'avatar': 'assets/images/jordan.png',
      'isSpeaking': false,
    },
    {
      'name': 'Sophia',
      'role': 'Listener',
      'avatar': 'assets/images/sophia.png',
      'isSpeaking': false,
    },
    {
      'name': 'You',
      'role': 'Adventurer',
      'avatar': 'assets/images/logo.jpg',
      'isSpeaking': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Simulate ambient speaking turns for immersive demo
    _speakerSimulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _activeSpeakerIndex = (_activeSpeakerIndex + 1) % 2;
          for (int i = 0; i < _speakers.length; i++) {
            _speakers[i]['isSpeaking'] = (i == _activeSpeakerIndex);
          }
        });
      }
    });

    SupabaseService.instance.joinVoiceLounge(
      loungeId: widget.lounge['id'] ?? 'lounge_default',
      userId: 'user_me',
      userName: StorageService.instance.getUserName().isEmpty
          ? 'You'
          : StorageService.instance.getUserName(),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speakerSimulationTimer?.cancel();
    SupabaseService.instance.leaveVoiceLounge(
      widget.lounge['id'] ?? 'lounge_default',
      'user_me',
    );
    super.dispose();
  }

  void _sendReaction(String emoji) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji reaction sent to lounge!'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.bgCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Notch & Title
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lounge['title'] ?? 'Live Audio Room',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.lounge['topic'] ?? 'Real-time Voice Date',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Participants Grid with Speaking Halo
          Expanded(
            child: GridView.builder(
              itemCount: _speakers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final s = _speakers[index];
                final isSpeaking = s['isSpeaking'] == true;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSpeaking
                                  ? AppTheme.neonCyan.withValues(
                                      alpha: 0.4 + (_pulseController.value * 0.6),
                                    )
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSpeaking
                                ? [
                                    BoxShadow(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: 0.3 * _pulseController.value,
                                      ),
                                      blurRadius: 14,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundImage: AssetImage(s['avatar']),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: s['role'].contains('Host')
                            ? AppTheme.questGold.withValues(alpha: 0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s['role'],
                        style: TextStyle(
                          color: s['role'].contains('Host')
                              ? AppTheme.questGold
                              : AppTheme.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Floating Reaction Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['🔥', '☕', '✨', '💖', '👋'].map((emoji) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: () => _sendReaction(emoji),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Bottom Action Bar (Mic, Hand, Leave)
          Row(
            children: [
              // Mute / Unmute
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMuted ? AppTheme.bgCard : AppTheme.neonCyan,
                    foregroundColor: _isMuted ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: _isMuted ? Colors.white24 : AppTheme.neonCyan,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _isMuted = !_isMuted;
                      _speakers.last['isSpeaking'] = !_isMuted;
                    });
                  },
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, size: 20),
                  label: Text(
                    _isMuted ? 'Muted' : 'Mic Active',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Raise Hand
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _handRaised ? AppTheme.questGold : AppTheme.bgCard,
                  foregroundColor: _handRaised ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: BorderSide(
                    color: _handRaised ? AppTheme.questGold : Colors.white24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _handRaised = !_handRaised);
                },
                child: Text(_handRaised ? '✋ Raised' : '✋ Hand'),
              ),
              const SizedBox(width: 10),

              // Leave Quietly
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkCoral.withValues(alpha: 0.2),
                  foregroundColor: AppTheme.sparkCoral,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: AppTheme.sparkCoral),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: const Text('✌️ Leave', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

