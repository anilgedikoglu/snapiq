import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class _RainItem {
  final int id;
  final String emoji;
  final double x;
  double topFraction;

  _RainItem({
    required this.id,
    required this.emoji,
    required this.x,
    required this.topFraction,
  });
}

class TapRainScreen extends StatefulWidget {
  const TapRainScreen({super.key});

  @override
  State<TapRainScreen> createState() => _TapRainScreenState();
}

class _TapRainScreenState extends State<TapRainScreen> {
  static const _gameId = 'tap_rain';
  static const _xpReward = 25;
  static const _gameName = 'Tap Rain';

  static const _types = ['🍎', '🍊', '⭐', '🔵', '❌'];
  static const _changeTargetEvery = 8; // seconds

  int _timeLeft = 30;
  int _score = 0;
  int _lives = 3;
  String _targetType = '🍎';
  final List<_RainItem> _items = [];
  bool _started = false;
  bool _gameEnded = false;
  Timer? _countdownTimer;
  Timer? _spawnTimer;
  Timer? _moveTimer;
  Timer? _targetTimer;
  int _nextId = 0;
  final _rand = Random();
  static const double _fallSpeed = 0.006;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _targetType = _types[_rand.nextInt(_types.length - 1)]; // exclude ❌
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        _items.add(_RainItem(
          id: _nextId++,
          emoji: _types[_rand.nextInt(_types.length)],
          x: 20 + _rand.nextDouble() * 300,
          topFraction: 0.0,
        ));
      });
    });
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        for (final item in _items) {
          item.topFraction += _fallSpeed;
        }
        _items.removeWhere((item) => item.topFraction > 1.0);
      });
    });
    _targetTimer = Timer.periodic(
        Duration(seconds: _changeTargetEvery), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        _targetType = _types[_rand.nextInt(_types.length - 1)];
      });
    });
  }

  void _tap(_RainItem item) {
    if (_gameEnded || !_started) return;
    setState(() => _items.removeWhere((i) => i.id == item.id));
    if (item.emoji == _targetType) {
      setState(() => _score++);
    } else {
      setState(() => _lives--);
      if (_lives <= 0) {
        _endGame();
      }
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _targetTimer?.cancel();
    setState(() => _gameEnded = true);
    _gameOver(_score);
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
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _targetTimer?.cancel();
    setState(() {
      _timeLeft = 30;
      _score = 0;
      _lives = 3;
      _items.clear();
      _started = false;
      _gameEnded = false;
      _nextId = 0;
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
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('TAP: ',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 16)),
                    Text(_targetType,
                        style: const TextStyle(fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _timeLeft / 30.0,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF00B4FF)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$_timeLeft s',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
              Expanded(
                child: _started
                    ? LayoutBuilder(builder: (ctx, constraints) {
                        return Stack(
                          children: [
                            for (final item in List.from(_items))
                              Positioned(
                                left: item.x,
                                top: item.topFraction *
                                    constraints.maxHeight,
                                child: GestureDetector(
                                  onTap: () => _tap(item),
                                  child: Text(item.emoji,
                                      style: const TextStyle(fontSize: 30)),
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
            child: Text('Tap Rain',
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
