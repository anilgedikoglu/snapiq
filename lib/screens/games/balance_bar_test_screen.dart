// Full-test version of Balance Bar (Test 11/12).
// 5 rounds, speed increases each round. score = (total/5).clamp(0,100).
// Navigates to DartFocusTestScreen on completion.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../services/ad_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'dart_focus_test_screen.dart';

class BalanceBarTestScreen extends StatefulWidget {
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
  final int pulseScore;

  const BalanceBarTestScreen({
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
    required this.pulseScore,
  });

  @override
  State<BalanceBarTestScreen> createState() => _BBTState();
}

class _BBTState extends State<BalanceBarTestScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalRounds = 5;

  late AnimationController _barCtrl;
  final _rand = Random();

  double _targetCenter = 0.5;
  double _zoneWidth    = 0.2;
  int    _round        = 0;
  int    _totalScore   = 0;
  bool   _canTap       = true;
  String _feedback     = '';
  Color  _feedbackColor = Colors.white;
  bool   _showFeedback  = false;
  bool   _gameEnded     = false;

  double get _barPosition => _barCtrl.value;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    _zoneWidth    = 0.15 + _rand.nextDouble() * 0.1;
  }

  void _onTap() {
    if (!_canTap || _gameEnded) return;
    _canTap = false;
    _barCtrl.stop();

    final barPos    = _barPosition;
    final zoneLeft  = _targetCenter - _zoneWidth / 2;
    final zoneRight = _targetCenter + _zoneWidth / 2;
    final dist      = (barPos - _targetCenter).abs();

    int points;
    String msg;
    Color color;

    if (dist < _zoneWidth * 0.25) {
      points = 100; msg = S.excellent; color = const Color(0xFF00C853);
    } else if (barPos >= zoneLeft && barPos <= zoneRight) {
      points = 70;  msg = S.great;     color = const Color(0xFF00B4FF);
    } else if (dist < 0.35) {
      points = 30;  msg = S.okay;      color = const Color(0xFFFDD835);
    } else {
      points = 0;   msg = S.missed;    color = const Color(0xFFFF7043);
    }

    setState(() {
      _totalScore += points;
      _round++;
      _feedback      = msg;
      _feedbackColor = color;
      _showFeedback  = true;
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
          setState(() { _showFeedback = false; _canTap = true; });
          _newTarget();
          // Speed increases each round: 1400→1200→1000→800→600 ms
          final ms = (1400 - _round * 200).clamp(600, 1400);
          _barCtrl.duration = Duration(milliseconds: ms);
          _barCtrl.reset();
          _barCtrl.repeat(reverse: true);
        }
      });
    }
  }

  Future<void> _finish() async {
    final balanceScore = (_totalScore / 5).round().clamp(0, 100);

    await AdService().incrementGameCountAndMaybeShow();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DartFocusTestScreen(
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
          pulseScore:    widget.pulseScore,
          balanceScore:  balanceScore,
        ),
      ),
    );
  }

  // Live "ruler" showing how far the bar is from the target centre.
  Widget _buildDeviationMeter() {
    return AnimatedBuilder(
      animation: _barCtrl,
      builder: (ctx, _) {
        final dev = _barPosition - _targetCenter; // - = left, + = right
        final pct = (dev * 100).round();
        final mag = pct.abs();
        final label = mag <= 1 ? '0%' : (dev < 0 ? '< $mag%' : '$mag% >');
        final color = mag <= 4
            ? const Color(0xFF00C853)
            : mag <= 12
                ? const Color(0xFFFDD835)
                : const Color(0xFFFF7043);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              LayoutBuilder(builder: (c, cons) {
                final w = cons.maxWidth;
                final nx =
                    (w / 2) + (dev / 0.5).clamp(-1.0, 1.0) * (w / 2 - 6);
                return SizedBox(
                  height: 18,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 2, color: Colors.white24),
                      Container(width: 2, height: 14, color: Colors.white38),
                      Positioned(
                        left: nx - 5,
                        child: Container(
                          width: 10,
                          height: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
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
                      Text('Test 11 / 29',
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
                            color: const Color(0xFF00C853),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$_round/$_totalRounds',
                          style: const TextStyle(
                              color: Color(0xFF00C853), fontSize: 13)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    S.balanceInstr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                _buildDeviationMeter(),
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
                              Shadow(
                                  color: _feedbackColor, blurRadius: 20)
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 36),
                      const SizedBox(height: 24),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final trackW = constraints.maxWidth;
                            final zoneLeft =
                                (_targetCenter - _zoneWidth / 2) * trackW;
                            final zoneW = _zoneWidth * trackW;
                            return Column(
                              children: [
                                SizedBox(
                                  height: 24,
                                  child: Stack(children: [
                                    Positioned(
                                      left: zoneLeft,
                                      width: zoneW,
                                      top: 0,
                                      child: Center(
                                        child: Text(S.target,
                                            style: TextStyle(
                                                color: const Color(
                                                        0xFF00C853)
                                                    .withValues(alpha: 0.8),
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 60,
                                  child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
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
                                                  color:
                                                      const Color(0xFF00C853)
                                                          .withValues(
                                                              alpha: 0.6),
                                                  width: 1.5),
                                            ),
                                          ),
                                        ),
                                        AnimatedBuilder(
                                          animation: _barCtrl,
                                          builder: (ctx, _) {
                                            final barLeft = max(
                                                0.0,
                                                min(
                                                    _barPosition * trackW -
                                                        30,
                                                    trackW - 60));
                                            return Positioned(
                                              left: barLeft,
                                              top: 20,
                                              child: Container(
                                                width: 60,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF00B4FF),
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
                                      ]),
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
                  child: Text(
                    S.balanceTotal(_totalScore),
                    style: const TextStyle(
                        color: Color(0xFF00C853),
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
