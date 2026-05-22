import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class BalanceBarScreen extends StatefulWidget {
  const BalanceBarScreen({super.key});

  @override
  State<BalanceBarScreen> createState() => _BalanceBarScreenState();
}

class _BalanceBarScreenState extends State<BalanceBarScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId = 'balance_bar';
  static const _xpReward = 25;
  static const _gameName = 'Balance Bar';

  late AnimationController _barCtrl;
  final _rand = Random();

  double _targetCenter = 0.5; // normalized 0..1
  double _zoneWidth = 0.2;
  int _round = 0;
  int _totalScore = 0;
  bool _canTap = true;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _gameEnded = false;

  double get _barPosition => _barCtrl.value; // 0..1 normalized

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400 + _rand.nextInt(600)),
    )..repeat(reverse: true);
    _newTarget();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  void _newTarget() {
    _targetCenter = 0.15 + _rand.nextDouble() * 0.7;
    _zoneWidth = 0.15 + _rand.nextDouble() * 0.1;
  }

  void _onTap() {
    if (!_canTap || _gameEnded) return;
    _canTap = false;
    _barCtrl.stop();

    final barPos = _barPosition;
    final zoneLeft = _targetCenter - _zoneWidth / 2;
    final zoneRight = _targetCenter + _zoneWidth / 2;
    final zoneCenter = _targetCenter;

    int points;
    String msg;
    Color color;

    final dist = (barPos - zoneCenter).abs();
    if (dist < _zoneWidth * 0.25) {
      // Center zone
      points = 100;
      msg = 'Mükemmel!';
      color = const Color(0xFF00C853);
    } else if (barPos >= zoneLeft && barPos <= zoneRight) {
      // Near zone
      points = 70;
      msg = 'Harika!';
      color = const Color(0xFF00B4FF);
    } else if (dist < 0.35) {
      // Outer zone
      points = 30;
      msg = 'Tamam';
      color = const Color(0xFFFDD835);
    } else {
      points = 0;
      msg = 'Kaçırdın';
      color = const Color(0xFFFF7043);
    }

    setState(() {
      _totalScore += points;
      _round++;
      _feedback = msg;
      _feedbackColor = color;
      _showFeedback = true;
    });

    if (_round >= 5) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _gameEnded = true);
          _gameOver(_totalScore);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _canTap = true;
          });
          _newTarget();
          // Speed increases with each round: 1400 → 1200 → 1000 → 800 → 600 ms
          final ms = (1400 - _round * 200).clamp(600, 1400);
          _barCtrl.duration = Duration(milliseconds: ms);
          _barCtrl.reset();
          _barCtrl.repeat(reverse: true);
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
    setState(() {
      _round = 0;
      _totalScore = 0;
      _canTap = true;
      _feedback = '';
      _showFeedback = false;
      _gameEnded = false;
    });
    _newTarget();
    _barCtrl.duration =
        Duration(milliseconds: 1400 + _rand.nextInt(600));
    _barCtrl.reset();
    _barCtrl.repeat(reverse: true);
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                        )
                      else
                        const Text(
                          'Yeşil bölgeye gir ve dokun!',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      const SizedBox(height: 24),
                      // Track
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final trackW = constraints.maxWidth;
                            final zoneLeft =
                                (_targetCenter - _zoneWidth / 2) * trackW;
                            final zoneW = _zoneWidth * trackW;

                            return Column(
                              children: [
                                // Target zone label
                                SizedBox(
                                  height: 24,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: zoneLeft,
                                        width: zoneW,
                                        top: 0,
                                        child: Center(
                                          child: Text(
                                            'HEDEF',
                                            style: TextStyle(
                                              color: const Color(0xFF00C853)
                                                  .withValues(alpha: 0.8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Track bar
                                SizedBox(
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      // Track bg
                                      Container(
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D1B2A),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.15)),
                                        ),
                                      ),
                                      // Target zone highlight
                                      Positioned(
                                        left: zoneLeft,
                                        width: zoneW,
                                        top: 22,
                                        height: 16,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853)
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: const Color(0xFF00C853)
                                                    .withValues(alpha: 0.6),
                                                width: 1.5),
                                          ),
                                        ),
                                      ),
                                      // Center tick
                                      Positioned(
                                        left: trackW / 2 - 1,
                                        top: 16,
                                        child: Container(
                                          width: 2,
                                          height: 28,
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      // Animated bar
                                      AnimatedBuilder(
                                        animation: _barCtrl,
                                        builder: (ctx, _) {
                                          final barLeft = max(
                                              0.0,
                                              min(
                                                  _barPosition * trackW - 30,
                                                  trackW - 60));
                                          return Positioned(
                                            left: barLeft,
                                            top: 20,
                                            child: Container(
                                              width: 60,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00B4FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: const Color(
                                                              0xFF00B4FF)
                                                          .withValues(
                                                              alpha: 0.6),
                                                      blurRadius: 12,
                                                      spreadRadius: 2)
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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
                        'Tur: ${_round.clamp(0, 5)}/5',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Puan: $_totalScore',
                        style: const TextStyle(
                            color: Color(0xFF00C853),
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
            child: Text('Balance Bar',
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
