import 'dart:math';
import 'package:flutter/material.dart';

class RingState {
  final double angle; // current total rotation radians
  final double radius; // 0..1 fraction of shortest canvas dimension
  final int segCount;
  final List<Color> palette;

  const RingState({
    required this.angle,
    required this.radius,
    required this.segCount,
    required this.palette,
  });
}

class OrbitSyncPainter extends CustomPainter {
  final List<RingState> rings;
  final List<Offset> stars;
  final double shockwave; // -1 = none, 0..1 expanding
  final Color shockwaveColor;
  final double glow; // 0..1 tap-flash at 12 o'clock
  final Color glowColor;
  final double targetGlow; // 0..1 approaching-sync glow on target marker
  final Color targetColor; // colour of the incoming sync
  final String? debugInfo; // non-null only when _kDebug == true

  static const double _strokeFraction = 0.045;
  static const double _segGap = 0.05; // radians of gap between segments

  const OrbitSyncPainter({
    required this.rings,
    required this.stars,
    this.shockwave = -1,
    this.shockwaveColor = const Color(0xFF00E5FF),
    this.glow = 0,
    this.glowColor = const Color(0xFF00E5FF),
    this.targetGlow = 0,
    this.targetColor = const Color(0xFF00E5FF),
    this.debugInfo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = size.shortestSide;

    // 1 — Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF050816),
    );

    // 2 — Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        1.1,
        starPaint,
      );
    }

    // 3 — Rings
    final strokeWidth = minDim * _strokeFraction;
    for (final ring in rings) {
      final radius = ring.radius * minDim / 2;
      final segW = (2 * pi) / ring.segCount;

      for (int seg = 0; seg < ring.segCount; seg++) {
        final color = ring.palette[seg % ring.palette.length];
        final startAngle = ring.angle + seg * segW - pi / 2;
        final sweep = segW - _segGap;

        // Proximity to 12 o'clock → extra brightness
        final midCanvas = startAngle + sweep / 2;
        final normalizedMid =
            ((midCanvas + pi / 2) % (2 * pi) + 2 * pi) % (2 * pi);
        final distToTop = _angleDist(normalizedMid, 0);
        final nearTop = distToTop < 0.22;
        final extraBright = nearTop ? 1.45 : 1.0;

        final rect = Rect.fromCircle(center: center, radius: radius);

        // Outer glow pass
        canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = color.withValues(alpha: 0.24 * extraBright)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 8
            ..strokeCap = StrokeCap.butt
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );

        // Inner solid pass
        canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = color.withValues(alpha: nearTop ? 1.0 : 0.87)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt,
        );
      }
    }

    // 4 — Target marker at 12 o'clock
    if (rings.isNotEmpty) {
      final outerR = rings.first.radius * minDim / 2 + strokeWidth / 2 + 8;

      // Approaching-sync halo behind marker
      if (targetGlow > 0) {
        final haloAlpha = targetGlow * 0.70;
        final haloRadius = 12.0 + targetGlow * 14.0;
        canvas.drawCircle(
          Offset(center.dx, center.dy - outerR - 7),
          haloRadius,
          Paint()
            ..color = targetColor.withValues(alpha: haloAlpha)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, 7 + targetGlow * 10),
        );
        // Second tighter ring so it looks like a pulse
        canvas.drawCircle(
          Offset(center.dx, center.dy - outerR - 7),
          haloRadius * 0.55,
          Paint()
            ..color = targetColor.withValues(alpha: haloAlpha * 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Marker line
      final lineAlpha = 0.55 + targetGlow * 0.45;
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: lineAlpha)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx, center.dy - outerR - 16),
        Offset(center.dx, center.dy - outerR),
        linePaint,
      );

      // Downward-pointing triangle
      final triTip = Offset(center.dx, center.dy - outerR);
      final triTopY = center.dy - outerR - 16;
      final triPath = Path()
        ..moveTo(triTip.dx, triTip.dy)
        ..lineTo(center.dx - 7, triTopY)
        ..lineTo(center.dx + 7, triTopY)
        ..close();
      canvas.drawPath(
        triPath,
        Paint()
          ..color = Colors.white.withValues(alpha: lineAlpha)
          ..style = PaintingStyle.fill,
      );
    }

    // 5 — Shockwave on tap
    if (shockwave >= 0) {
      final maxR = minDim * 0.6;
      final r = shockwave * maxR;
      final alpha = (1.0 - shockwave).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = shockwaveColor.withValues(alpha: alpha * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1.0 - shockwave * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = shockwaveColor.withValues(alpha: alpha * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // 6 — Tap-flash glow at 12 o'clock on each ring
    if (glow > 0) {
      for (final ring in rings) {
        final radius = ring.radius * minDim / 2;
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius),
          strokeWidth * 0.9,
          Paint()
            ..color = glowColor.withValues(alpha: glow * 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius),
          strokeWidth * 0.45,
          Paint()..color = Colors.white.withValues(alpha: glow * 0.85),
        );
      }
    }

    // 7 — Debug overlay (only when _kDebug == true in screen)
    if (debugInfo != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '  $debugInfo  ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            height: 1.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Dark pill behind text
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(6, 6, tp.width, tp.height),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xCC000000),
      );
      tp.paint(canvas, const Offset(6, 6));
    }
  }

  double _angleDist(double a, double b) {
    final d = ((a - b).abs()) % (2 * pi);
    return d > pi ? 2 * pi - d : d;
  }

  @override
  bool shouldRepaint(covariant OrbitSyncPainter old) => true;
}
