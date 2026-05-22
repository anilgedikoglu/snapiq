import 'dart:math';
import 'package:flutter/material.dart';

class LaserGatePainter extends CustomPainter {
  final List<double> angles; // current angle in radians for each ring
  final int ballRing; // 0=center, 1..3 = which ring ball is at
  final int lives;
  final int score;
  final int impactRing;   // -1 = none, 0-2 = which ring was just hit
  final double impactGlow; // 1.0 = just hit, 0.0 = faded out

  static const List<double> _radii = [80, 130, 180];
  static const List<Color> _ringColors = [
    Color(0xFF00B4FF),
    Color(0xFFE91E63),
    Color(0xFF03DAC6),
  ];
  static const double _gapAngle = pi / 3; // 60 degrees
  static const double _strokeWidth = 6;

  const LaserGatePainter({
    required this.angles,
    required this.ballRing,
    required this.lives,
    required this.score,
    this.impactRing = -1,
    this.impactGlow = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw rings with gap
    for (int i = 0; i < 3; i++) {
      final radius = _radii[i];
      final color = _ringColors[i];
      final angle = angles[i];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // If this ring was just hit, flash it red-orange
      if (i == impactRing && impactGlow > 0) {
        final flashPaint = Paint()
          ..color = const Color(0xFFFF4D4D).withValues(alpha: impactGlow * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth + 10
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * impactGlow);
        final rect = Rect.fromCircle(center: center, radius: radius);
        final gapStart = angle - pi / 2 - _gapAngle / 2;
        final arcSweep = 2 * pi - _gapAngle;
        canvas.drawArc(rect, gapStart + _gapAngle, arcSweep, false, flashPaint);
      }

      final rect = Rect.fromCircle(center: center, radius: radius);
      final gapStart = angle - pi / 2 - _gapAngle / 2;
      final arcSweep = 2 * pi - _gapAngle;

      canvas.drawArc(rect, gapStart + _gapAngle, arcSweep, false, glowPaint);
      canvas.drawArc(rect, gapStart + _gapAngle, arcSweep, false, paint);
    }

    // ── Impact effect at 12-o'clock of the hit ring ──────────────────────────
    if (impactRing >= 0 && impactRing < 3 && impactGlow > 0) {
      final hitRadius = _radii[impactRing];
      final hitPos = Offset(center.dx, center.dy - hitRadius);
      final ringColor = _ringColors[impactRing];

      // Expanding shockwave ring
      final shockR = 7.0 + (1.0 - impactGlow) * 22.0;
      final shockPaint = Paint()
        ..color = ringColor.withValues(alpha: impactGlow * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * impactGlow);
      canvas.drawCircle(hitPos, shockR, shockPaint);

      // Second larger shockwave (slight delay feel)
      final shockR2 = 12.0 + (1.0 - impactGlow) * 30.0;
      final shockPaint2 = Paint()
        ..color = Colors.white.withValues(alpha: impactGlow * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * impactGlow);
      canvas.drawCircle(hitPos, shockR2, shockPaint2);

      // Bright core flash
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: impactGlow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * impactGlow);
      canvas.drawCircle(hitPos, 5.5 * impactGlow, corePaint);

      // 8 radiating sparks
      const sparkCount = 8;
      final sparkPaint = Paint()
        ..color = ringColor.withValues(alpha: impactGlow * 0.9)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final sparkInner = 8.0;
      final sparkOuter = sparkInner + 10.0 + (1.0 - impactGlow) * 8.0;
      for (int k = 0; k < sparkCount; k++) {
        final a = k * (2 * pi / sparkCount);
        final start = hitPos + Offset(cos(a) * sparkInner, sin(a) * sparkInner);
        final end   = hitPos + Offset(cos(a) * sparkOuter, sin(a) * sparkOuter);
        canvas.drawLine(start, end, sparkPaint);
      }
    }

    // ── Ball ─────────────────────────────────────────────────────────────────
    // Hide ball at center while impact animation is playing —
    // visually the ball "travelled to" the hit ring and is shown there as the impact.
    if (impactRing >= 0 && impactGlow > 0 && ballRing == 0) return;

    // ballRing=0: center; 1=between ring0-ring1; 2=between ring1-ring2; 3=past outer
    double ballR;
    Color ballColor;
    if (ballRing == 0) {
      ballR = 0;
      ballColor = Colors.white;
    } else if (ballRing == 1) {
      ballR = (_radii[0] + _radii[1]) / 2; // 105
      ballColor = _ringColors[0];
    } else if (ballRing == 2) {
      ballR = (_radii[1] + _radii[2]) / 2; // 155
      ballColor = _ringColors[1];
    } else {
      ballR = _radii[2] + 20;
      ballColor = Colors.white;
    }

    final ballPaint = Paint()
      ..color = ballColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + Offset(0, -ballR), 10, ballPaint);

    final ballPaint2 = Paint()..color = Colors.white;
    canvas.drawCircle(center + Offset(0, -ballR), 7, ballPaint2);

    // Indicator tick at top (12 o'clock)
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    canvas.drawLine(
      center + Offset(0, -_radii[2] - 16),
      center + Offset(0, -_radii[2] - 6),
      tickPaint,
    );
  }

  @override
  bool shouldRepaint(LaserGatePainter oldDelegate) => true;
}
