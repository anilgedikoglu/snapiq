import 'dart:math';
import 'package:flutter/material.dart';

class LaserGatePainter extends CustomPainter {
  final List<double> angles; // current angle in radians for each ring
  final int ballRing; // 0=center, 1..3 = which ring ball is at
  final int lives;
  final int score;

  static const List<double> _radii = [80, 130, 180];
  static const List<Color> _ringColors = [
    Color(0xFF00B4FF),
    Color(0xFFE91E63),
    Color(0xFF03DAC6),
  ];
  static const double _gapAngle = pi / 3; // 60 degrees
  static const double _strokeWidth = 6;

  LaserGatePainter({
    required this.angles,
    required this.ballRing,
    required this.lives,
    required this.score,
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

      final rect = Rect.fromCircle(center: center, radius: radius);
      // Draw arc from gap end to gap start (full circle minus gap)
      final gapStart = angle - pi / 2 - _gapAngle / 2;
      final arcSweep = 2 * pi - _gapAngle;

      canvas.drawArc(rect, gapStart + _gapAngle, arcSweep, false, glowPaint);
      canvas.drawArc(rect, gapStart + _gapAngle, arcSweep, false, paint);
    }

    // Draw ball at its current ring position or center
    double ballR;
    Color ballColor;
    if (ballRing == 0) {
      ballR = 0;
      ballColor = Colors.white;
    } else {
      ballR = _radii[ballRing - 1];
      ballColor = ballRing <= 3 ? _ringColors[ballRing - 1] : Colors.white;
    }

    final ballPaint = Paint()
      ..color = ballColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + Offset(0, -ballR), 10, ballPaint);

    final ballPaint2 = Paint()..color = Colors.white;
    canvas.drawCircle(center + Offset(0, -ballR), 7, ballPaint2);

    // Indicator at top (12 o'clock)
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
