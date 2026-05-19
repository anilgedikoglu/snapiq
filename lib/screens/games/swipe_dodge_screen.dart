import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class _Obstacle {
  double y; // 0=top, 1=bottom
  int gapLane; // 0,1,2

  _Obstacle({required this.y, required this.gapLane});
}

class SwipeDodgeScreen extends StatefulWidget {
  const SwipeDodgeScreen({super.key});

  @override
  State<SwipeDodgeScreen> createState() => _SwipeDodgeScreenState();
}

class _SwipeDodgeScreenState extends State<SwipeDodgeScreen> {
  static const _gameId = 'swipe_dodge';
  static const _xpReward = 30;
  static const _gameName = 'Swipe Dodge';

  final _rand = Random();
  int _lane = 1; // 0=left, 1=center, 2=right
  int _lives = 3;
  int _score = 0;
  List<_Obstacle> _obstacles = [];
  Timer? _spawnTimer;
  Timer? _moveTimer;
  double _speed = 0.008;
  bool _gameOver = false;
  bool _gameStarted = false;
  int _spawnIntervalMs = 2500;

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _gameStarted = true;
    _startTimers();
  }

  void _startTimers() {
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameOver) return;
      _tick();
    });
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: _spawnIntervalMs), () {
      if (!mounted || _gameOver) return;
      setState(() {
        _obstacles.add(_Obstacle(y: 0, gapLane: _rand.nextInt(3)));
      });
      _spawnIntervalMs = max(900, _spawnIntervalMs - 50);
      _scheduleNextSpawn();
    });
  }

  void _tick() {
    setState(() {
      _speed = 0.008 + (_score * 0.0002);
      final toRemove = <_Obstacle>[];
      for (final obs in _obstacles) {
        obs.y += _speed;
        if (obs.y >= 0.85) {
          // Check collision at bottom
          if (_lane != obs.gapLane) {
            _lives--;
            if (_lives <= 0) {
              _endGame();
              return;
            }
          } else {
            _score++;
          }
          toRemove.add(obs);
        }
      }
      _obstacles.removeWhere((o) => toRemove.contains(o));
    });
  }

  void _endGame() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    setState(() => _gameOver = true);
    _gameOverDialog(_score);
  }

  void _moveLeft() {
    if (_gameOver || !_gameStarted) return;
    setState(() => _lane = (_lane - 1).clamp(0, 2));
  }

  void _moveRight() {
    if (_gameOver || !_gameStarted) return;
    setState(() => _lane = (_lane + 1).clamp(0, 2));
  }

  Future<void> _gameOverDialog(int score) async {
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
      _lane = 1;
      _lives = 3;
      _score = 0;
      _obstacles = [];
      _speed = 0.008;
      _gameOver = false;
      _gameStarted = false;
      _spawnIntervalMs = 2500;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
                            left: laneW,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          Positioned(
                            left: laneW * 2,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
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
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853)
                                    .withValues(alpha: 0.25),
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
                          // Start overlay
                          if (!_gameStarted)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _startGame,
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C853)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFF00C853)
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('BAŞLA',
                                              style: TextStyle(
                                                  color: Color(0xFF00C853),
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          SizedBox(height: 8),
                                          Text('Sola/Sağa kaydır',
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Control buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _moveLeft,
                      child: Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  const Color(0xFF00B4FF).withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_left,
                            color: Color(0xFF00B4FF), size: 32),
                      ),
                    ),
                    Row(
                      children: List.generate(
                          3,
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 20))),
                    ),
                    GestureDetector(
                      onTap: _moveRight,
                      child: Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  const Color(0xFF00B4FF).withValues(alpha: 0.5)),
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
            child: Text('Swipe Dodge',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'Skor: $_score',
              style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
