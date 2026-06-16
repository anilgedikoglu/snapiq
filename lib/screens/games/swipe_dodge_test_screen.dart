// Full-test version of Swipe Dodge (Test 15/16).
// 15 obstacles, 3 lives. Score = dodged/15 * 100.
// Navigates to ColorPanicTestScreen on completion.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'color_panic_test_screen.dart';

class _Obstacle {
  double y;
  int gapLane;
  _Obstacle({required this.y, required this.gapLane});
}

class SwipeDodgeTestScreen extends StatefulWidget {
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

  const SwipeDodgeTestScreen({
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
  });

  @override
  State<SwipeDodgeTestScreen> createState() => _SDTState();
}

class _SDTState extends State<SwipeDodgeTestScreen> {
  static const _totalObstacles = 15;

  final _rand = Random();

  int _lane = 1; // 0=left 1=center 2=right
  int _lives = 3;
  int _dodged = 0;
  int _spawned = 0;
  final List<_Obstacle> _obstacles = [];
  Timer? _spawnTimer;
  Timer? _moveTimer;
  double _speed = 0.010;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameOver) return;
      _tick();
    });
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    if (_spawned >= _totalObstacles) return;
    _spawnTimer?.cancel();
    final interval = max(800, 2200 - _spawned * 60);
    _spawnTimer = Timer(Duration(milliseconds: interval), () {
      if (!mounted || _gameOver) return;
      if (_spawned < _totalObstacles) {
        setState(() {
          _obstacles.add(_Obstacle(y: 0, gapLane: _rand.nextInt(3)));
          _spawned++;
        });
      }
      _scheduleNextSpawn();
    });
  }

  void _tick() {
    setState(() {
      // Ramps steadily as the round progresses (by obstacles spawned),
      // so the fall speed gradually increases over time.
      _speed = (0.008 + _spawned * 0.00035).clamp(0.008, 0.022);
      final toRemove = <_Obstacle>[];
      for (final obs in _obstacles) {
        obs.y += _speed;
        if (obs.y >= 0.85) {
          if (_lane != obs.gapLane) {
            _lives--;
            if (_lives <= 0) {
              _lives = 0;
              toRemove.add(obs);
              _obstacles.removeWhere((o) => toRemove.contains(o));
              _endGame();
              return;
            }
          } else {
            _dodged++;
          }
          toRemove.add(obs);
        }
      }
      _obstacles.removeWhere((o) => toRemove.contains(o));

      // All spawned obstacles processed?
      if (_spawned >= _totalObstacles && _obstacles.isEmpty) {
        _endGame();
      }
    });
  }

  void _endGame() {
    if (_gameOver) return;
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    setState(() => _gameOver = true);
    _finish();
  }

  void _moveLeft() {
    if (_gameOver) return;
    setState(() => _lane = (_lane - 1).clamp(0, 2));
  }

  void _moveRight() {
    if (_gameOver) return;
    setState(() => _lane = (_lane + 1).clamp(0, 2));
  }

  Future<void> _finish() async {
    final swipeDodgeScore = (_dodged / _totalObstacles * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ColorPanicTestScreen(
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
          swipeDodgeScore:  swipeDodgeScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('Test 15 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_spawned - _obstacles.length) / _totalObstacles,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFFE91E63),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_dodged/$_totalObstacles',
                        style: const TextStyle(
                            color: Color(0xFFE91E63), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.swipeInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Game area
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity! < 0) {
                      _moveLeft();
                    } else {
                      _moveRight();
                    }
                  },
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final laneW = w / 3;
                      final playerX = _lane * laneW + laneW / 2 - 25;

                      return Stack(
                        children: [
                          // Lane dividers
                          Positioned(
                            left: laneW, top: 0, bottom: 0,
                            child: Container(width: 1,
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          Positioned(
                            left: laneW * 2, top: 0, bottom: 0,
                            child: Container(width: 1,
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          // Obstacles
                          ..._obstacles.map((obs) {
                            return Positioned(
                              top: obs.y * h - 6,
                              left: 0,
                              right: 0,
                              child: Row(
                                children: List.generate(3, (i) {
                                  final isGap = i == obs.gapLane;
                                  return Container(
                                    width: laneW,
                                    height: 12,
                                    color: isGap
                                        ? Colors.transparent
                                        : const Color(0xFFE91E63)
                                            .withValues(alpha: 0.85),
                                  );
                                }),
                              ),
                            );
                          }),
                          // Player
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 150),
                            left: playerX,
                            bottom: 60,
                            child: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF00C853), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF00C853)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12)
                                ],
                              ),
                              child: const Icon(Icons.person,
                                  color: Color(0xFF00C853), size: 28),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Controls + lives
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _moveLeft,
                      child: Container(
                        width: 80, height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00B4FF).withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_left,
                            color: Color(0xFF00B4FF), size: 32),
                      ),
                    ),
                    Row(
                      children: List.generate(3,
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 20))),
                    ),
                    GestureDetector(
                      onTap: _moveRight,
                      child: Container(
                        width: 80, height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00B4FF).withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_right,
                            color: Color(0xFF00B4FF), size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
