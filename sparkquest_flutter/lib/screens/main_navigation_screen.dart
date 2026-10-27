import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'map_screen.dart';
import 'matches_chat_screen.dart';
import 'quests_screen.dart';
import 'profile_screen.dart';
import '../widgets/daily_spin_wheel_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _embers = 325;
  final int _streakDays = 3;

  void _addEmbers(int count) {
    setState(() => _embers += count);
  }

  void _openDateShieldModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _DateShieldBottomSheet(
        onEmergencyCall: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📞 Emergency call triggered! Phone ringing in 10s...'),
              backgroundColor: AppTheme.sparkCoral,
            ),
          );
        },
      ),
    );
  }

  void _showEmbersStore() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Text('✦ Spark Embers Vault', style: TextStyle(color: AppTheme.questGold, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Balance: $_embers Embers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Use Embers to Superlike, unlock radar scan boosts, and reveal mystery blind-date clues.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _storeOption('💎 100 Embers', 'Free daily grant', () {
              _addEmbers(100);
              Navigator.pop(ctx);
            }),
            const SizedBox(height: 8),
            _storeOption('🔥 500 Embers', 'Explorer Pouch', () {
              _addEmbers(500);
              Navigator.pop(ctx);
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textDim)),
          )
        ],
      ),
    );
  }

  Widget _storeOption(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.questGold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
              ],
            ),
            const Icon(Icons.add_circle, color: AppTheme.questGold),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExploreScreen(
        onEmbersEarned: () => _addEmbers(15),
        onOpenChat: () => setState(() => _currentIndex = 2),
      ),
      MapScreen(
        onEmberFound: () => _addEmbers(50),
      ),
      MatchesChatScreen(
        onOpenDateShield: _openDateShieldModal,
      ),
      QuestsScreen(
        streakDays: _streakDays,
        onClaimEmber: () => _addEmbers(100),
      ),
      ProfileScreen(
        embers: _embers,
        onOpenDateShield: _openDateShieldModal,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.sparkCoral, AppTheme.neonCyan],
              ).createShader(bounds),
              child: const Text(
                'SPARKQUEST',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.electricViolet.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.electricViolet.withOpacity(0.6)),
              ),
              child: const Text(
                'FLUTTER',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.neonCyan),
              ),
            ),
          ],
        ),
        actions: [
          // Streak Chip
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.sparkCoral.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.sparkCoral.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('🔥 ', style: TextStyle(fontSize: 12)),
                Text(
                  '${_streakDays}d (1.25x)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sparkCoral,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Embers Balance Chip
          GestureDetector(
            onTap: _showEmbersStore,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.questGold.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.questGold.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Text('✦ ', style: TextStyle(color: AppTheme.questGold, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(
                    '$_embers',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.questGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Daily Fortune Wheel Button
          IconButton(
            icon: const Text('🎡', style: TextStyle(fontSize: 18)),
            tooltip: 'Daily Fortune Wheel',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => DailySpinWheelDialog(
                  onAwardEmbers: (val) {
                    _addEmbers(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 +$val Embers added to your vault!'),
                        backgroundColor: AppTheme.questGold,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Date Shield SOS Button
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppTheme.neonCyan, size: 22),
            tooltip: 'Date Shield 2.0',
            onPressed: _openDateShieldModal,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department_outlined),
              activeIcon: Icon(Icons.local_fire_department_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Radar Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_rounded),
              label: 'Quests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DateShieldBottomSheet extends StatelessWidget {
  final VoidCallback onEmergencyCall;

  const _DateShieldBottomSheet({required this.onEmergencyCall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.shield, color: AppTheme.electricViolet, size: 28),
                SizedBox(width: 10),
                Text(
                  'Date Shield 2.0 Guardian',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Real-time discrete protection for meetups & live dates.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _shieldActionTile(
              icon: Icons.phone_in_talk,
              color: AppTheme.sparkCoral,
              title: 'Simulate Escape Call',
              subtitle: 'Trigger a realistic call to safely excuse yourself',
              onTap: onEmergencyCall,
            ),
            const SizedBox(height: 12),
            _shieldActionTile(
              icon: Icons.share_location,
              color: AppTheme.neonCyan,
              title: 'Live Location Link',
              subtitle: 'Share encrypted GPS link with your trusted contact',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📍 Live GPS link copied to clipboard and sent to emergency contact!'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _shieldActionTile(
              icon: Icons.lock_clock,
              color: AppTheme.questGold,
              title: 'Safety Check-in Timer (30 min)',
              subtitle: 'Auto-alerts your contact if you don\'t check in',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏰ Safety Check-in Timer set for 30 minutes.'),
                    backgroundColor: AppTheme.questGold,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _shieldActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textDim),
          ],
        ),
      ),
    );
  }
}
