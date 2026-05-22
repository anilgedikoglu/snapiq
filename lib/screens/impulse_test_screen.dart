import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import '../l10n/app_strings.dart';
import 'pattern_test_screen.dart';

class ImpulseTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;

  const ImpulseTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
  });

  @override
  State<ImpulseTestScreen> createState() => _ImpulseTestScreenState();
}

class _ImpulseTestScreenState extends State<ImpulseTestScreen> {
  static const _shapes = ['daire', 'kare', 'üçgen', 'yıldız'];
  static const _totalShapes = 10;
  static const _circleCount = 4;

  List<String> _sequence = [];
  int _current = -1;
  bool _showing = false;
  Timer? _showTimer;
  int _score = 100;
  bool _tapped = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _buildSequence();
    Future.delayed(const Duration(milliseconds: 600), _nextShape);
  }

  void _buildSequence() {
    final r = Random();
    final List<String> seq = [];
    final circles = List.filled(_circleCount, 'daire');
    final others = List.generate(
        _totalShapes - _circleCount,
        (_) => _shapes.skip(1).toList()[r.nextInt(_shapes.length - 1)]);
    seq.addAll(circles);
    seq.addAll(others);
    seq.shuffle(r);
    _sequence = seq;
  }

  void _nextShape() async {
    if (_current + 1 >= _totalShapes) {
      _finish();
      return;
    }
    _current++;
    _tapped = false;
    setState(() => _showing = true);

    _showTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      // If it was a circle and user didn't tap → missed
      if (_sequence[_current] == 'daire' && !_tapped) {
        setState(() => _score = (_score - 10).clamp(0, 100));
      }
      setState(() => _showing = false);
      Future.delayed(const Duration(milliseconds: 200), _nextShape);
    });
  }

  void _onTap() {
    if (!_showing || _done) return;
    _tapped = true;
    if (_sequence[_current] == 'daire') {
      // correct
      HapticFeedback.selectionClick();
      setState(() => _score = (_score + 25).clamp(0, 100));
    } else {
      // wrong
      HapticFeedback.mediumImpact();
      setState(() => _score = (_score - 20).clamp(0, 100));
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatternTestScreen(
            session: widget.session,
            reactionScore: widget.reactionScore,
            stroopScore: widget.stroopScore,
            memoryScore: widget.memoryScore,
            sequenceScore: widget.sequenceScore,
            impulseScore: _score,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    super.dispose();
  }

  Widget _buildShape(String shape, double size) {
    final color = const Color(0xFF00B4FF);
    switch (shape) {
      case 'daire':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.4), blurRadius: 20)
            ],
          ),
        );
      case 'kare':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFBB86FC).withValues(alpha: 0.2),
            border: Border.all(color: const Color(0xFFBB86FC), width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case 'üçgen':
        return CustomPaint(
          size: Size(size, size),
          painter: _TrianglePainter(const Color(0xFF03DAC6)),
        );
      case 'yıldız':
        return CustomPaint(
          size: Size(size, size),
          painter: _StarPainter(Colors.amber),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _current < 0 ? 0.0 : (_current + 1) / _totalShapes;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              const SizedBox(height: 8),
              Text(
                S.impulseInstruction,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      const Color(0xFF00B4FF).withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00B4FF)),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_current < 0 ? 0 : _current + 1} / $_totalShapes',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
              // Score
              Text(
                S.impulseScore(_score),
                style: const TextStyle(
                    color: Color(0xFF00B4FF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _onTap,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _showing && _current >= 0
                          ? _buildShape(_sequence[_current], 130)
                          : const SizedBox(width: 130, height: 130),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _showing && _current >= 0
                    ? Text(
                        S.shapeDisplay(_sequence[_current]),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      )
                    : const SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.touch_app, color: Color(0xFF00B4FF), size: 18),
          const SizedBox(width: 6),
          const Text('Test 5/6',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(S.impulseTestLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const n = 5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.4;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = (i * pi / n) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
