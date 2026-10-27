import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onEmberFound;

  const MapScreen({super.key, required this.onEmberFound});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _radarController;
  final List<MapDrop> _drops = [
    MapDrop(id: '1', title: 'Skyline Lounge', type: 'venue', icon: '🍸', x: 0.35, y: 0.42),
    MapDrop(id: '2', title: 'The Boathouse Cafe', type: 'venue', icon: '☕', x: 0.65, y: 0.55),
    MapDrop(id: '3', title: 'Fire Drop +50', type: 'fire', icon: '🔥', x: 0.48, y: 0.32, value: 50),
    MapDrop(id: '4', title: 'Gem Drop +100', type: 'gem', icon: '💎', x: 0.28, y: 0.62, value: 100),
  ];

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
          _drops.add(MapDrop(
            id: 'extra_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Mystery Beacon +75',
            type: 'fire',
            icon: '🔥',
            x: 0.5 + (Random().nextDouble() * 0.3 - 0.15),
            y: 0.5 + (Random().nextDouble() * 0.3 - 0.15),
            value: 75,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📡 Radar Scan Complete: 2 Hidden Ember Beacons Revealed!'),
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
              CustomPaint(
                painter: MapGridPainter(),
              ),
              // Concentric Radar Waves Animation
              if (_isScanning)
                Center(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SonarWavePainter(progress: _radarController.value),
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
                            color: AppTheme.neonCyan.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('You', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Map Drops & Venue Markers
              ..._drops.map((drop) => Positioned(
                left: MediaQuery.of(context).size.width * drop.x - 30,
                top: (MediaQuery.of(context).size.height - 200) * drop.y - 30,
                child: GestureDetector(
                  onTap: () {
                    if (drop.value > 0) {
                      widget.onEmberFound();
                      setState(() => _drops.remove(drop));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Claimed ${drop.title}! 🔥'),
                          backgroundColor: AppTheme.questGold,
                        ),
                      );
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
                            color: drop.type == 'venue' ? AppTheme.electricViolet : AppTheme.questGold,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (drop.type == 'venue' ? AppTheme.electricViolet : AppTheme.questGold).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(drop.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          drop.title,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
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
              color: AppTheme.bgSurface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: AppTheme.neonCyan.withOpacity(0.15), blurRadius: 12),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/maya.png', width: 34, height: 34, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📡 PROXIMITY BEACON DETECTED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.neonCyan, letterSpacing: 0.8),
                      ),
                      Text(
                        'Maya (92% Match) is 280 ft away!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wave sent to Maya! 🌊'), backgroundColor: AppTheme.sparkCoral),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sparkCoral,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Wave 🌊', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              shadowColor: AppTheme.neonCyan.withOpacity(0.5),
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

  void _showVenueModal(String venueName) {
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.questGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: AppTheme.questGold, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERIFIED SAFE HAVEN PARTNER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.questGold, letterSpacing: 1),
                      ),
                      Text(
                        venueName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.questGold.withOpacity(0.1),
                border: Border.all(color: AppTheme.questGold.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('🎁 ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      '15% Off Total Bill (Code: SPARK15) • Angel Shot Protocol Active',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sparkCoral,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Checked in at $venueName! 15% discount unlocked. 🛡️'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              },
              child: const Text('Check In & Unlock 15% Perk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        ..color = AppTheme.neonCyan.withOpacity(opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final fillPaint = Paint()
        ..color = AppTheme.neonCyan.withOpacity(opacity * 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SonarWavePainter oldDelegate) => oldDelegate.progress != progress;
}
