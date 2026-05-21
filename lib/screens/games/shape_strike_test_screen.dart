// Full-test version of Shape Strike (Test 19/29).
// 30 seconds or until 3 lives gone.
// Target shapes that fall off screen cost 1 life; wrong taps cost 1 life.
// Score = clamp(correctTaps / 15 * 100, 0, 100).
// Mid-chain screen — navigates to MemoryFlashTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'memory_flash_test_screen.dart';

enum _ShapeType { circle, square, triangle, star }

class _FallingShape {
  final int id;
  final _ShapeType type;
  final double x;
  double topFraction;

  _FallingShape({
    required this.id,
    required this.type,
    required this.x,
    required this.topFraction,
  });
}

class ShapeStrikeTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;
  final int circleScore;
  final int laserScore;
  final int timingScore;
  final int pulseScore;
  final int balanceScore;
  final int dartScore;
  final int skyScore;
  final int targetLockScore;
  final int swipeDodgeScore;
  final int colorPanicScore;
  final int dontTapRedScore;
  final int tapTargetScore;

  const ShapeStrikeTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
    required this.patternScore,
    required this.circleScore,
    required this.laserScore,
    required this.timingScore,
    required this.pulseScore,
    required this.balanceScore,
    required this.dartScore,
    required this.skyScore,
    required this.targetLockScore,
    required this.swipeDodgeScore,
    required this.colorPanicScore,
    required this.dontTapRedScore,
    required this.tapTargetScore,
  });

  @override
  State<ShapeStrikeTestScreen> createState() => _SSTState();
}

class _SSTState extends State<ShapeStrikeTestScreen> {
  static const _maxScore = 15; // 15 correct taps = 100%
  static const _duration = 30;

  int _lives = 3;
  int _score = 0;
  int _correctInRow = 0;
  int _timeLeft = _duration;
  _ShapeType _targetShape = _ShapeType.circle;
  final List<_FallingShape> _shapes = [];
  bool _gameEnded = false;
  Timer? _spawnTimer;
  Timer? _moveTimer;
  Timer? _countdownTimer;
  int _nextId = 0;
  final _rand = Random();
  double _fallSpeed = 0.006;

  static const _shapeNames = {
    _ShapeType.circle:   'DAİRE',
    _ShapeType.triangle: 'ÜÇGEN',
    _ShapeType.square:   'KARE',
    _ShapeType.star:     'YİLDİZ',
  };

  static const _shapeColors = {
    _ShapeType.circle:   Color(0xFF00B4FF),
    _ShapeType.triangle: Color(0xFF00C853),
    _ShapeType.square:   Color(0xFFBB86FC),
    _ShapeType.star:     Color(0xFFFDD835),
  };

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _targetShape = _ShapeType.values[_rand.nextInt(_ShapeType.values.length)];
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameEnded) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _spawnTimer?.cancel();
        _moveTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() => _gameEnded = true);
        _finish();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _gameEnded) return;
      final type = _ShapeType.values[_rand.nextInt(_ShapeType.values.length)];
      setState(() {
        _shapes.add(_FallingShape(
          id: _nextId++,
          type: type,
          x: 30 + _rand.nextDouble() * 280,
          topFraction: 0.0,
        ));
      });
    });
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        for (final s in _shapes) {
          s.topFraction += _fallSpeed;
        }
        _lives -= _shapes.where(
            (s) => s.topFraction > 1.0 && s.type == _targetShape).length;
        _shapes.removeWhere((s) => s.topFraction > 1.0);
      });
      if (_lives <= 0 && !_gameEnded) {
        _spawnTimer?.cancel();
        _moveTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() => _gameEnded = true);
        _finish();
      }
    });
  }

  void _tap(_FallingShape shape) {
    if (_gameEnded) return;
    setState(() => _shapes.removeWhere((s) => s.id == shape.id));
    if (shape.type == _targetShape) {
      setState(() {
        _score++;
        _correctInRow++;
        _fallSpeed = (_fallSpeed + 0.0005).clamp(0.003, 0.02);
        if (_correctInRow % 5 == 0) {
          _targetShape =
              _ShapeType.values[_rand.nextInt(_ShapeType.values.length)];
        }
      });
    } else {
      setState(() => _lives--);
      if (_lives <= 0) {
        _spawnTimer?.cancel();
        _moveTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() => _gameEnded = true);
        _finish();
      }
    }
  }

  Future<void> _finish() async {
    final shapeStrikeScore = (_score / _maxScore * 100).round().clamp(0, 100);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryFlashTestScreen(
          session:          widget.session,
          reactionScore:    widget.reactionScore,
          stroopScore:      widget.stroopScore,
          memoryScore:      widget.memoryScore,
          sequenceScore:    widget.sequenceScore,
          impulseScore:     widget.impulseScore,
          patternScore:     widget.patternScore,
          circleScore:      widget.circleScore,
          laserScore:       widget.laserScore,
          timingScore:      widget.timingScore,
          pulseScore:       widget.pulseScore,
          balanceScore:     widget.balanceScore,
          dartScore:        widget.dartScore,
          skyScore:         widget.skyScore,
          targetLockScore:  widget.targetLockScore,
          swipeDodgeScore:  widget.swipeDodgeScore,
          colorPanicScore:  widget.colorPanicScore,
          dontTapRedScore:  widget.dontTapRedScore,
          tapTargetScore:   widget.tapTargetScore,
          shapeStrikeScore: shapeStrikeScore,
        ),
      ),
    );
  }

  Widget _buildShape(_ShapeType type, Color color) {
    if (type == _ShapeType.circle) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.85),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
        ),
      );
    } else if (type == _ShapeType.square) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
        ),
      );
    } else if (type == _ShapeType.triangle) {
      return CustomPaint(
        size: const Size(50, 50),
        painter: _TrianglePainter(color),
      );
    } else {
      return CustomPaint(
        size: const Size(50, 50),
        painter: _StarPainter(color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = _shapeColors[_targetShape]!;
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Progress header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Test 19 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _timeLeft / _duration,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFFFDD835),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_timeLeft s',
                        style: const TextStyle(
                            color: Color(0xFFFDD835), fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Shape Strike — Doğru şekle dokun!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Lives + score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3,
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 18))),
                    ),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Target indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sadece ',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  _buildShape(_targetShape, targetColor),
                  const Text(' dokun!',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(_shapeNames[_targetShape]!,
                      style: TextStyle(
                          color: targetColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              // Game area
              Expanded(
                child: LayoutBuilder(builder: (ctx, constraints) {
                  return Stack(
                    children: [
                      for (final s in List.from(_shapes))
                        Positioned(
                          left: s.x - 25,
                          top: s.topFraction * constraints.maxHeight - 25,
                          child: GestureDetector(
                            onTap: () => _tap(s),
                            child: _buildShape(s.type, _shapeColors[s.type]!),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
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
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawShadow(path, color, 8, false);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final path = _starPath(
        size.width / 2, size.height / 2, 5, size.width / 2, size.width / 4);
    canvas.drawPath(path, paint);
    canvas.drawShadow(path, color, 8, false);
  }

  Path _starPath(
      double cx, double cy, int points, double outerR, double innerR) {
    final path = Path();
    final step = pi / points;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * step - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}
