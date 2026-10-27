import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/profile.dart';
import '../theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback onEmbersEarned;
  final VoidCallback onOpenChat;

  const ExploreScreen({
    super.key,
    required this.onEmbersEarned,
    required this.onOpenChat,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Profile> _cards = [];
  final List<Profile> _history = [];
  Offset _dragOffset = Offset.zero;
  bool _isPlayingVoice = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _cards = List.from(Profile.seedProfiles);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _swipe(bool isRight) {
    if (_cards.isEmpty) return;
    final top = _cards.removeAt(0);
    _history.add(top);
    _dragOffset = Offset.zero;
    setState(() {});

    if (isRight) {
      _showMatchDialog(top);
    }
  }

  void _rewind() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous card to undo')),
      );
      return;
    }
    setState(() {
      final last = _history.removeLast();
      _cards.insert(0, last);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Swipe undone! ↩️')),
    );
  }

  void _showMatchDialog(Profile profile) {
    widget.onEmbersEarned();
    _confettiController.play();

    showDialog(
      context: context,
      builder: (ctx) => Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppTheme.neonCyan, AppTheme.sparkCoral, AppTheme.questGold],
          ),
          AlertDialog(
            backgroundColor: AppTheme.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppTheme.sparkCoral, width: 2),
            ),
            title: const Center(
              child: Text(
                'IT’S A SPARK! 💘',
                style: TextStyle(
                  color: AppTheme.sparkCoral,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(profile.photoAsset),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 12),
                Text(
                  'You and ${profile.name} sparked!',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.questGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '+10 Embers Earned 🔥',
                    style: TextStyle(color: AppTheme.questGold, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep Swiping', style: TextStyle(color: AppTheme.textDim)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkCoral,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onOpenChat();
                },
                child: const Text('Send Message', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar, size: 72, color: AppTheme.neonCyan),
            const SizedBox(height: 16),
            const Text(
              'All Caught Up on Sparks!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check the Map or tap Rewind to revisit.',
              style: TextStyle(color: AppTheme.textDim),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Profiles'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricViolet),
              onPressed: () => setState(() => _cards = List.from(Profile.seedProfiles)),
            ),
          ],
        ),
      );
    }

    final top = _cards.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Card Stack
          Expanded(
            child: Stack(
              children: [
                // Background Card
                if (_cards.length > 1)
                  Transform.scale(
                    scale: 0.94,
                    child: _buildCardContent(_cards[1], isTop: false),
                  ),
                // Top Card with Gesture Detector
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta;
                    });
                  },
                  onPanEnd: (details) {
                    if (_dragOffset.dx > 120) {
                      _swipe(true);
                    } else if (_dragOffset.dx < -120) {
                      _swipe(false);
                    } else {
                      setState(() => _dragOffset = Offset.zero);
                    }
                  },
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.rotate(
                      angle: _dragOffset.dx / 400 * (pi / 12),
                      child: _buildCardContent(top, isTop: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action Buttons Row
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCardContent(Profile profile, {required bool isTop}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isTop && _dragOffset.dx > 50
                ? AppTheme.emeraldGreen.withOpacity(0.4)
                : isTop && _dragOffset.dx < -50
                    ? AppTheme.sparkCoral.withOpacity(0.4)
                    : Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.asset(
            profile.photoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.bgSurface),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.4, 0.65, 1.0],
              ),
            ),
          ),
          // Compatibility Pill
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.neonCyan),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.neonCyan, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.compatPct}% Match',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile Details at Bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name & Age & Verified
                Row(
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (profile.isVerified)
                      const Icon(Icons.verified, color: AppTheme.neonCyan, size: 22),
                  ],
                ),
                Text(
                  '${profile.occupation} · ${profile.distance}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 10),
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                // Voice Spark Pill
                if (profile.hasVoicePrompt)
                  GestureDetector(
                    onTap: () {
                      setState(() => _isPlayingVoice = !_isPlayingVoice);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPlayingVoice ? AppTheme.neonCyan : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPlayingVoice ? Icons.pause_circle : Icons.play_circle_fill,
                            color: AppTheme.neonCyan,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profile.voicePromptText,
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _isPlayingVoice ? 'Playing...' : '12s',
                            style: const TextStyle(fontSize: 11, color: AppTheme.neonCyan),
                          ),
                        ],
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind
          _circleButton(
            icon: Icons.replay,
            color: AppTheme.questGold,
            size: 48,
            onTap: _rewind,
          ),
          // Pass
          _circleButton(
            icon: Icons.close,
            color: AppTheme.sparkCoral,
            size: 60,
            onTap: () => _swipe(false),
          ),
          // SuperLike
          _circleButton(
            icon: Icons.star,
            color: AppTheme.neonCyan,
            size: 52,
            onTap: () => _swipe(true),
          ),
          // Like
          _circleButton(
            icon: Icons.favorite,
            color: AppTheme.emeraldGreen,
            size: 60,
            onTap: () => _swipe(true),
          ),
          // Boost
          _circleButton(
            icon: Icons.bolt,
            color: AppTheme.electricViolet,
            size: 48,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚡ 1-Hour Super Boost Active! Profile 5x amplified.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.48),
        onPressed: onTap,
      ),
    );
  }
}
