import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';
import '../../painters/laser_gate_painter.dart';

class LaserGateScreen extends StatefulWidget {
  const LaserGateScreen({super.key});

  @override
  State<LaserGateScreen> createState() => _LaserGateScreenState();
}

class _LaserGateScreenState extends State<LaserGateScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'laser_gate';
  static const _xpReward = 40;
  static const _gameName = 'Laser Gate';

  // Speeds in rad/sec
  List<double> _ringSpeed = [1.2, -1.8, 2.5];
  late List<AnimationController> _ringCtrl;
  int _ballRing = 0; // 0=center, 1,2,3 = past ring i
  int _lives = 3;
  int _score = 0;
  bool _canTap = true;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _gameEnded = false;

  static const double _tolerance = 25 * pi / 180;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _ringCtrl = List.generate(3, (i) {
      final speed = _ringSpeed[i].abs();
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (2000 / speed).round()),
      );
      ctrl.repeat();
      return ctrl;
    });
  }

  double _ringAngle(int i) {
    final value = _ringCtrl[i].value;
    return _ringSpeed[i] >= 0 ? value * 2 * pi : (1 - value) * 2 * pi;
  }

  bool _isGapAtTop(int ringIndex) {
    final angle = _ringAngle(ringIndex) % (2 * pi);
    // Gap center is at angle position; gap is 60 deg wide.
    // Gap "at top" means angle is near 0 (12 o'clock, i.e., -pi/2 in standard coords)
    // We define gap center as the angle position for the gap start
    // In painter: gap starts at angle - pi/2 - gapAngle/2
    // Gap is at top when gap center ≈ 0 (our coordinate), meaning angle ≈ 0
    final diff = (angle).abs();
    final diff2 = (angle - 2 * pi).abs();
    return (diff < _tolerance || diff2 < _tolerance);
  }

  void _onTap() {
    if (!_canTap || _gameEnded || _ballRing >= 3) return;
    _canTap = false;

    final targetRing = _ballRing; // which ring to pass through
    if (_isGapAtTop(targetRing)) {
      // Pass!
      setState(() {
        _ballRing++;
        _feedback = 'Geçti!';
        _feedbackColor = const Color(0xFF00C853);
        _showFeedback = true;
      });

      if (_ballRing >= 3) {
        // All 3 rings passed
        _score++;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _ballRing = 0;
              _showFeedback = false;
              _canTap = true;
              // Speed up
              _ringSpeed = _ringSpeed
                  .map((s) => s * (s >= 0 ? 1.15 : -1.15))
                  .toList();
              for (final c in _ringCtrl) {
                c.dispose();
              }
              _initControllers();
            });
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _showFeedback = false;
              _canTap = true;
            });
          }
        });
      }
    } else {
      // Hit!
      setState(() {
        _lives--;
        _feedback = 'Vuruldu!';
        _feedbackColor = const Color(0xFFFF7043);
        _showFeedback = true;
        _ballRing = 0;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _canTap = true;
          });
          if (_lives <= 0) {
            setState(() => _gameEnded = true);
            _gameOver(_score);
          }
        }
      });
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
    for (final c in _ringCtrl) {
      c.dispose();
    }
    _ringSpeed = [1.2, -1.8, 2.5];
    _initControllers();
    setState(() {
      _ballRing = 0;
      _lives = 3;
      _score = 0;
      _canTap = true;
      _feedback = '';
      _showFeedback = false;
      _gameEnded = false;
    });
  }

  @override
  void dispose() {
    for (final c in _ringCtrl) {
      c.dispose();
    }
    super.dispose();
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
                        animation: Listenable.merge(_ringCtrl),
                        builder: (ctx, _) {
                          return CustomPaint(
                            painter: LaserGatePainter(
                              angles: List.generate(3, _ringAngle),
                              ballRing: _ballRing,
                              lives: _lives,
                              score: _score,
                            ),
                            size: const Size(400, 400),
                          );
                        },
                      ),
                      if (_showFeedback)
                        Text(
                          _feedback,
                          style: TextStyle(
                            color: _feedbackColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: _feedbackColor, blurRadius: 20)
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          3,
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      Text(
                        'Skor: $_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Boşluk 12\'de iken dokun!',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
            child: Text('Laser Gate',
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
