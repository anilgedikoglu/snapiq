import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class SkyShotScreen extends StatefulWidget {
  const SkyShotScreen({super.key});

  @override
  State<SkyShotScreen> createState() => _SkyShotScreenState();
}

class _SkyShotScreenState extends State<SkyShotScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'sky_shot';
  static const _xpReward = 30;
  static const _gameName = 'Sky Shot';

  late AnimationController _targetCtrl;
  AnimationController? _projectileCtrl;

  int _shotsLeft = 5;
  int _totalScore = 0;
  List<int> _shotScores = [];
  bool _canShoot = true;
  bool _gameEnded = false;
  int _lastShotScore = 0;
  bool _showLastScore = false;
  double _capturedTargetX = 0.5; // target x when shot was fired

  // Speed increases with each shot
  Duration get _targetSpeed =>
      Duration(milliseconds: 2400 - (_shotScores.length * 200).clamp(0, 1600));

  @override
  void initState() {
    super.initState();
    _targetCtrl = AnimationController(vsync: this, duration: _targetSpeed)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _projectileCtrl?.dispose();
    super.dispose();
  }

  void _shoot() {
    if (!_canShoot || _gameEnded) return;
    _canShoot = false;
    _capturedTargetX = _targetCtrl.value;

    _projectileCtrl?.dispose();
    _projectileCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _projectileCtrl!.addListener(() {
      if (mounted) setState(() {});
    });

    _projectileCtrl!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Calculate score based on horizontal distance
        final dx = (_capturedTargetX - 0.5).abs(); // 0 = center, 0.5 = edge
        int score;
        if (dx < 0.05) {
          score = 100;
        } else if (dx < 0.10) {
          score = 70;
        } else if (dx < 0.20) {
          score = 40;
        } else if (dx < 0.35) {
          score = 15;
        } else {
          score = 0;
        }

        if (mounted) {
          setState(() {
            _totalScore += score;
            _shotScores.add(score);
            _lastShotScore = score;
            _showLastScore = true;
            _shotsLeft--;
            _canShoot = true;
          });

          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _showLastScore = false);
          });

          if (_shotsLeft <= 0) {
            setState(() => _gameEnded = true);
            _gameOver(_totalScore);
          } else {
            // Update target speed
            _targetCtrl.duration = _targetSpeed;
            _targetCtrl.repeat(reverse: true);
          }
        }
      }
    });

    _projectileCtrl!.forward();
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
    _projectileCtrl?.dispose();
    _projectileCtrl = null;
    _targetCtrl.duration = const Duration(milliseconds: 2400);
    _targetCtrl.repeat(reverse: true);
    setState(() {
      _shotsLeft = 5;
      _totalScore = 0;
      _shotScores = [];
      _canShoot = true;
      _gameEnded = false;
      _lastShotScore = 0;
      _showLastScore = false;
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
                  onTap: _shoot,
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      // Target x position (0..1 normalized)
                      final targetX = _targetCtrl.value * (w - 60);
                      // Projectile y (0=top, 1=bottom) during flight
                      final projY = _projectileCtrl != null
                          ? h - (h * 0.9 * _projectileCtrl!.value) - 30
                          : h - 50.0;

                      return Stack(
                        children: [
                          // Target UFO at top
                          Positioned(
                            left: targetX,
                            top: h * 0.08,
                            child: Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4FF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: const Color(0xFF00B4FF), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF00B4FF)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12)
                                ],
                              ),
                              child: const Center(
                                child: Text('🛸',
                                    style: TextStyle(fontSize: 22)),
                              ),
                            ),
                          ),
                          // Projectile
                          if (_projectileCtrl != null &&
                              _projectileCtrl!.isAnimating)
                            Positioned(
                              left: w / 2 - 4,
                              top: projY,
                              child: Container(
                                width: 8,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDD835),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFFDD835)
                                            .withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2)
                                  ],
                                ),
                              ),
                            ),
                          // Cannon at bottom
                          Positioned(
                            bottom: 16,
                            left: w / 2 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF00C853), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF00C853)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10)
                                ],
                              ),
                              child: const Icon(Icons.arrow_upward,
                                  color: Color(0xFF00C853), size: 22),
                            ),
                          ),
                          // Score popup
                          if (_showLastScore)
                            Center(
                              child: Text(
                                '+$_lastShotScore',
                                style: TextStyle(
                                  color: _lastShotScore > 60
                                      ? const Color(0xFF00C853)
                                      : _lastShotScore > 30
                                          ? const Color(0xFFFDD835)
                                          : const Color(0xFFFF7043),
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                        color: Colors.black45, blurRadius: 8)
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                          5,
                          (i) => Text(
                              i < _shotsLeft ? '🚀' : '⭕',
                              style: const TextStyle(fontSize: 16))),
                    ),
                    Text(
                      'Puan: $_totalScore',
                      style: const TextStyle(
                          color: Color(0xFF00B4FF),
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
            child: Text('Sky Shot',
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
