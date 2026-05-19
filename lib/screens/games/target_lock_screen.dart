import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';
import '../../painters/radar_painter.dart';

class TargetLockScreen extends StatefulWidget {
  const TargetLockScreen({super.key});

  @override
  State<TargetLockScreen> createState() => _TargetLockScreenState();
}

class _TargetLockScreenState extends State<TargetLockScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId = 'target_lock';
  static const _xpReward = 35;
  static const _gameName = 'Target Lock';
  static const _totalToLock = 10;
  static const _tolerance = 15 * pi / 180; // 15 degrees

  late AnimationController _sweepCtrl;
  final _rand = Random();

  List<double> _targetAngles = [];
  List<bool> _targetLocked = [];
  int _totalLocked = 0;
  int _totalScore = 0;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _gameEnded = false;
  double _sweepSpeed = 1.0; // rotations/sec

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / _sweepSpeed).round()),
    )..repeat();
    _spawnTargets();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  void _spawnTargets() {
    _targetAngles = List.generate(3, (_) => _rand.nextDouble() * 2 * pi);
    _targetLocked = List.filled(3, false);
  }

  double get _currentSweepAngle => _sweepCtrl.value * 2 * pi;

  void _onTap() {
    if (_gameEnded) return;

    bool lockedAny = false;
    for (int i = 0; i < _targetAngles.length; i++) {
      if (_targetLocked[i]) continue;
      final diff = (_currentSweepAngle - _targetAngles[i]).abs();
      final minDiff = min(diff, (2 * pi - diff).abs());
      if (minDiff <= _tolerance) {
        setState(() {
          _targetLocked[i] = true;
          _totalLocked++;
          lockedAny = true;
        });

        final accuracyScore = (100 * (1 - minDiff / _tolerance)).round().clamp(0, 100);
        setState(() {
          _totalScore += accuracyScore;
          _feedback = '+$accuracyScore';
          _feedbackColor = const Color(0xFF00C853);
          _showFeedback = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _showFeedback = false);
        });
        break;
      }
    }

    if (!lockedAny) {
      setState(() {
        _feedback = 'Kaçırdın';
        _feedbackColor = const Color(0xFFFF7043);
        _showFeedback = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showFeedback = false);
      });
    }

    // Check if all locked
    if (_targetLocked.every((l) => l)) {
      if (_totalLocked >= _totalToLock) {
        setState(() => _gameEnded = true);
        _gameOver(_totalScore);
      } else {
        // New round, speed up
        _sweepSpeed += 0.3;
        _sweepCtrl.duration = Duration(milliseconds: (1000 / _sweepSpeed).round());
        _sweepCtrl.reset();
        _sweepCtrl.repeat();
        _spawnTargets();
        setState(() {});
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
    _sweepSpeed = 1.0;
    _sweepCtrl.duration = const Duration(milliseconds: 1000);
    _sweepCtrl.reset();
    _sweepCtrl.repeat();
    _spawnTargets();
    setState(() {
      _totalLocked = 0;
      _totalScore = 0;
      _feedback = '';
      _showFeedback = false;
      _gameEnded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _sweepCtrl,
                        builder: (ctx, _) {
                          return CustomPaint(
                            painter: RadarPainter(
                              sweepAngle: _currentSweepAngle,
                              targetAngles: _targetAngles,
                              targetLocked: _targetLocked,
                            ),
                            size: const Size(300, 300),
                          );
                        },
                      ),
                      if (_showFeedback)
                        Positioned(
                          top: 20,
                          child: Text(
                            _feedback,
                            style: TextStyle(
                              color: _feedbackColor,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: _feedbackColor, blurRadius: 16)
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kilitli: $_totalLocked/$_totalToLock',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Puan: $_totalScore',
                        style: const TextStyle(
                            color: Color(0xFFBB86FC),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            child: Text('Target Lock',
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
