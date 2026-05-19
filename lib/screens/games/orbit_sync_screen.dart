import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';
import '../../painters/orbit_sync_painter.dart';

class OrbitSyncScreen extends StatefulWidget {
  const OrbitSyncScreen({super.key});

  @override
  State<OrbitSyncScreen> createState() => _OrbitSyncScreenState();
}

class _OrbitSyncScreenState extends State<OrbitSyncScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'orbit_sync';
  static const _xpReward = 40;
  static const _gameName = 'Orbit Sync';

  static const List<List<Color>> _ringColors = [
    [Color(0xFF00B4FF), Color(0xFFBB86FC)],
    [Color(0xFF03DAC6), Color(0xFFE91E63)],
    [Color(0xFF00C853), Color(0xFFFDD835)],
    [Color(0xFFFF7043), Color(0xFFFF7043)],
  ];

  // Speeds in radians per second for each ring
  static const List<double> _speeds = [0.25 * 2 * pi, -0.4 * 2 * pi, 0.6 * 2 * pi, -0.8 * 2 * pi];

  late List<AnimationController> _ringControllers;
  int _round = 0;
  int _totalScore = 0;
  bool _tapped = false;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _ringControllers = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      );
      ctrl.repeat();
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _ringControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _ringAngle(int i) {
    // Convert controller value (0..1) to angle in radians, with direction
    final value = _ringControllers[i].value;
    if (_speeds[i] >= 0) {
      return value * 2 * pi;
    } else {
      return (1 - value) * 2 * pi;
    }
  }

  int _countMatching() {
    int count = 0;
    for (int i = 0; i < 4; i++) {
      final angle = _ringAngle(i) % (2 * pi);
      // First color is "at top" if angle < pi (normalized)
      if (angle < pi) count++;
    }
    return count;
  }

  void _onTap() {
    if (_tapped || _gameEnded) return;
    _tapped = true;

    final matching = _countMatching();
    int points;
    String msg;
    Color color;

    if (matching == 4) {
      points = 100;
      msg = 'Mükemmel!';
      color = const Color(0xFF00C853);
    } else if (matching == 3) {
      points = 60;
      msg = 'Harika!';
      color = const Color(0xFF00B4FF);
    } else if (matching == 2) {
      points = 20;
      msg = 'Tamam';
      color = const Color(0xFFFDD835);
    } else {
      points = 0;
      msg = 'Kaçırdın';
      color = const Color(0xFFFF7043);
    }

    setState(() {
      _totalScore += points;
      _feedback = msg;
      _feedbackColor = color;
      _showFeedback = true;
      _round++;
    });

    if (_round >= 10) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _gameEnded = true);
          _gameOver(_totalScore);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _tapped = false;
          });
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
    for (final c in _ringControllers) {
      c.reset();
      c.repeat();
    }
    setState(() {
      _round = 0;
      _totalScore = 0;
      _tapped = false;
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
                        animation: Listenable.merge(_ringControllers),
                        builder: (ctx, _) {
                          return CustomPaint(
                            painter: OrbitSyncPainter(
                              angles: List.generate(4, _ringAngle),
                              ringColors: _ringColors,
                            ),
                            size: const Size(320, 320),
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
                            shadows: [Shadow(color: _feedbackColor, blurRadius: 20)],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Puan: $_totalScore',
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
                    "12'de aynı renkler hizalandığında dokun!",
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Orbit Sync',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFBB86FC).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_round.clamp(0, 10)}/10',
              style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
