import 'dart:math';
import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<double> targetAngles;
  final List<bool> targetLocked;
  final double tolerance;

  RadarPainter({
    required this.sweepAngle,
    required this.targetAngles,
    required this.targetLocked,
    this.tolerance = 40 * pi / 180,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background
    canvas.drawCircle(center, radius, Paint()
      ..color = const Color(0xFF050A14)
      ..style = PaintingStyle.fill);

    // Grid circles only (no spokes)
    final gridPaint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, gridPaint);
    }

    // ── Hit zone visuals (drawn first, targets on top) ───────────────────────
    for (int i = 0; i < targetAngles.length; i++) {
      if (targetLocked[i]) continue;
      final a = targetAngles[i];

      // 1. Sector fill (very faint) — shows the whole angular zone
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.95),
        a - tolerance,
        tolerance * 2,
        true,  // useCenter: pie-slice shape
        Paint()
          ..color = const Color(0xFFFF7043).withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );

      // 2. Thick arc on the outer ring — clearly visible zone boundary
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.88),
        a - tolerance,
        tolerance * 2,
        false,
        Paint()
          ..color = const Color(0xFFFF7043).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Sweep trail ──────────────────────────────────────────────────────────
    const trailSweep = pi / 3;
    final trailRect = Rect.fromCircle(center: center, radius: radius - 4);
    for (int i = 0; i < 20; i++) {
      final alpha = (i / 20) * 0.4;
      canvas.drawArc(
        trailRect,
        sweepAngle - trailSweep * (i / 20),
        trailSweep / 20,
        true,
        Paint()
          ..color = const Color(0xFF00C853).withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
    }

    // ── Sweep line ───────────────────────────────────────────────────────────
    canvas.drawLine(
      center,
      center + Offset(cos(sweepAngle) * radius, sin(sweepAngle) * radius),
      Paint()
        ..color = const Color(0xFF00C853)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Targets ───────────────────────────────────────────────────────────────
    for (int i = 0; i < targetAngles.length; i++) {
      final a = targetAngles[i];
      final pos = center + Offset(cos(a) * radius * 0.75, sin(a) * radius * 0.75);

      if (targetLocked[i]) {
        canvas.drawCircle(pos, 10, Paint()
          ..color = const Color(0xFF00C853)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(pos, 6, Paint()..color = Colors.white);
      } else {
        // Check if sweep is inside the hit zone → make dot brighter
        final diff = (sweepAngle - a).abs();
        final angDist = min(diff, (2 * pi - diff).abs());
        final isNear = angDist <= tolerance; // visual = detection zone

        canvas.drawCircle(pos, isNear ? 14 : 10, Paint()
          ..color = const Color(0xFFFF7043).withValues(alpha: isNear ? 0.8 : 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isNear ? 12 : 8));
        canvas.drawCircle(pos, isNear ? 8 : 6, Paint()
          ..color = isNear ? Colors.white : const Color(0xFFFF7043));
      }
    }

    // Border
    canvas.drawCircle(center, radius, Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
