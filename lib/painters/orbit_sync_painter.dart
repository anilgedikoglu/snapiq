import 'dart:math';
import 'package:flutter/material.dart';

class OrbitSyncPainter extends CustomPainter {
  final List<double> angles;
  final List<List<Color>> ringColors;

  static const List<double> _radii = [150, 115, 80, 45];
  static const double _strokeWidth = 18;

  OrbitSyncPainter({required this.angles, required this.ringColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 4; i++) {
      final radius = _radii[i];
      final angle = angles[i];
      final colors = ringColors[i];

      // Arc 1: color[0] from angle to angle+pi
      _drawArc(canvas, center, radius, angle, pi, colors[0]);
      // Arc 2: color[1] from angle+pi to angle+2*pi
      _drawArc(canvas, center, radius, angle + pi, pi, colors[1]);
    }

    // Draw indicator tick at 12 o'clock (top)
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final outerR = _radii[0] + _strokeWidth / 2 + 6;
    final innerR = _radii[3] - _strokeWidth / 2 - 6;
    canvas.drawLine(
      center + Offset(0, -outerR),
      center + Offset(0, -innerR),
      tickPaint,
    );

    // Center dot
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(center, 6, dotPaint);
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double startAngle,
      double sweepAngle, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Glow layer
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth + 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final rect = Rect.fromCircle(center: center, radius: radius);
    // Flutter arc: 0 = 3 o'clock, -pi/2 = 12 o'clock
    // We want angle=0 to mean 12 o'clock, so offset by -pi/2
    canvas.drawArc(rect, startAngle - pi / 2, sweepAngle, false, glowPaint);
    canvas.drawArc(rect, startAngle - pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(OrbitSyncPainter oldDelegate) => true;
}
