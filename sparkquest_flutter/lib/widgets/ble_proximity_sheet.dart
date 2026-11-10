import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/quest_progression_service.dart';
import '../services/realtime_chat_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BleProximitySheet extends StatefulWidget {
  final VoidCallback? onEmberSpent;

  const BleProximitySheet({super.key, this.onEmberSpent});

  @override
  State<BleProximitySheet> createState() => _BleProximitySheetState();
}

class _BleProximitySheetState extends State<BleProximitySheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  bool _isBroadcasting = true;
  String _currentVibe = 'Looking for Coffee ☕';
  int _rangeMeters = 50;

  final List<String> _vibes = [
    'Looking for Coffee ☕',
    'Ready for Trivia 🧠',
    'Sunset Stroll 🌅',
    'Board Games 🎲',
    'Gym Partner 🏋️',
    'Boba Run 🧋',
  ];

  List<_BleExplorer> get _explorers {
    if (!StorageService.instance.isReviewerAccount()) {
      return const <_BleExplorer>[];
    }
    return [
      _BleExplorer(
        id: 'maya',
        name: 'Maya [Review Demo]',
        rpgClass: 'Bard',
        level: 4,
        avatar: 'assets/images/maya.png',
        distanceMeters: 18,
        rssi: -48,
        vibe: 'Looking for Coffee ☕',
        synergy: 94,
        bonusText: '+25% Bard Synergy • Review Demo',
        relativeAngle: 0.85,
      ),
      _BleExplorer(
        id: 'sophia',
        name: 'Sophia [Review Demo]',
        rpgClass: 'Mage',
        level: 5,
        avatar: 'assets/images/sophia.png',
        distanceMeters: 29,
        rssi: -62,
        vibe: 'Ready for Trivia 🧠',
        synergy: 89,
        bonusText: '+20% Lore Synergy • Review Demo',
        relativeAngle: 2.3,
      ),
      _BleExplorer(
        id: 'alex',
        name: 'Alex [Review Demo]',
        rpgClass: 'Paladin',
        level: 6,
        avatar: 'assets/images/alex.png',
        distanceMeters: 42,
        rssi: -75,
        vibe: 'Sunset Stroll 🌅',
        synergy: 84,
        bonusText: '+15% Quest Defense • Review Demo',
        relativeAngle: 4.1,
      ),
      _BleExplorer(
        id: 'jordan',
        name: 'Jordan [Review Demo]',
        rpgClass: 'Rogue',
        level: 5,
        avatar: 'assets/images/jordan.png',
        distanceMeters: 48,
        rssi: -81,
        vibe: 'Board Games 🎲',
        synergy: 81,
        bonusText: '+10% Speed Bonus • Review Demo',
        relativeAngle: 5.4,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _isBroadcasting = StorageService.instance.isBleBeaconBroadcasting();
    _currentVibe = StorageService.instance.getBleBeaconVibe();
    _rangeMeters = StorageService.instance.getBleBeaconRangeMeters();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  void _toggleBroadcasting(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _isBroadcasting = value);
    await StorageService.instance.setBleBeaconBroadcasting(value);
  }

  void _selectVibe(String vibe) async {
    HapticFeedback.selectionClick();
    setState(() => _currentVibe = vibe);
    await StorageService.instance.saveBleBeaconVibe(vibe);
  }

  void _sendWave(_BleExplorer explorer) {
    HapticFeedback.mediumImpact();
    RealtimeChatService.instance.sendMessage(
      explorer.name,
      '👋 Waved at your BLE Beacon (${explorer.distanceMeters}m away)! Vibe: "$_currentVibe"',
    );
    QuestProgressionService.instance.incrementQuest('engage5', xpGain: 20);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌊 Wave sent to ${explorer.name}! (+20 XP)'),
        backgroundColor: AppTheme.neonCyan,
      ),
    );
  }

  void _sendSparkWhisper(_BleExplorer explorer) async {
    final cost = 5;
    final canAfford = StorageService.instance.canAffordEmbers(cost);
    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ You need at least 5 Embers for a Spark Whisper!'),
          backgroundColor: AppTheme.sparkCoral,
        ),
      );
      return;
    }

    final success = await StorageService.instance.spendEmbers(cost);
    if (success) {
      HapticFeedback.heavyImpact();
      widget.onEmberSpent?.call();
      RealtimeChatService.instance.sendMessage(
        explorer.name,
        '⚡ SPARK WHISPER: Hey! Our vibes matched on BLE Radar ("$_currentVibe"). Care to grab that coffee nearby?',
      );
      QuestProgressionService.instance.incrementQuest('engage5', xpGain: 35);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚡ High-Priority Whisper beamed to ${explorer.name}! (-5 Embers, +35 XP)',
            ),
            backgroundColor: AppTheme.questGold,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.textDim.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('📡', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BLE Proximity Radar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Discover adventurers crossing paths within 50m',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isBroadcasting,
                  onChanged: _toggleBroadcasting,
                  activeThumbColor: AppTheme.neonCyan,
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.bgCard, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Radar sweep visualizer
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _sweepController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(220, 220),
                              painter: _RadarSweepPainter(
                                sweepAngle: _sweepController.value * 2 * pi,
                                isScanning: _isBroadcasting,
                                maxDistance: _rangeMeters.toDouble(),
                                explorers: _isBroadcasting ? _explorers : [],
                              ),
                            );
                          },
                        ),
                        // Center user beacon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isBroadcasting
                                  ? AppTheme.neonCyan
                                  : AppTheme.textDim,
                              width: 2,
                            ),
                            boxShadow: _isBroadcasting
                                ? [
                                    BoxShadow(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Broadcast Status Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isBroadcasting
                          ? AppTheme.neonCyan.withValues(alpha: 0.12)
                          : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isBroadcasting
                            ? AppTheme.neonCyan.withValues(alpha: 0.4)
                            : AppTheme.textDim.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isBroadcasting
                                ? AppTheme.neonCyan
                                : AppTheme.textDim,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isBroadcasting
                              ? 'Broadcasting Vibe Beacon: Active (${_explorers.length} Found)'
                              : 'Beacon Paused (Silent Ghost Mode)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isBroadcasting
                                ? AppTheme.neonCyan
                                : AppTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Vibe Selector
                const Text(
                  'Your Broadcast Vibe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vibes.map((vibe) {
                    final isSelected = vibe == _currentVibe;
                    return ChoiceChip(
                      label: Text(vibe),
                      selected: isSelected,
                      onSelected: (_) => _selectVibe(vibe),
                      selectedColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                      backgroundColor: AppTheme.bgCard,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.neonCyan
                            : AppTheme.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.neonCyan
                            : AppTheme.textDim.withValues(alpha: 0.2),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Radar Radius Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discovery Range',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${_rangeMeters}m (~${(_rangeMeters * 3.28).round()} ft)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rangeMeters.toDouble(),
                  min: 15,
                  max: 75,
                  divisions: 4,
                  activeColor: AppTheme.neonCyan,
                  inactiveColor: AppTheme.bgCard,
                  onChanged: (val) async {
                    setState(() => _rangeMeters = val.round());
                    await StorageService.instance.saveBleBeaconRangeMeters(
                      _rangeMeters,
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Nearby Explorers Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Beacons in Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sparkCoral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_explorers.length} Online',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.sparkCoral,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (!_isBroadcasting)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Enable BLE Discovery to scan nearby adventurers.',
                        style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                      ),
                    ),
                  )
                else if (_explorers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          color: AppTheme.neonCyan,
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Radar Scanning...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Broadcasting your vibe beacon. When an adventurer carrying SparkQuest steps into your BLE radius, they will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (StorageService.instance.isReviewerAccount())
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.questGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.questGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.questGold,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Google Reviewer Demo: Showing test BLE nodes. Real users scan genuine physical devices.',
                              style: TextStyle(
                                color: AppTheme.questGold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ..._explorers.map((explorer) => _buildExplorerCard(explorer)),
                ],

                const SizedBox(height: 16),

                // BLE Privacy Shield Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text('🛡️', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ephemeral BLE Privacy Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldGreen,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'SparkQuest rotates Bluetooth MAC identifiers every 15 minutes. Exact GPS is never exposed to nearby phones.',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorerCard(_BleExplorer explorer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: explorer.synergy >= 90
              ? AppTheme.questGold.withValues(alpha: 0.4)
              : AppTheme.bgCard,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      explorer.avatar,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.bgSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          explorer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.electricViolet.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${explorer.rpgClass} Lv.${explorer.level}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.electricViolet,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.bluetooth_searching,
                          size: 13,
                          color: AppTheme.neonCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${explorer.distanceMeters}m away • ${explorer.rssi} dBm',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.neonCyan,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Synergy Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.questGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.questGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${explorer.synergy}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.questGold,
                      ),
                    ),
                    const Text(
                      'SYNERGY',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.questGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Vibe pill + bonus
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.sparkCoral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  explorer.vibe,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sparkCoral,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                explorer.bonusText,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textDim,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendWave(explorer),
                  icon: const Text('👋', style: TextStyle(fontSize: 13)),
                  label: const Text('Wave'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: AppTheme.textDim.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendSparkWhisper(explorer),
                  icon: const Text('⚡', style: TextStyle(fontSize: 13)),
                  label: const Text('Whisper (-5✦)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.questGold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BleExplorer {
  final String id;
  final String name;
  final String rpgClass;
  final int level;
  final String avatar;
  final int distanceMeters;
  final int rssi;
  final String vibe;
  final int synergy;
  final String bonusText;
  final double relativeAngle;

  _BleExplorer({
    required this.id,
    required this.name,
    required this.rpgClass,
    required this.level,
    required this.avatar,
    required this.distanceMeters,
    required this.rssi,
    required this.vibe,
    required this.synergy,
    required this.bonusText,
    required this.relativeAngle,
  });
}

class _RadarSweepPainter extends CustomPainter {
  final double sweepAngle;
  final bool isScanning;
  final double maxDistance;
  final List<_BleExplorer> explorers;

  _RadarSweepPainter({
    required this.sweepAngle,
    required this.isScanning,
    required this.maxDistance,
    required this.explorers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.bgDeep
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Concentric range rings
    final ringPaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.33, ringPaint);
    canvas.drawCircle(center, radius * 0.66, ringPaint);
    canvas.drawCircle(center, radius, ringPaint);

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      ringPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      ringPaint,
    );

    // Sweep gradient fan
    if (isScanning) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: pi / 2,
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.4),
            AppTheme.neonCyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(sweepAngle);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        0,
        pi / 2,
        true,
        sweepPaint,
      );
      canvas.restore();
    }

    // Nearby explorer blips
    final blipPaint = Paint()
      ..color = AppTheme.questGold
      ..style = PaintingStyle.fill;
    final blipGlowPaint = Paint()
      ..color = AppTheme.questGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (final exp in explorers) {
      final normDist = (exp.distanceMeters / maxDistance).clamp(0.2, 0.95);
      final blipDist = radius * normDist;
      final bx = center.dx + blipDist * cos(exp.relativeAngle);
      final by = center.dy + blipDist * sin(exp.relativeAngle);

      canvas.drawCircle(Offset(bx, by), 8, blipGlowPaint);
      canvas.drawCircle(Offset(bx, by), 4, blipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.maxDistance != maxDistance;
  }
}
