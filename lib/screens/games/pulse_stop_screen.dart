import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class PulseStopScreen extends StatefulWidget {
  const PulseStopScreen({super.key});

  @override
  State<PulseStopScreen> createState() => _PulseStopScreenState();
}

class _PulseStopScreenState extends State<PulseStopScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId = 'pulse_stop';
  static const _xpReward = 25;
  static const _gameName = 'Pulse Stop';

  static const double _minR = 60;
  static const double _maxR = 200;

  late AnimationController _pulseCtrl;
  final _rand = Random();
  double _targetR = 130;
  int _round = 0;
  int _totalScore = 0;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _canTap = true;
  bool _gameEnded = false;

  double get _currentR => _minR + (_pulseCtrl.value) * (_maxR - _minR);

  @override
  void initState() {
    super.initState();
    _targetR = _minR + (_rand.nextDouble() * (_maxR - _minR));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800 + _rand.nextInt(600)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_canTap || _gameEnded) return;
    _canTap = false;
    _pulseCtrl.stop();

    final diff = (_currentR - _targetR).abs();
    int points;
    String msg;
    Color color;

    if (diff < 5) {
      points = 100;
      msg = 'Mükemmel!';
      color = const Color(0xFF00C853);
    } else if (diff < 15) {
      points = 70;
      msg = 'Harika!';
      color = const Color(0xFF00B4FF);
    } else if (diff < 30) {
      points = 40;
      msg = 'İyi';
      color = const Color(0xFFFDD835);
    } else if (diff < 50) {
      points = 15;
      msg = 'Tamam';
      color = const Color(0xFFFF7043);
    } else {
      points = 0;
      msg = 'Kaçırdın';
      color = Colors.red;
    }

    setState(() {
      _totalScore += points;
      _round++;
      _feedback = msg;
      _feedbackColor = color;
      _showFeedback = true;
    });

    if (_round >= 15) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _gameEnded = true);
          _gameOver(_totalScore);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _targetR = _minR + (_rand.nextDouble() * (_maxR - _minR));
            _canTap = true;
          });
          _pulseCtrl.duration =
              Duration(milliseconds: 600 + _rand.nextInt(800));
          _pulseCtrl.repeat(reverse: true);
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
      _targetR = _minR + (_rand.nextDouble() * (_maxR - _minR));
      _round = 0;
      _totalScore = 0;
      _feedback = '';
      _showFeedback = false;
      _canTap = true;
      _gameEnded = false;
    });
    _pulseCtrl.duration = Duration(milliseconds: 800 + _rand.nextInt(600));
    _pulseCtrl.repeat(reverse: true);
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
                      // Target zone ring
                      Container(
                        width: _targetR * 2,
                        height: _targetR * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFDD835).withValues(alpha: 0.5),
                            width: 2,
                          ),
                          color: const Color(0xFFFDD835).withValues(alpha: 0.05),
                        ),
                      ),
                      // Pulsing ring
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (ctx, _) {
                          final r = _currentR;
                          return Container(
                            width: r * 2,
                            height: r * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00B4FF),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00B4FF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      // Center dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      // Feedback
                      if (_showFeedback)
                        Positioned(
                          top: 30,
                          child: Text(
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
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tur: ${_round.clamp(0, 15)}/15',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Puan: $_totalScore',
                        style: const TextStyle(
                            color: Color(0xFFFDD835),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Halka sarı bölgeye girince dokun!',
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
            child: Text('Pulse Stop',
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
