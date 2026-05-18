import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class DontTapRedScreen extends StatefulWidget {
  const DontTapRedScreen({super.key});

  @override
  State<DontTapRedScreen> createState() => _DontTapRedScreenState();
}

class _DontTapRedScreenState extends State<DontTapRedScreen> {
  static const _gameId = 'dont_tap_red';
  static const _xpReward = 25;
  static const _gameName = "Don't Tap Red";

  static const _palette = [
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.red,
  ];

  int _lives = 3;
  int _score = 0;
  int _speed = 1200;
  List<Color> _grid = [];
  bool _started = false;
  bool _gameEnded = false;
  Timer? _autoTimer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateGrid();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _generateGrid() {
    _grid = List.generate(6, (_) => _palette[_rand.nextInt(_palette.length)]);
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer(Duration(milliseconds: _speed), () {
      if (!mounted || _gameEnded) return;
      // Time out — miss
      setState(() {
        if (_score > 0) _score--;
        _generateGrid();
        _startAutoTimer();
      });
    });
  }

  void _start() {
    setState(() => _started = true);
    _startAutoTimer();
  }

  void _tap(int index) {
    if (_gameEnded || !_started) return;
    _autoTimer?.cancel();
    final color = _grid[index];
    if (color == Colors.red) {
      setState(() {
        _lives--;
        _generateGrid();
      });
      if (_lives <= 0) {
        setState(() => _gameEnded = true);
        _gameOver(_score);
        return;
      }
    } else {
      setState(() {
        _score++;
        _speed = max(400, _speed - 40);
        _generateGrid();
      });
    }
    _startAutoTimer();
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
    _autoTimer?.cancel();
    setState(() {
      _lives = 3;
      _score = 0;
      _speed = 1200;
      _started = false;
      _gameEnded = false;
      _generateGrid();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (i) => Text(i < _lives ? '❤️' : '🖤',
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('KIRMIZIYA DOKUNMA!',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 20),
              Expanded(
                child: _started
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(6, (i) {
                            return GestureDetector(
                              onTap: () => _tap(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _grid[i].withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _grid[i].withValues(alpha: 0.4),
                                        blurRadius: 10)
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      )
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
            child: Text("Don't Tap Red",
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
