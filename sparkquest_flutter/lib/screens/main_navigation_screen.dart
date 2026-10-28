import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'map_screen.dart';
import 'matches_chat_screen.dart';
import 'quests_screen.dart';
import 'profile_screen.dart';
import '../widgets/daily_spin_wheel_dialog.dart';
import '../widgets/date_guard_dialog.dart';
import '../widgets/onboarding_ftue_dialog.dart';
import '../widgets/spark_pass_dialog.dart';
import '../services/iap_service.dart';
import '../services/storage_service.dart';
import '../services/realtime_chat_service.dart';
import '../services/quest_progression_service.dart';
import '../widgets/notification_banner.dart';
import '../widgets/biometric_lock_screen.dart';
import '../widgets/video_call_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _embers = 150;
  int _streakDays = 3;
  String? _notificationSender;
  String? _notificationText;
  bool _isAppLocked = false;

  @override
  void initState() {
    super.initState();
    RealtimeChatService.instance.addListener(_onBadgeStateChanged);
    QuestProgressionService.instance.addListener(_onBadgeStateChanged);
    IAPService.instance.addListener(_onBadgeStateChanged);
    _initStorageAndServices();
  }

  @override
  void dispose() {
    RealtimeChatService.instance.removeListener(_onBadgeStateChanged);
    QuestProgressionService.instance.removeListener(_onBadgeStateChanged);
    IAPService.instance.removeListener(_onBadgeStateChanged);
    super.dispose();
  }

  void _onBadgeStateChanged() {
    if (mounted) setState(() {});
  }

  void _initStorageAndServices() async {
    await StorageService.instance.init();
    await IAPService.instance.initialize();
    if (mounted) {
      setState(() {
        _embers = StorageService.instance.getEmbers();
        _streakDays = StorageService.instance.getStreak();
      });

      final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (!isTest && !StorageService.instance.isFtueCompleted()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => OnboardingFtueDialog(
              onCompleted: (bonusEmbers) {
                _addEmbers(bonusEmbers);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🎁 Onboarding Complete! +$bonusEmbers Embers & +100 Season XP unlocked!',
                      ),
                      backgroundColor: AppTheme.questGold,
                    ),
                  );
                }
              },
            ),
          );
        });
      }
    }

    RealtimeChatService.instance.onIncomingNotification = (sender, text) {
      if (mounted && _currentIndex != 2) {
        HapticFeedback.mediumImpact();
        setState(() {
          _notificationSender = sender;
          _notificationText = text;
        });
        Timer(const Duration(seconds: 4), () {
          if (mounted && _notificationSender == sender) {
            setState(() {
              _notificationSender = null;
              _notificationText = null;
            });
          }
        });
      }
    };

    RealtimeChatService.instance.onIncomingCall = (signal) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final roomId = signal['room_id']?.toString() ?? 'room_1';
      final callerName = signal['caller_name']?.toString() ?? 'Maya';
      final callerAvatar = signal['caller_avatar']?.toString() ?? 'assets/images/maya.png';
      final isVoiceOnly = signal['is_voice_only'] == true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => IncomingCallDialog(
          roomId: roomId,
          callerName: callerName,
          callerAvatar: callerAvatar,
          isVoiceOnly: isVoiceOnly,
          onAccept: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  matchName: callerName,
                  photoAsset: callerAvatar.startsWith('http')
                      ? 'assets/images/maya.png'
                      : callerAvatar,
                  isVoiceOnly: isVoiceOnly,
                  onOpenDateShield: _openDateShieldModal,
                ),
              ),
            );
          },
          onDecline: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Declined Spark Call from $callerName'),
                backgroundColor: AppTheme.bgCard,
              ),
            );
          },
        ),
      );
    };
  }

  void _addEmbers(int count, {bool isRawPurchase = false}) {
    final effectiveDelta = (count > 0 && !isRawPurchase && IAPService.instance.isGoldVip)
        ? count * 2
        : count;
    setState(() {
      _embers = (_embers + effectiveDelta).clamp(0, 999999);
    });
    StorageService.instance.saveEmbers(_embers);
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
              content: Text(
                '📞 Escape Call armed! Incoming Realtime call in 2s...',
              ),
              backgroundColor: AppTheme.sparkCoral,
            ),
          );
          Timer(const Duration(seconds: 2), () {
            RealtimeChatService.instance.triggerIncomingCall(
              callerName: 'Maya (Roommate SOS)',
              callerAvatar: 'assets/images/maya.png',
              isVoiceOnly: true,
            );
          });
        },
      ),
    );
  }

  void _showEmbersStore() {
    final dailyClaimed = StorageService.instance.hasClaimedDailyGrantToday();
    final isVip = IAPService.instance.isGoldVip;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '✦ Spark Embers Vault',
              style: TextStyle(
                color: AppTheme.questGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isVip)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.questGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.questGold),
                ),
                child: const Text(
                  '👑 2x VIP ACTIVE',
                  style: TextStyle(
                    color: AppTheme.questGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Balance: $_embers Embers 🔥',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spend Embers on Super-Sparks (25🔥), Standout Roses (40🔥), Rewinds (15🔥), and Admirer Unblurs (30🔥).',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _storeOption(
                '🎁 Daily Spark Grant (+25🔥)',
                dailyClaimed ? 'Come back tomorrow for next grant' : 'Free 1x daily login reward',
                dailyClaimed ? 'CLAIMED ✓' : 'FREE',
                () async {
                  if (dailyClaimed) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⏳ Daily Spark Grant already claimed today! Resets at midnight.'),
                      ),
                    );
                    return;
                  }
                  await StorageService.instance.markDailyGrantClaimedToday();
                  _addEmbers(25);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  HapticFeedback.lightImpact();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎁 +25 Free Embers claimed for today!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _storeOption(
                '✦ Starter Pouch (150 Embers)',
                'Send 6 Super-Sparks or 3 Standout Roses',
                '\$1.99',
                () async {
                  Navigator.pop(ctx);
                  HapticFeedback.heavyImpact();
                  final p = IAPService.instance.products.firstWhere(
                    (prod) => prod.id == 'sparkquest_embers_100',
                  );
                  await IAPService.instance.purchase(
                    p,
                    onEmbersAdded: (amt) => _addEmbers(amt, isRawPurchase: true),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '💎 Purchase Successful! +150 Embers added to vault.',
                        ),
                        backgroundColor: AppTheme.questGold,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _storeOption(
                '🔥 Adventurer Chest (600 Embers)',
                'Includes +20% Bonus • Most Popular',
                '\$5.99',
                () async {
                  Navigator.pop(ctx);
                  HapticFeedback.heavyImpact();
                  final p = IAPService.instance.products.firstWhere(
                    (prod) => prod.id == 'sparkquest_embers_500',
                  );
                  await IAPService.instance.purchase(
                    p,
                    onEmbersAdded: (amt) => _addEmbers(amt, isRawPurchase: true),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🔥 Purchase Successful! +600 Embers added to vault.',
                        ),
                        backgroundColor: AppTheme.sparkCoral,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _storeOption(
                '👑 Sovereign Vault (1,500 Embers)',
                '+50% Bonus Embers + 1 Free Spotlight Boost',
                '\$12.99',
                () async {
                  Navigator.pop(ctx);
                  HapticFeedback.heavyImpact();
                  final p = IAPService.instance.products.firstWhere(
                    (prod) => prod.id == 'sparkquest_embers_1500',
                  );
                  await IAPService.instance.purchase(
                    p,
                    onEmbersAdded: (amt) => _addEmbers(amt, isRawPurchase: true),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '👑 Sovereign Vault Unlocked! +1,500 Embers & +1 Boost added.',
                        ),
                        backgroundColor: AppTheme.electricViolet,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _storeOption(
                '⚡ 30m Spotlight Boost',
                '5x local deck priority for 30 mins',
                '\$2.99',
                () async {
                  Navigator.pop(ctx);
                  HapticFeedback.heavyImpact();
                  final p = IAPService.instance.products.firstWhere(
                    (prod) => prod.id == 'sparkquest_spotlight_boost',
                  );
                  await IAPService.instance.purchase(p);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚡ Spotlight Boost Active! You are now featured locally.',
                        ),
                        backgroundColor: Color(0xFFF59E0B),
                      ),
                    );
                  }
                },
              ),
              if (!isVip) ...[
                const SizedBox(height: 8),
                _storeOption(
                  '👑 SparkQuest Gold VIP',
                  '2x Earned Embers, Free Rewinds & Unblur Admirers',
                  '\$14.99/mo',
                  () async {
                    Navigator.pop(ctx);
                    HapticFeedback.heavyImpact();
                    final p = IAPService.instance.products.firstWhere(
                      (prod) => prod.id == 'sparkquest_gold_monthly',
                    );
                    await IAPService.instance.purchase(p);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '👑 Welcome to SparkQuest Gold VIP! 2x Embers & Unlimited Perks unlocked.',
                          ),
                          backgroundColor: AppTheme.questGold,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await IAPService.instance.restorePurchases();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🔄 Google Play purchases restored successfully.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Restore Purchases',
              style: TextStyle(color: AppTheme.textDim, fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeOption(
    String title,
    String subtitle,
    String price,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.questGold.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.questGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: const TextStyle(
                  color: AppTheme.questGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExploreScreen(
        onEmbersEarned: () => _addEmbers(10),
        onBonusEmbers: _addEmbers,
        onOpenChat: () => setState(() => _currentIndex = 2),
      ),
      MapScreen(onEmberFound: () => _addEmbers(50)),
      MatchesChatScreen(
        onOpenDateShield: _openDateShieldModal,
        onAwardEmbers: _addEmbers,
      ),
      QuestsScreen(
        streakDays: _streakDays,
        onClaimEmber: _addEmbers,
      ),
      ProfileScreen(
        embers: _embers,
        onOpenDateShield: _openDateShieldModal,
        onTriggerLock: () => setState(() => _isAppLocked = true),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sparkCoral.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.sparkCoral, AppTheme.neonCyan],
              ).createShader(bounds),
              child: const Text(
                'SPARKQUEST',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Embers Balance Chip
          GestureDetector(
            onTap: _showEmbersStore,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.questGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.questGold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '✦ ',
                    style: TextStyle(
                      color: AppTheme.questGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_embers',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.questGold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Season Spark Pass Button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            icon: const Text('⭐', style: TextStyle(fontSize: 16)),
            tooltip: 'Season 1 Spark Pass',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => SparkPassDialog(
                  currentXP: QuestProgressionService.instance.seasonXp,
                  onRewardClaimed: (val) {
                    _addEmbers(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🎉 +$val Embers unlocked from Spark Pass!',
                        ),
                        backgroundColor: AppTheme.questGold,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Daily Fortune Wheel Button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            icon: const Text('🎡', style: TextStyle(fontSize: 16)),
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

          // Date Guard & Guardian Angel SOS Button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            icon: const Icon(Icons.shield, color: AppTheme.neonCyan, size: 19),
            tooltip: 'Date Guard Safety Shield',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const DateGuardDialog(),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          if (_notificationSender != null && _notificationText != null)
            NotificationBanner(
              sender: _notificationSender!,
              message: _notificationText!,
              onTap: () {
                setState(() {
                  _notificationSender = null;
                  _notificationText = null;
                  _currentIndex = 2; // Jump to Matches & Chat
                });
              },
              onDismiss: () {
                setState(() {
                  _notificationSender = null;
                  _notificationText = null;
                });
              },
            ),
          if (_isAppLocked)
            BiometricLockScreen(
              onUnlocked: () {
                setState(() => _isAppLocked = false);
              },
            ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            final unreadMessages = RealtimeChatService.instance
                .getConversations()
                .fold<int>(0, (sum, c) => sum + c.unreadCount);
            final claimableQuests = QuestProgressionService.instance.quests
                .where((q) => q.isCompleted && !q.isClaimed)
                .length;

            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.local_fire_department_outlined),
                  activeIcon: Icon(Icons.local_fire_department_rounded),
                  label: 'Explore',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore_rounded),
                  label: 'Radar Map',
                ),
                BottomNavigationBarItem(
                  icon: Badge.count(
                    count: unreadMessages,
                    isLabelVisible: unreadMessages > 0,
                    backgroundColor: AppTheme.sparkCoral,
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  activeIcon: Badge.count(
                    count: unreadMessages,
                    isLabelVisible: unreadMessages > 0,
                    backgroundColor: AppTheme.sparkCoral,
                    child: const Icon(Icons.chat_bubble_rounded),
                  ),
                  label: 'Matches',
                ),
                BottomNavigationBarItem(
                  icon: Badge.count(
                    count: claimableQuests,
                    isLabelVisible: claimableQuests > 0,
                    backgroundColor: AppTheme.emeraldGreen,
                    child: const Icon(Icons.shield_outlined),
                  ),
                  activeIcon: Badge.count(
                    count: claimableQuests,
                    isLabelVisible: claimableQuests > 0,
                    backgroundColor: AppTheme.emeraldGreen,
                    child: const Icon(Icons.shield_rounded),
                  ),
                  label: 'Quests',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            );
          },
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
                    content: Text(
                      '📍 Live GPS link copied to clipboard and sent to emergency contact!',
                    ),
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
                    content: Text(
                      '⏰ Safety Check-in Timer set for 30 minutes.',
                    ),
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
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
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
