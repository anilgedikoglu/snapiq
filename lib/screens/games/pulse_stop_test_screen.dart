// Full-test version of Pulse Stop (Test 10/10).
// 5 rounds, max 100 pts each → total max 500 → normalized to 0-100.
// Navigates to ResultScreen on completion.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../services/ad_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'balance_bar_test_screen.dart';

class PulseStopTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;
  final int circleScore;
  final int laserScore;
  final int timingScore;

  const PulseStopTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
    required this.patternScore,
    required this.circleScore,
    required this.laserScore,
    required this.timingScore,
  });

  @override
  State<PulseStopTestScreen> createState() => _PSTState();
}

class _PSTState extends State<PulseStopTestScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalRounds = 5;
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

  double get _currentR => _minR + _pulseCtrl.value * (_maxR - _minR);

  @override
  void initState() {
    super.initState();
    _targetR = _minR + _rand.nextDouble() * (_maxR - _minR);
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
      points = 100; msg = S.excellent; color = const Color(0xFF00C853);
    } else if (diff < 15) {
      points = 70;  msg = S.great;     color = const Color(0xFF00B4FF);
    } else if (diff < 30) {
      points = 40;  msg = S.good;      color = const Color(0xFFFDD835);
    } else if (diff < 50) {
      points = 15;  msg = S.okay;      color = const Color(0xFFFF7043);
    } else {
      points = 0;   msg = S.missed;    color = Colors.red;
    }

    setState(() {
      _totalScore += points;
      _round++;
      _feedback = msg;
      _feedbackColor = color;
      _showFeedback = true;
    });

    if (_round >= _totalRounds) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _gameEnded = true);
          _finish();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _targetR = _minR + _rand.nextDouble() * (_maxR - _minR);
            _canTap = true;
          });
          _pulseCtrl.duration =
              Duration(milliseconds: 600 + _rand.nextInt(800));
          _pulseCtrl.repeat(reverse: true);
        }
      });
    }
  }

  Future<void> _finish() async {
    final pulseScore = (_totalScore / 5).round().clamp(0, 100);

    await AdService().incrementGameCountAndMaybeShow();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BalanceBarTestScreen(
          session:       widget.session,
          reactionScore: widget.reactionScore,
          stroopScore:   widget.stroopScore,
          memoryScore:   widget.memoryScore,
          sequenceScore: widget.sequenceScore,
          impulseScore:  widget.impulseScore,
          patternScore:  widget.patternScore,
          circleScore:   widget.circleScore,
          laserScore:    widget.laserScore,
          timingScore:   widget.timingScore,
          pulseScore:    pulseScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // Test header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Test 10 / 29',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _round / _totalRounds,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            color: const Color(0xFFFDD835),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$_round/$_totalRounds',
                          style: const TextStyle(
                              color: Color(0xFFFDD835), fontSize: 13)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    S.pulseInstr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
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
                            color: const Color(0xFFFDD835)
                                .withValues(alpha: 0.5),
                            width: 2,
                          ),
                          color: const Color(0xFFFDD835)
                              .withValues(alpha: 0.05),
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
                                Shadow(
                                    color: _feedbackColor, blurRadius: 20)
                              ],
                            ),
                          ),
                        ),
                      if (_gameEnded)
                        Text(
                          S.done,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 16),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Text(
                    S.pulseTotal(_totalScore),
                    style: const TextStyle(
                        color: Color(0xFFFDD835),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
