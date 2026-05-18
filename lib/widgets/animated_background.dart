import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _orb1;
  late AnimationController _orb2;

  @override
  void initState() {
    super.initState();
    _orb1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _orb2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orb1.dispose();
    _orb2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050A14), Color(0xFF0A0F1E)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orb1,
          builder: (_, __) => Positioned(
            top: -80 + _orb1.value * 40,
            right: -60 + _orb1.value * 30,
            child: _Orb(
              size: 280,
              color: const Color(0xFF7B2FBE),
              opacity: 0.12 + _orb1.value * 0.06,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orb2,
          builder: (_, __) => Positioned(
            bottom: -60 + _orb2.value * 30,
            left: -40 + _orb2.value * 20,
            child: _Orb(
              size: 240,
              color: const Color(0xFF0066FF),
              opacity: 0.10 + _orb2.value * 0.05,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class ParticleOverlay extends StatefulWidget {
  final Widget child;

  const ParticleOverlay({super.key, required this.child});

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        r: _rand.nextDouble() * 2 + 1,
        speed: _rand.nextDouble() * 0.15 + 0.05,
        phase: _rand.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _ctrl.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _Particle {
  double x, y, r, speed, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = (p.y + (t + p.phase) * p.speed) % 1.0;
      paint.color = const Color(0xFF00B4FF).withValues(alpha: 0.25);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
