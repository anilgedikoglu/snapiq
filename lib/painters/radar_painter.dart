import 'dart:math';
import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  final double sweepAngle; // current sweep angle in radians
  final List<double> targetAngles;
  final List<bool> targetLocked;

  RadarPainter({
    required this.sweepAngle,
    required this.targetAngles,
    required this.targetLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF050A14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Grid circles
    final gridPaint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, gridPaint);
    }

    // Grid lines
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        center,
        center + Offset(cos(a) * radius, sin(a) * radius),
        gridPaint,
      );
    }

    // Sweep trail (fading arc)
    final trailSweep = pi / 2;
    final trailRect = Rect.fromCircle(center: center, radius: radius - 4);
    for (int i = 0; i < 20; i++) {
      final alpha = (i / 20) * 0.4;
      final trailPaint = Paint()
        ..color = const Color(0xFF00C853).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        trailRect,
        sweepAngle - trailSweep * (i / 20),
        trailSweep / 20,
        true,
        trailPaint,
      );
    }

    // Sweep line
    final sweepPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(
      center,
      center + Offset(cos(sweepAngle) * radius, sin(sweepAngle) * radius),
      sweepPaint,
    );

    // Targets
    for (int i = 0; i < targetAngles.length; i++) {
      final a = targetAngles[i];
      final pos = center + Offset(cos(a) * radius * 0.75, sin(a) * radius * 0.75);
      if (targetLocked[i]) {
        // Locked: green checkmark circle
        final lockPaint = Paint()
          ..color = const Color(0xFF00C853)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(pos, 10, lockPaint);
        final lockPaint2 = Paint()..color = Colors.white;
        canvas.drawCircle(pos, 6, lockPaint2);
      } else {
        // Unlocked: bright dot
        final dotGlow = Paint()
          ..color = const Color(0xFFFF7043).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(pos, 10, dotGlow);
        final dotPaint = Paint()..color = const Color(0xFFFF7043);
        canvas.drawCircle(pos, 6, dotPaint);
      }
    }

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
