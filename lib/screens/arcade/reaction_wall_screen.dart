import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class _Wall {
  double y; // 0.0 to 1.0
  final int gapLane; // 0, 1, or 2
  bool scored = false;
  _Wall({required this.y, required this.gapLane});
}

class ReactionWallScreen extends StatefulWidget {
  const ReactionWallScreen({super.key});

  @override
  State<ReactionWallScreen> createState() => _ReactionWallScreenState();
}

class _ReactionWallScreenState extends State<ReactionWallScreen> {
  static const _gameId = 'reaction_wall';
  static const _xpReward = 25;
  static const _gameName = 'Reaction Wall';

  int _playerLane = 1;
  int _score = 0;
  int _lives = 3;
  final List<_Wall> _walls = [];
  bool _gameEnded = false;
  Timer? _moveTimer;
  Timer? _spawnTimer;
  final _rand = Random();
  double _wallSpeed = 0.008; // fraction per tick, ramps up as you score

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        _walls.add(_Wall(y: 0.0, gapLane: _rand.nextInt(3)));
      });
    });
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        for (final w in _walls) {
          w.y += _wallSpeed;
        }
        // Check scoring when wall passes player (y >= 0.88)
        for (final w in _walls) {
          if (!w.scored && w.y >= 0.88) {
            w.scored = true;
            _wallSpeed = (_wallSpeed + 0.0004).clamp(0.008, 0.026);
            if (w.gapLane == _playerLane) {
              _score++;
            } else {
              _lives--;
              if (_lives <= 0) {
                _endGame();
                return;
              }
            }
          }
        }
        _walls.removeWhere((w) => w.y > 1.1);
      });
    });
  }

  void _endGame() {
    if (_gameEnded) return;
    _moveTimer?.cancel();
    _spawnTimer?.cancel();
    setState(() => _gameEnded = true);
    _gameOver(_score);
  }

  void _moveLeft() {
    if (_gameEnded) return;
    setState(() => _playerLane = max(0, _playerLane - 1));
  }

  void _moveRight() {
    if (_gameEnded) return;
    setState(() => _playerLane = min(2, _playerLane + 1));
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
    _moveTimer?.cancel();
    _spawnTimer?.cancel();
    setState(() {
      _playerLane = 1;
      _score = 0;
      _lives = 3;
      _walls.clear();
      _gameEnded = false;
      _wallSpeed = 0.008;
    });
    _startTimers();
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: LayoutBuilder(builder: (ctx, constraints) {
                  final laneW = constraints.maxWidth / 3;
                  return Stack(
                    children: [
                      // Lane dividers
                      Positioned(
                        left: laneW,
                        top: 0,
                        bottom: 0,
                        child: Container(
                            width: 1,
                            color: Colors.white12),
                      ),
                      Positioned(
                        left: laneW * 2,
                        top: 0,
                        bottom: 0,
                        child: Container(
                            width: 1,
                            color: Colors.white12),
                      ),
                      // Walls
                      for (final w in List.from(_walls))
                        ..._buildWall(w, constraints.maxWidth,
                            constraints.maxHeight, laneW),
                      // Player
                      Positioned(
                        bottom: 20,
                        left: _playerLane * laneW + laneW / 2 - 20,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4FF),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF00B4FF)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 12)
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _moveLeft,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB86FC)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFBB86FC)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Center(
                            child: Text('←',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _moveRight,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB86FC)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFBB86FC)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Center(
                            child: Text('→',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28)),
                          ),
                        ),
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

  List<Widget> _buildWall(
      _Wall w, double totalW, double totalH, double laneW) {
    const wallH = 18.0;
    final top = w.y * totalH - wallH / 2;
    return [
      for (int lane = 0; lane < 3; lane++)
        if (lane != w.gapLane)
          Positioned(
            left: lane * laneW,
            top: top,
            child: Container(
              width: laneW - 1,
              height: wallH,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
    ];
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
            child: Text('Reaction Wall',
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
