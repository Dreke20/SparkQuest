import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ReleaseNotesDialog extends StatelessWidget {
  const ReleaseNotesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: AppTheme.sparkCoral.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.sparkCoral),
                        ),
                        child: const Text('🚀', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Release Notes & Roadmap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'SparkQuest Version Tracking',
                            style: TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textDim, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Scrollable Notes Body
              Expanded(
                child: ListView(
                  children: [
                    _buildVersionCard(
                      badge: 'CURRENT RELEASE',
                      badgeColor: AppTheme.emeraldGreen,
                      version: 'v2.0.0+5',
                      date: 'October 2026',
                      title: 'Live Map, Restored Neon Branding & 50 Top-Tier Features',
                      highlights: const [
                        '🗺️ Live OpenStreetMap & CartoDB Dark Radar: Pan, pinch, and zoom live city streets with anchored Safe Havens and 500m privacy blur radius.',
                        '🔥 Restored Original Neon Flaming-Heart Logo across AppBar, Android launcher icons, and onboarding.',
                        '⚖️ Balanced Monetization: 150🔥 starter balance, anti-cheat purchase guards, daily grant cooldown, and 2x Gold VIP multipliers.',
                        '🛡️ Fortress Safety: Date Shield 2.0 with Fake Escape Call, community Safe Haven check-ins, and 3D Anti-Catfish scan.',
                        '⚡ 60fps Optimization: RepaintBoundary layers & resolution-aware image decoding reduce texture memory by ~65%.',
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildVersionCard(
                      badge: 'PREVIEW ACTIVE',
                      badgeColor: AppTheme.neonCyan,
                      version: 'v2.1.0-preview',
                      date: 'November 2026',
                      title: 'Drop-In Voice Lounges & BLE Proximity Discovery',
                      highlights: const [
                        '🎙️ Live Audio Lounges: Drop-in audio chat rooms to connect with local explorers before formal dates.',
                        '🎤 Realtime Speaking Halos: Visual audio activity rings with 1-tap mic mute and hand-raising.',
                        '✨ Floating Spark Reactions: Realtime reaction emojis (🔥, ☕, 💫, 💖) across live rooms.',
                        '📡 BLE Proximity Discovery: Broadcast custom vibe beacons ("Looking for Coffee", "Ready for Trivia") within 50m.',
                        '🛡️ Ephemeral BLE Privacy: Rotating Bluetooth MAC identifiers with zero permanent GPS exposure.',
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildVersionCard(
                      badge: 'FUTURE ROADMAP',
                      badgeColor: AppTheme.questGold,
                      version: 'v2.2.0',
                      date: 'Target: Q2 2027',
                      title: 'Wearable SOS & Global Teleport 2.0',
                      highlights: const [
                        '⌚ Wearable SOS: Apple Watch and WearOS discreet heart-rate spike emergency alert.',
                        '🌐 Global Teleport 2.0: Instant multi-city passports with live automated language translation.',
                        '🎟️ In-App Venue Meetup Booking: Direct reservations at curated meetup cafes and lounges.',
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ You are running the latest version (v2.0.0+5)!'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Close • Up to Date (v2.0.0+5)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard({
    required String badge,
    required Color badgeColor,
    required String version,
    required String date,
    required String title,
    required List<String> highlights,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
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
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                '$version • $date',
                style: const TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.neonCyan, fontSize: 12)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

