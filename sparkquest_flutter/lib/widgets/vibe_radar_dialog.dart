import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VibeRadarDialog extends StatelessWidget {
  final String matchName;

  const VibeRadarDialog({super.key, this.matchName = 'Sophia'});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('📊 ', style: TextStyle(fontSize: 20)),
                    Text(
                      '6-AXIS VIBE RADAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textDim),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Comparing your attributes with $matchName',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Radar Chart Canvas
            SizedBox(
              width: 250,
              height: 230,
              child: CustomPaint(painter: _RadarChartPainter()),
            ),

            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('You (Alex)', AppTheme.neonCyan),
                const SizedBox(width: 20),
                _legendItem(matchName, AppTheme.sparkCoral),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.questGold.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                '🔥 Highest Resonance: Spontaneity (94%) & Wit (88%). You two thrive on playful banter and unscripted adventures!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<String> labels = [
    '🧗 Adventure',
    '🧠 Wit',
    '🎭 Humor',
    '⚡ Energy',
    '🔮 Spontaneity',
    '💖 Romance',
  ];
  final List<double> youVals = [0.85, 0.92, 0.80, 0.75, 0.90, 0.78];
  final List<double> matchVals = [0.90, 0.88, 0.85, 0.70, 0.94, 0.82];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final total = labels.length;
    final angleStep = (2 * pi) / total;

    // Web circles / polygons
    for (int ring = 1; ring <= 4; ring++) {
      final r = (radius / 4) * ring;
      final path = Path();
      for (int i = 0; i < total; i++) {
        final angle = i * angleStep - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Spokes and labels
    for (int i = 0; i < total; i++) {
      final angle = i * angleStep - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      canvas.drawLine(
        center,
        Offset(x, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..strokeWidth = 1,
      );

      // Label text
      final labelAngle = angle;
      final labelX = center.dx + (radius + 18) * cos(labelAngle);
      final labelY = center.dy + (radius + 14) * sin(labelAngle);

      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // You Polygon (Neon Cyan)
    _drawPolygon(
      canvas,
      center,
      radius,
      youVals,
      AppTheme.neonCyan.withValues(alpha: 0.3),
      AppTheme.neonCyan,
    );

    // Match Polygon (Spark Coral)
    _drawPolygon(
      canvas,
      center,
      radius,
      matchVals,
      AppTheme.sparkCoral.withValues(alpha: 0.3),
      AppTheme.sparkCoral,
    );
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double maxRadius,
    List<double> vals,
    Color fill,
    Color stroke,
  ) {
    final total = vals.length;
    final angleStep = (2 * pi) / total;
    final path = Path();

    for (int i = 0; i < total; i++) {
      final angle = i * angleStep - pi / 2;
      final r = maxRadius * vals[i];
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int i = 0; i < total; i++) {
      final angle = i * angleStep - pi / 2;
      final r = maxRadius * vals[i];
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
