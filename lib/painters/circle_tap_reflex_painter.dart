import 'dart:math';
import 'package:flutter/material.dart';

class CircleTapReflexPainter extends CustomPainter {
  /// Fraction of min(width, height) used as ring radius.
  final double radiusFraction;

  /// Ball's current angle in radians (canvas: 0=right, -pi/2=top).
  final double ballAngleRad;

  /// Direction of rotation: +1 = clockwise, -1 = counter-clockwise.
  final int direction;

  /// Width of the target arc in radians.
  final double targetArcWidthRad;

  /// 0..1 – how close the ball is to the target (drives target glow).
  final double approachGlow;

  /// 0..1 – tap-flash intensity.
  final double feedbackGlow;

  /// Colour of the tap flash.
  final Color feedbackColor;

  /// 0..1 – gold perfect-flash on the ring.
  final double perfectFlash;

  /// Whether to render the ball and its trail.
  final bool showBall;

  static const _targetAngleRad = -pi / 2; // 12 o'clock
  static const _trailCount = 10;
  static const _trailStepRad = 5.0 * pi / 180; // 5° per trail point

  const CircleTapReflexPainter({
    required this.radiusFraction,
    required this.ballAngleRad,
    required this.direction,
    required this.targetArcWidthRad,
    required this.approachGlow,
    this.feedbackGlow = 0,
    this.feedbackColor = const Color(0xFF00E5FF),
    this.perfectFlash = 0,
    this.showBall = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = size.shortestSide;
    final radius = minDim * radiusFraction;

    // ── 1. Background ─────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF050816),
    );

    // Subtle decorative outer ring
    canvas.drawCircle(
      center, radius * 1.18,
      Paint()
        ..color = const Color(0xFF1E293B).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 2. Main ring ──────────────────────────────────────────────────────────
    // Soft glow layer
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFF00B4FF).withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    // Solid ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFF2D4A7A).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── 3. Target arc at 12 o'clock ───────────────────────────────────────────
    _drawTargetArc(canvas, center, radius);

    // ── 4. Perfect flash (gold overlay on ring) ───────────────────────────────
    if (perfectFlash > 0) {
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = const Color(0xFFFFD84D).withValues(alpha: perfectFlash * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // ── 5. Feedback glow burst at ball position ───────────────────────────────
    if (feedbackGlow > 0 && showBall) {
      final bx = center.dx + cos(ballAngleRad) * radius;
      final by = center.dy + sin(ballAngleRad) * radius;
      canvas.drawCircle(
        Offset(bx, by), 36 * feedbackGlow,
        Paint()
          ..color = feedbackColor.withValues(alpha: feedbackGlow * 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      canvas.drawCircle(
        Offset(bx, by), 16 * feedbackGlow,
        Paint()
          ..color = feedbackColor.withValues(alpha: feedbackGlow * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    if (!showBall) return;

    // ── 6. Motion trail ───────────────────────────────────────────────────────
    for (int i = _trailCount; i >= 1; i--) {
      final trailAngle = ballAngleRad - direction * _trailStepRad * i;
      final tx = center.dx + cos(trailAngle) * radius;
      final ty = center.dy + sin(trailAngle) * radius;
      // Fraction 0 (farthest) to 1 (nearest ball)
      final frac = (_trailCount - i + 1) / _trailCount.toDouble();
      final alpha = frac * frac * 0.55;
      final r = 3.5 + frac * 4.5;
      canvas.drawCircle(
        Offset(tx, ty), r,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
      );
    }

    // ── 7. Ball ───────────────────────────────────────────────────────────────
    final bx = center.dx + cos(ballAngleRad) * radius;
    final by = center.dy + sin(ballAngleRad) * radius;
    final bp = Offset(bx, by);

    // Outer glow
    canvas.drawCircle(
      bp, 16,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    // Core
    canvas.drawCircle(bp, 8.5, Paint()..color = const Color(0xFF00E5FF));
    // Specular highlight
    canvas.drawCircle(
      Offset(bx - 2.5, by - 2.5), 3.0,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawTargetArc(Canvas canvas, Offset center, double radius) {
    final halfWidth = targetArcWidthRad / 2;
    final startAngle = _targetAngleRad - halfWidth;
    final sweep = targetArcWidthRad;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Glow layer (intensifies as ball approaches)
    final glowAlpha = 0.18 + approachGlow * 0.62;
    final glowWidth = 9.0 + approachGlow * 12.0;
    canvas.drawArc(
      rect, startAngle, sweep, false,
      Paint()
        ..color = const Color(0xFF41FF7A).withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, 5.0 + approachGlow * 7.0),
    );

    // Solid arc
    canvas.drawArc(
      rect, startAngle, sweep, false,
      Paint()
        ..color = const Color(0xFF41FF7A)
            .withValues(alpha: 0.80 + approachGlow * 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round,
    );

    // Centre dot at exact 12 o'clock
    final cx = center.dx + cos(_targetAngleRad) * radius;
    final cy = center.dy + sin(_targetAngleRad) * radius;
    canvas.drawCircle(
      Offset(cx, cy), 5.5 + approachGlow * 3,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65 + approachGlow * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + approachGlow * 5),
    );
    canvas.drawCircle(
      Offset(cx, cy), 2.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CircleTapReflexPainter old) => true;
}
