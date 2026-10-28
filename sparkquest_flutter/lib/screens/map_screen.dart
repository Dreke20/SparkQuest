import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/quest_progression_service.dart';
import '../services/realtime_chat_service.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onEmberFound;

  const MapScreen({super.key, required this.onEmberFound});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _privacyFuzzActive = true;
  String _selectedCategory = 'all'; // 'all', 'venue', 'drop', 'event'
  late AnimationController _radarController;
  final List<MapDrop> _drops = [
    MapDrop(
      id: '1',
      title: 'Skyline Lounge',
      type: 'venue',
      icon: '🍸',
      x: 0.32,
      y: 0.42,
    ),
    MapDrop(
      id: '2',
      title: 'The Boathouse Cafe',
      type: 'venue',
      icon: '☕',
      x: 0.68,
      y: 0.56,
    ),
    MapDrop(
      id: '3',
      title: 'Fire Drop +50',
      type: 'fire',
      icon: '🔥',
      x: 0.48,
      y: 0.30,
      value: 50,
    ),
    MapDrop(
      id: '4',
      title: 'Gem Drop +100',
      type: 'gem',
      icon: '💎',
      x: 0.25,
      y: 0.64,
      value: 100,
    ),
    MapDrop(
      id: 'event_trivia',
      title: 'Rooftop Trivia Raid',
      type: 'event',
      icon: '🎉',
      x: 0.72,
      y: 0.34,
    ),
    MapDrop(
      id: 'event_run',
      title: 'Sunset Run & Matcha',
      type: 'event',
      icon: '🌅',
      x: 0.30,
      y: 0.24,
    ),
  ];

  List<MapDrop> get _filteredDrops {
    if (_selectedCategory == 'all') return _drops;
    if (_selectedCategory == 'venue') {
      return _drops.where((d) => d.type == 'venue').toList();
    }
    if (_selectedCategory == 'drop') {
      return _drops.where((d) => d.value > 0).toList();
    }
    if (_selectedCategory == 'event') {
      return _drops.where((d) => d.type == 'event').toList();
    }
    return _drops;
  }

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _triggerSonarScan() {
    setState(() => _isScanning = true);
    _radarController.forward(from: 0.0);

    // Add 2 newly revealed mystery drops
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _drops.add(
            MapDrop(
              id: 'extra_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Mystery Beacon +75',
              type: 'fire',
              icon: '🔥',
              x: 0.5 + (Random().nextDouble() * 0.3 - 0.15),
              y: 0.5 + (Random().nextDouble() * 0.3 - 0.15),
              value: 75,
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📡 Radar Scan Complete: 2 Hidden Ember Beacons Revealed!',
            ),
            backgroundColor: AppTheme.neonCyan,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Canvas Area
        Container(
          color: const Color(0xFF070B14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Grid Background Lines
              CustomPaint(painter: MapGridPainter()),
              // Concentric Radar Waves Animation
              if (_isScanning)
                Center(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SonarWavePainter(
                          progress: _radarController.value,
                        ),
                        child: const SizedBox(width: 320, height: 320),
                      );
                    },
                  ),
                ),
              // User Center Marker
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Map Drops & Venue Markers
              ..._filteredDrops.map(
                (drop) => Positioned(
                  left: MediaQuery.of(context).size.width * drop.x - 30,
                  top: (MediaQuery.of(context).size.height - 200) * drop.y - 30,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (drop.value > 0) {
                        widget.onEmberFound();
                        QuestProgressionService.instance.incrementQuest(
                          'engage5',
                          xpGain: 25,
                        );
                        setState(() => _drops.remove(drop));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Claimed ${drop.title}! 🔥 (+25 XP)'),
                            backgroundColor: AppTheme.questGold,
                          ),
                        );
                      } else if (drop.type == 'event') {
                        _showEventRsvpModal(drop);
                      } else {
                        _showVenueModal(drop.title);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: drop.type == 'venue'
                                  ? AppTheme.electricViolet
                                  : (drop.type == 'event'
                                      ? AppTheme.neonCyan
                                      : AppTheme.questGold),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (drop.type == 'venue'
                                            ? AppTheme.electricViolet
                                            : (drop.type == 'event'
                                                ? AppTheme.neonCyan
                                                : AppTheme.questGold))
                                        .withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            drop.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            drop.title,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
        ),
        // Proximity Beacon Alert
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/maya.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📡 PROXIMITY BEACON DETECTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonCyan,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Maya (92% Match) is 280 ft away!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    RealtimeChatService.instance.sendMessage(
                      'Maya',
                      '👋 Waved at your Proximity Beacon (280 ft away)!',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Wave sent to Maya’s chat! 🌊 Check Matches for her reply.',
                        ),
                        backgroundColor: AppTheme.sparkCoral,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sparkCoral,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Wave 🌊',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Map Category Filter Bar + #28 Privacy Fuzzing + #31 Weather Smart Suggestion
        Positioned(
          top: 80,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('all', '✨ All Radar'),
                    const SizedBox(width: 8),
                    _buildFilterPill('event', '🎉 Live Events'),
                    const SizedBox(width: 8),
                    _buildFilterPill('venue', '🛡️ Safe Havens'),
                    const SizedBox(width: 8),
                    _buildFilterPill('drop', '🔥 Ember Drops'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () => _privacyFuzzActive = !_privacyFuzzActive,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _privacyFuzzActive
                                  ? '🛡️ Map Privacy Shield: Coordinates fuzzed to 500m radius'
                                  : '📍 Exact Venue Check-In Mode active',
                            ),
                            backgroundColor: AppTheme.emeraldGreen,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _privacyFuzzActive
                              ? AppTheme.emeraldGreen.withValues(alpha: 0.2)
                              : AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.emeraldGreen),
                        ),
                        child: Text(
                          _privacyFuzzActive
                              ? '🛡️ 500m Privacy Blur'
                              : '📍 Exact Pin',
                          style: const TextStyle(
                            color: AppTheme.emeraldGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  '🌤️ 66°F Golden Hour • Top Idea: Rooftop Trivia or Botanical Patio',
                  style: TextStyle(color: AppTheme.questGold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        // #29: Crossing Paths ("Missed Connections") Radar Button
        Positioned(
          bottom: 24,
          left: 16,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bgSurface,
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.electricViolet),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            onPressed: _showCrossedPathsModal,
            icon: const Text('👣', style: TextStyle(fontSize: 15)),
            label: const Text(
              '3 Crossed Paths',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ),
        // Pulse Radar Floating Button
        Positioned(
          bottom: 24,
          right: 20,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              shadowColor: AppTheme.neonCyan.withValues(alpha: 0.5),
            ),
            icon: const Icon(Icons.satellite_alt, size: 20),
            label: Text(
              _isScanning ? 'Scanning...' : '📡 Pulse Radar',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isScanning ? null : _triggerSonarScan,
          ),
        ),
      ],
    );
  }

  void _showCrossedPathsModal() {
    HapticFeedback.selectionClick();
    final crossed = [
      {
        'name': 'Sophia',
        'place': '☕ The Boathouse Cafe • 2 hours ago',
        'asset': 'assets/images/sophia.png',
        'count': 'Crossed paths 3x this week',
      },
      {
        'name': 'Jordan',
        'place': '🎵 Vinyl District Coffee • Yesterday',
        'asset': 'assets/images/jordan.png',
        'count': 'Crossed paths 2x this week',
      },
      {
        'name': 'Taylor',
        'place': '🌳 Dolores Park Overlook • 4 hours ago',
        'asset': 'assets/images/taylor.png',
        'count': 'Crossed paths 4x this week',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👣 Crossed Paths Radar (Last 24h)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adventurers who visited the same Safe Haven neighborhoods as you.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...crossed.map((c) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage(c['asset']!),
                ),
                title: Text(
                  c['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${c['place']}\n${c['count']}',
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 11.5,
                  ),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sparkCoral,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    RealtimeChatService.instance.sendMessage(
                      c['name']!,
                      '👣 Just saw we crossed paths at ${c['place']}! Next espresso is on me ☕',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '👣 Sent a Crossed-Paths Spark to ${c['name']}!',
                        ),
                        backgroundColor: AppTheme.sparkCoral,
                      ),
                    );
                  },
                  child: const Text('Wave 👋', style: TextStyle(fontSize: 12)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showVenueModal(String venueName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.questGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: AppTheme.questGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERIFIED SAFE HAVEN PARTNER • 4.9 ★ SAFETY RATING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.questGold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        venueName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // #30: Community Vibe Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                '✨ Well-Lit Patio',
                '🤫 Easy Conversation Noise',
                '🍹 Great Mocktails',
                '🛡️ Trained Angel-Shot Staff',
              ]
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.questGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.questGold.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('🎁 ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      'QR Pass: SPARK-15 (15% Off Total Bill + Free 2nd Espresso) • Angel Shot Protocol Active',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sparkCoral,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      SupabaseService.instance.recordMapCheckin(
                        venueId: venueName,
                      );
                      QuestProgressionService.instance.incrementQuest(
                        'engage4',
                        xpGain: 40,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Checked in at $venueName! 15% QR Perk & +40 XP unlocked. 🛡️',
                          ),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                    },
                    child: const Text(
                      'Solo Check-In (+40 XP)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.questGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onEmberFound();
                      SupabaseService.instance.recordMapCheckin(
                        venueId: '${venueName}_coop',
                      );
                      QuestProgressionService.instance.incrementQuest(
                        'engage4',
                        xpGain: 80,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🤝 Co-Op Date Check-In Verified at $venueName! +50🔥 & +80 XP!',
                          ),
                          backgroundColor: AppTheme.questGold,
                        ),
                      );
                    },
                    child: const Text(
                      '🤝 Co-Op Check-In (+50🔥)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String id, String label) {
    final active = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.electricViolet
              : AppTheme.bgSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppTheme.neonCyan : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showEventRsvpModal(MapDrop eventDrop) {
    final isRsvped = StorageService.instance
        .getRsvpedEvents()
        .contains(eventDrop.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    eventDrop.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEON NIGHT COMMUNITY RAID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonCyan,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        eventDrop.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tonight at 7:30 PM • Verified Group Hangout with live trivia, icebreaker quests, and +50 Embers check-in bonus.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundImage: AssetImage('assets/images/sophia.png'),
                ),
                const SizedBox(width: 6),
                const CircleAvatar(
                  radius: 14,
                  backgroundImage: AssetImage('assets/images/jordan.png'),
                ),
                const SizedBox(width: 6),
                const CircleAvatar(
                  radius: 14,
                  backgroundImage: AssetImage('assets/images/maya.png'),
                ),
                const SizedBox(width: 10),
                Text(
                  isRsvped
                      ? 'You + 11 Explorers RSVP’d ✓'
                      : '11 Nearby Explorers Attending',
                  style: const TextStyle(
                    color: AppTheme.questGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRsvped
                    ? AppTheme.emeraldGreen
                    : AppTheme.sparkCoral,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!isRsvped) {
                  await StorageService.instance.addRsvpedEvent(eventDrop.id);
                  await SupabaseService.instance.recordMapCheckin(
                    venueId: eventDrop.id,
                  );
                  QuestProgressionService.instance.incrementQuest(
                    'engage4',
                    xpGain: 60,
                  );
                  widget.onEmberFound();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🎉 RSVP Confirmed for ${eventDrop.title}! +50 Embers & +60 XP earned!',
                        ),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                isRsvped ? Icons.check_circle : Icons.celebration,
                color: Colors.white,
              ),
              label: Text(
                isRsvped
                    ? 'RSVP Confirmed (Checked In)'
                    : 'RSVP & Check In (+50🔥)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapDrop {
  final String id;
  final String title;
  final String type;
  final String icon;
  final double x;
  final double y;
  final int value;

  MapDrop({
    required this.id,
    required this.title,
    required this.type,
    required this.icon,
    required this.x,
    required this.y,
    this.value = 0,
  });
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF131D33)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SonarWavePainter extends CustomPainter {
  final double progress;

  SonarWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final p = (progress + (i * 0.33)) % 1.0;
      final radius = p * maxRadius;
      final opacity = (1.0 - p).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final fillPaint = Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: opacity * 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SonarWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
