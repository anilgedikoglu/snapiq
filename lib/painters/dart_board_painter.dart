import 'dart:math';
import 'package:flutter/material.dart';

class DartBoardPainter extends CustomPainter {
  static const List<Color> _ringColors = [
    Color(0xFF1A1A1A), // 1 - black
    Color(0xFFE53935), // 2 - red
    Color(0xFF1A1A1A), // 3
    Color(0xFF43A047), // 4 - green
    Color(0xFF1A1A1A), // 5
    Color(0xFFE53935), // 6
    Color(0xFF1A1A1A), // 7
    Color(0xFF43A047), // 8
    Color(0xFFFDD835), // 9 - bullseye outer
    Color(0xFFE53935), // 10 - bullseye
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2;

    for (int i = _ringColors.length - 1; i >= 0; i--) {
      final r = maxR * (i + 1) / _ringColors.length;
      final paint = Paint()..color = _ringColors[i];
      canvas.drawCircle(center, r, paint);

      // Ring border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, r, borderPaint);
    }

    // Draw cross lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    canvas.drawLine(
        center - Offset(maxR, 0), center + Offset(maxR, 0), linePaint);
    canvas.drawLine(
        center - Offset(0, maxR), center + Offset(0, maxR), linePaint);
  }

  @override
  bool shouldRepaint(DartBoardPainter oldDelegate) => false;
}
