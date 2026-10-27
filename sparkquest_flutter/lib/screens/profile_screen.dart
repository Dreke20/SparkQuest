import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/spark_pass_dialog.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  final int embers;
  final VoidCallback onOpenDateShield;

  const ProfileScreen({
    super.key,
    required this.embers,
    required this.onOpenDateShield,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isVerified = false;
  bool _isRecordingVoice = false;
  bool _hasVoicePrompt = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  String _selectedFrame = 'cyber_cyan';
  bool _isGoldVip = false;

  final List<String?> _photos = [
    'assets/images/alex.png',
    null,
    null,
    null,
    null,
    null,
  ];

  @override
  void dispose() {
    _voiceTimer?.cancel();
    super.dispose();
  }

  void _triggerLivenessModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LivenessVerificationModal(
        onVerified: () {
          setState(() => _isVerified = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Face Verified! Anti-Catfish Shield Activated.'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        },
      ),
    );
  }

  void _toggleVoiceRecording() {
    if (_isRecordingVoice) {
      _voiceTimer?.cancel();
      setState(() {
        _isRecordingVoice = false;
        _hasVoicePrompt = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎙️ Voice Spark saved! "My secret, useless talent"'),
          backgroundColor: AppTheme.electricViolet,
        ),
      );
    } else {
      setState(() {
        _isRecordingVoice = true;
        _voiceSeconds = 0;
      });
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_voiceSeconds >= 15) {
          _toggleVoiceRecording();
        } else {
          setState(() => _voiceSeconds++);
        }
      });
    }
  }

  void _triggerFakeCall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🛡️ Date Shield Emergency Call'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A discreet escape call is scheduled.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your phone will ring with an automated "urgent family check-in" in 10 seconds. Answer to step away gracefully without awkwardness.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📞 Simulated rescue call incoming in 10s...'),
                  backgroundColor: AppTheme.sparkCoral,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sparkCoral),
            child: const Text('Start 10s Timer'),
          ),
        ],
      ),
    );
  }

  void _openCosmeticsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final frames = [
            {'id': 'cyber_cyan', 'name': '⚡ Cyberpunk Ring', 'color': AppTheme.neonCyan},
            {'id': 'phoenix_flame', 'name': '🔥 Phoenix Flame', 'color': AppTheme.sparkCoral},
            {'id': 'galactic_violet', 'name': '🌌 Galactic Aura', 'color': AppTheme.electricViolet},
            {'id': 'neon_crown', 'name': '👑 Neon Crown Legend', 'color': AppTheme.questGold},
          ];

          return Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '✨ Avatar Glowing Frames',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textDim),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select an animated frame for your profile and chat cards.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...frames.map((f) {
                  final isSelected = (_selectedFrame == f['id']);
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedFrame = f['id'] as String);
                      setModalState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Equipped ${f['name']}! ✨'),
                          backgroundColor: f['color'] as Color,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? (f['color'] as Color) : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: f['color'] as Color, width: 2),
                                ),
                                child: const Center(child: Text('👤', style: TextStyle(fontSize: 12))),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                f['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          Text(
                            isSelected ? 'EQUIPPED' : 'EQUIP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? (f['color'] as Color) : AppTheme.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openVIPModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('👑 SparkQuest Gold VIP', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.questGold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unlock exclusive explorer privileges:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _vipPerk('⏪', 'Unlimited Rewinds on passed cards'),
            _vipPerk('👁️', 'See who liked your profile instantly'),
            _vipPerk('✦', '2x Embers from all quests & drops'),
            _vipPerk('⚡', 'Weekly Spotlight Profile Boost'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: AppTheme.textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isGoldVip = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('👑 Welcome to SparkQuest Gold! Enjoy VIP perks.'),
                  backgroundColor: AppTheme.questGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.questGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Unlock Gold (500 ✦)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _vipPerk(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildUserHeroCard(),

          const SizedBox(height: 20),

          // Safety Shield Banner
          _buildDateShieldBanner(),

          const SizedBox(height: 16),

          // VIP Gold & Avatar Frames Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openCosmeticsModal,
                  icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.questGold),
                  label: const Text('Avatar Frames', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bgCard,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.questGold.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openVIPModal,
                  icon: const Icon(Icons.workspace_premium, size: 16, color: AppTheme.sparkCoral),
                  label: Text(_isGoldVip ? 'Gold Active 👑' : 'SparkQuest Gold', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGoldVip ? AppTheme.questGold.withOpacity(0.2) : AppTheme.bgCard,
                    foregroundColor: _isGoldVip ? AppTheme.questGold : Colors.white,
                    side: BorderSide(color: _isGoldVip ? AppTheme.questGold : AppTheme.sparkCoral.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Spark Pass Season 1 Banner Button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showDialog(
                context: context,
                builder: (ctx) => SparkPassDialog(
                  currentXP: 450,
                  onRewardClaimed: (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🎉 +$val Embers from Spark Pass!')),
                    );
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.2),
                    const Color(0xFFEC4899).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('⭐', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Season 1: Spark Pass (30 Tiers)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        Text('Level 4: Explorer Keen • 450 XP', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Supabase Linked Cloud Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🟢 ', style: TextStyle(fontSize: 12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supabase Cloud Sync', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Project: ${SupabaseService.projectRef} (Active & Healthy)', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final ok = await SupabaseService.instance.checkConnection();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? '🟢 Supabase connected successfully!' : '⚠️ Offline fallback active'),
                          backgroundColor: ok ? const Color(0xFF10B981) : Colors.amber.shade800,
                        ),
                      );
                    }
                  },
                  child: const Text('Test Ping', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Liveness Verification Banner / Badge
          _buildVerificationBanner(),

          const SizedBox(height: 24),

          // Voice Spark Section
          _buildVoiceSparkCard(),

          const SizedBox(height: 24),

          // 6-Photo Grid
          const Text(
            'MEDIA GALLERY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 12),
          _buildPhotoGrid(),

          const SizedBox(height: 24),

          // Explorer Persona & RPG Attributes
          const Text(
            'EXPLORER PERSONA',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.questGold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAttributesCard(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUserHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.sparkCoral.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            AppTheme.sparkCoral.withOpacity(0.12),
            AppTheme.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _selectedFrame == 'phoenix_flame'
                        ? AppTheme.sparkCoral
                        : (_selectedFrame == 'neon_crown'
                            ? AppTheme.questGold
                            : (_selectedFrame == 'galactic_violet' ? AppTheme.electricViolet : AppTheme.neonCyan)),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_selectedFrame == 'phoenix_flame'
                              ? AppTheme.sparkCoral
                              : (_selectedFrame == 'neon_crown'
                                  ? AppTheme.questGold
                                  : (_selectedFrame == 'galactic_violet' ? AppTheme.electricViolet : AppTheme.neonCyan)))
                          .withOpacity(0.55),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Image.asset(
                    'assets/images/alex.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: AppTheme.bgInput,
                      child: const Icon(Icons.person, color: AppTheme.neonCyan, size: 40),
                    ),
                  ),
                ),
              ),
              if (_isVerified)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.emeraldGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Alex, 27',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_isGoldVip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.questGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.questGold),
                        ),
                        child: const Text('👑 VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.questGold)),
                      ),
                    if (_isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 18, color: AppTheme.emeraldGreen),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Software Engineer • Explorer Lv. 7',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.questGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✦ ', style: TextStyle(color: AppTheme.questGold, fontSize: 12)),
                          Text(
                            '${widget.embers} Embers',
                            style: const TextStyle(
                              color: AppTheme.questGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.sparkCoral.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🔥 3d Streak (1.25x)',
                        style: TextStyle(
                          color: AppTheme.sparkCoral,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateShieldBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.electricViolet.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.electricViolet.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: AppTheme.electricViolet, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Shield 2.0 Active',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Live GPS sharing & discrete safety triggers',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenDateShield,
                  icon: const Icon(Icons.location_on, size: 16, color: AppTheme.neonCyan),
                  label: const Text('Share Live Location', style: TextStyle(fontSize: 12, color: AppTheme.neonCyan)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.neonCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _triggerFakeCall,
                icon: const Icon(Icons.phone_forwarded, size: 16),
                label: const Text('Fake Call', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkCoral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isVerified
            ? AppTheme.emeraldGreen.withOpacity(0.12)
            : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isVerified ? AppTheme.emeraldGreen : AppTheme.neonCyan.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_isVerified ? AppTheme.emeraldGreen : AppTheme.neonCyan).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isVerified ? Icons.verified : Icons.face,
              color: _isVerified ? AppTheme.emeraldGreen : AppTheme.neonCyan,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isVerified ? 'Profile Verified' : 'Anti-Catfish Liveness Check',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _isVerified
                      ? '3D face scan verified • Trust score 100%'
                      : 'Take a 3-step live selfie check to earn your blue tick',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!_isVerified)
            ElevatedButton(
              onPressed: _triggerLivenessModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceSparkCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.electricViolet.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mic, color: AppTheme.electricViolet, size: 20),
              SizedBox(width: 8),
              Text(
                'VOICE SPARK (15s Max)',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricViolet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '"My secret, completely useless talent 🪄"',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          if (_isRecordingVoice)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sparkCoral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.sparkCoral),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppTheme.sparkCoral,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.5, 1.5),
                        duration: 600.ms,
                      ),
                  const SizedBox(width: 10),
                  Text(
                    'Recording... 00:${_voiceSeconds.toString().padLeft(2, '0')} / 00:15',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.sparkCoral),
                  ),
                ],
              ),
            )
          else if (_hasVoicePrompt)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.play_circle_fill, color: AppTheme.neonCyan, size: 28),
                  SizedBox(width: 8),
                  Text('Voice snippet saved (0:12)', style: TextStyle(color: AppTheme.neonCyan, fontSize: 13)),
                  Spacer(),
                  Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 18),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _toggleVoiceRecording,
            icon: Icon(_isRecordingVoice ? Icons.stop : Icons.mic),
            label: Text(_isRecordingVoice ? 'Stop & Save Spark' : (_hasVoicePrompt ? 'Re-record Prompt' : 'Record Voice Prompt')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecordingVoice ? AppTheme.sparkCoral : AppTheme.electricViolet,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final photo = _photos[index];
        if (photo != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.bgInput,
                    child: const Icon(Icons.person, color: AppTheme.textSecondary),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: AppTheme.neonCyan),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: AppTheme.sparkCoral.withOpacity(0.85),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: const Text(
                        'MAIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select image from Gallery or Camera')),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.neonCyan.withOpacity(0.25),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: AppTheme.neonCyan, size: 28),
                SizedBox(height: 4),
                Text('Add', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttributesCard() {
    final attributes = [
      {'label': 'Archetype', 'val': '🌌 Night Owl Strategist', 'color': AppTheme.electricViolet},
      {'label': 'Quest Rank', 'val': '🛡️ Platinum Explorer Lv. 7', 'color': AppTheme.questGold},
      {'label': 'Dating Mode', 'val': '🔥 Serious Sparks & Escapades', 'color': AppTheme.sparkCoral},
      {'label': 'Love Language', 'val': '✨ Quality Time & Co-op Gaming', 'color': AppTheme.neonCyan},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.questGold.withOpacity(0.3)),
      ),
      child: Column(
        children: attributes.map((attr) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  attr['label'] as String,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  attr['val'] as String,
                  style: TextStyle(
                    color: attr['color'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LivenessVerificationModal extends StatefulWidget {
  final VoidCallback onVerified;

  const _LivenessVerificationModal({required this.onVerified});

  @override
  State<_LivenessVerificationModal> createState() => _LivenessVerificationModalState();
}

class _LivenessVerificationModalState extends State<_LivenessVerificationModal> {
  int _step = 0;
  bool _flash = false;

  final List<Map<String, String>> _challenges = [
    {
      'title': 'Center Your Face',
      'instruction': 'Position your face inside the glowing oval.',
      'icon': '👤',
    },
    {
      'title': 'Tilt Head Left',
      'instruction': 'Slowly turn your head slightly to the left.',
      'icon': '👈',
    },
    {
      'title': 'Smile for the Camera',
      'instruction': 'Give a natural smile to confirm 3D depth.',
      'icon': '😊',
    },
  ];

  void _nextStep() {
    if (_step < _challenges.length - 1) {
      setState(() => _step++);
    } else {
      // Trigger flash and complete
      setState(() => _flash = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flash = false);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.pop(context);
            widget.onVerified();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = _challenges[_step];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: _flash ? Colors.white : AppTheme.bgDeep,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '3D Anti-Catfish Scan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textDim),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Oval simulated camera view
            Container(
              width: 220,
              height: 280,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(140),
                border: Border.all(
                  color: AppTheme.neonCyan,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    cur['icon']!,
                    style: const TextStyle(fontSize: 80),
                  ),
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Step ${_step + 1} of 3',
                        style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              cur['title']!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              cur['instruction']!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _step == 2 ? 'Complete Scan 📸' : 'Next Step ➜',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
