import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

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

class ShapeStrikeScreen extends StatefulWidget {
  const ShapeStrikeScreen({super.key});

  @override
  State<ShapeStrikeScreen> createState() => _ShapeStrikeScreenState();
}

class _ShapeStrikeScreenState extends State<ShapeStrikeScreen> {
  static const _gameId = 'shape_strike';
  static const _xpReward = 30;
  static const _gameName = 'Shape Strike';

  int _lives = 3;
  int _score = 0;
  int _correctInRow = 0;
  _ShapeType _targetShape = _ShapeType.circle;
  final List<_FallingShape> _shapes = [];
  bool _started = false;
  bool _gameEnded = false;
  Timer? _spawnTimer;
  Timer? _moveTimer;
  int _nextId = 0;
  final _rand = Random();
  double _fallSpeed = 0.006; // fraction per tick (50ms ticks)

  static const _shapeNames = {
    _ShapeType.circle: 'DAİRE',
    _ShapeType.triangle: 'ÜÇGEN',
    _ShapeType.square: 'KARE',
    _ShapeType.star: 'YİLDİZ',
  };

  static const _shapeColors = {
    _ShapeType.circle: Color(0xFF00B4FF),
    _ShapeType.triangle: Color(0xFF00C853),
    _ShapeType.square: Color(0xFFBB86FC),
    _ShapeType.star: Color(0xFFFDD835),
  };

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _targetShape = _ShapeType.values[_rand.nextInt(_ShapeType.values.length)];
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _gameEnded) return;
      final type =
          _ShapeType.values[_rand.nextInt(_ShapeType.values.length)];
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
        _shapes.removeWhere((s) => s.topFraction > 1.0);
      });
    });
  }

  void _tap(_FallingShape shape) {
    if (_gameEnded || !_started) return;
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
        setState(() => _gameEnded = true);
        _gameOver(_score);
      }
    }
  }

  Future<void> _gameOver(int score) async {
    final s = await StorageService.getInstance();
    final prevBest = s.arcadeBestScore(_gameId);
    final isNewBest = score > prevBest;
    await s.saveArcadeBestScore(_gameId, score);
    await s.saveXP(_xpReward);
    final newLevel = XpService.levelForXp(s.xp);
    await s.saveLevel(newLevel);
    await AchievementService.checkArcadeAchievements(_gameId, score, s);
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ArcadeResultOverlay(
        gameName: _gameName,
        score: score,
        bestScore: isNewBest ? score : prevBest,
        xpGained: _xpReward,
        isNewBest: isNewBest,
        onReplay: () {
          Navigator.pop(context);
          _restart();
        },
        onBack: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _restart() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    setState(() {
      _lives = 3;
      _score = 0;
      _correctInRow = 0;
      _shapes.clear();
      _started = false;
      _gameEnded = false;
      _nextId = 0;
      _fallSpeed = 0.006;
    });
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
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (i) => Text(i < _lives ? '❤️' : '🖤',
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_started) ...[
                const SizedBox(height: 8),
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
              ],
              Expanded(
                child: _started
                    ? LayoutBuilder(builder: (ctx, constraints) {
                        return Stack(
                          children: [
                            for (final s in List.from(_shapes))
                              Positioned(
                                left: s.x - 25,
                                top: s.topFraction * constraints.maxHeight - 25,
                                child: GestureDetector(
                                  onTap: () => _tap(s),
                                  child: _buildShape(s.type,
                                      _shapeColors[s.type]!),
                                ),
                              ),
                          ],
                        );
                      })
                    : Center(
                        child: GestureDetector(
                          onTap: _start,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B4FF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF00B4FF)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: const Text('BAŞLA',
                                style: TextStyle(
                                    color: Color(0xFF00B4FF),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Shape Strike',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
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
    final path = _starPath(size.width / 2, size.height / 2, 5, size.width / 2,
        size.width / 4);
    canvas.drawPath(path, paint);
    canvas.drawShadow(path, color, 8, false);
  }

  Path _starPath(double cx, double cy, int points, double outerR, double innerR) {
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
