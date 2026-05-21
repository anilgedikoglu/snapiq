import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class _Target {
  final int id;
  double x;
  double y;
  double radius;
  final bool isDecoy;
  _Target(
      {required this.id,
      required this.x,
      required this.y,
      required this.radius,
      required this.isDecoy});
}

class TapTargetScreen extends StatefulWidget {
  const TapTargetScreen({super.key});

  @override
  State<TapTargetScreen> createState() => _TapTargetScreenState();
}

class _TapTargetScreenState extends State<TapTargetScreen> {
  static const _gameId = 'tap_target';
  static const _xpReward = 25;
  static const _gameName = 'Tap Target';

  int _timeLeft = 30;
  int _score = 0;
  final List<_Target> _targets = [];
  bool _gameEnded = false;
  Timer? _countdownTimer;
  Timer? _spawnTimer;
  Timer? _despawnTimer;
  int _nextId = 0;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _despawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _countdownTimer?.cancel();
        _spawnTimer?.cancel();
        _despawnTimer?.cancel();
        _endGame();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      _spawnTarget();
    });
    _despawnTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _targets.removeWhere((t) => t.radius <= 0);
      });
    });
  }

  void _spawnTarget() {
    final isDecoy = _rand.nextDouble() < 0.3;
    final id = _nextId++;
    final target = _Target(
      id: id,
      x: 30 + _rand.nextDouble() * 280,
      y: 80 + _rand.nextDouble() * 420,
      radius: 35,
      isDecoy: isDecoy,
    );
    setState(() => _targets.add(target));
    // Auto-despawn after 1.5s
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _targets.removeWhere((t) => t.id == id));
    });
  }

  void _tapTarget(_Target t) {
    if (_gameEnded) return;
    setState(() {
      _targets.removeWhere((item) => item.id == t.id);
      if (!t.isDecoy) {
        _score++;
      } else {
        if (_score > 0) _score--;
      }
    });
  }

  void _endGame() {
    if (_gameEnded) return;
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
    _despawnTimer?.cancel();
    setState(() {
      _timeLeft = 30;
      _score = 0;
      _targets.clear();
      _gameEnded = false;
      _nextId = 0;
    });
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _timeLeft / 30.0;
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              const Color(0xFF00B4FF).withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF00B4FF)),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_timeLeft s',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 16),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    for (final t in List.from(_targets))
                      Positioned(
                        left: t.x - t.radius,
                        top: t.y - t.radius,
                        child: GestureDetector(
                          onTap: () => _tapTarget(t),
                          child: t.isDecoy
                              ? Container(
                                  width: t.radius * 2,
                                  height: t.radius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withValues(alpha: 0.85),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.5),
                                          blurRadius: 10)
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text('✗',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                )
                              : Container(
                                  width: t.radius * 2,
                                  height: t.radius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00C853)
                                        .withValues(alpha: 0.85),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFF00C853)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 14)
                                    ],
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
            child: Text('Tap Target',
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
