// Full-test version of Target Lock (Test 14/15).
// Lock 10 targets → score 0-1000 normalized to 0-100.
// Navigates to SwipeDodgeTestScreen on completion.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import '../../painters/radar_painter.dart';
import 'swipe_dodge_test_screen.dart';

class TargetLockTestScreen extends StatefulWidget {
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
  final int balanceScore;
  final int dartScore;
  final int skyScore;

  const TargetLockTestScreen({
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
    required this.balanceScore,
    required this.dartScore,
    required this.skyScore,
  });

  @override
  State<TargetLockTestScreen> createState() => _TLTState();
}

class _TLTState extends State<TargetLockTestScreen>
    with TickerProviderStateMixin {

  static const _totalToLock = 10;
  static const _tolerance   = 40 * pi / 180;

  final _rand = Random();

  Ticker? _sweepTicker;
  double _sweepAngle = 0.0;
  double _sweepSpeed = 0.4;
  int    _prevMs     = 0;

  List<double> _targetAngles = [];
  List<bool>   _targetLocked = [];
  int    _totalLocked = 0;
  int    _totalScore  = 0;
  String _feedback    = '';
  Color  _feedbackColor = Colors.white;
  bool   _showFeedback  = false;
  bool   _gameEnded     = false;

  @override
  void initState() {
    super.initState();
    _spawnTargets();
    _sweepTicker = createTicker(_onSweepTick)..start();
  }

  void _onSweepTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMilliseconds;
    final dt = ms - _prevMs;
    _prevMs = ms;
    if (dt <= 0) return;
    setState(() {
      _sweepAngle = (_sweepAngle + dt / 1000.0 * _sweepSpeed * 2 * pi) % (2 * pi);
    });
  }

  @override
  void dispose() {
    _sweepTicker?.dispose();
    super.dispose();
  }

  void _spawnTargets() {
    _targetAngles = List.generate(3, (_) => _rand.nextDouble() * 2 * pi);
    _targetLocked = List.filled(3, false);
  }

  void _onTap() {
    if (_gameEnded) return;

    bool lockedAny = false;
    for (int i = 0; i < _targetAngles.length; i++) {
      if (_targetLocked[i]) continue;
      final diff    = (_sweepAngle - _targetAngles[i]).abs();
      final minDiff = min(diff, (2 * pi - diff).abs());
      if (minDiff <= _tolerance) {
        final accuracyScore = (100 * (1 - minDiff / _tolerance)).round().clamp(0, 100);
        setState(() {
          _targetLocked[i] = true;
          _totalLocked++;
          _totalScore += accuracyScore;
          _feedback      = '+$accuracyScore';
          _feedbackColor = const Color(0xFF00C853);
          _showFeedback  = true;
          lockedAny = true;
        });
        Future.delayed(const Duration(milliseconds: 600),
            () { if (mounted) setState(() => _showFeedback = false); });
        break;
      }
    }

    if (!lockedAny) {
      setState(() {
        _feedback      = 'Kaçırdın!';
        _feedbackColor = const Color(0xFFFF7043);
        _showFeedback  = true;
      });
      Future.delayed(const Duration(milliseconds: 600),
          () { if (mounted) setState(() => _showFeedback = false); });
    }

    if (_targetLocked.every((l) => l)) {
      if (_totalLocked >= _totalToLock) {
        setState(() => _gameEnded = true);
        _sweepTicker?.stop();
        _finish();
      } else {
        _sweepSpeed += 0.15;
        _spawnTargets();
        setState(() {});
      }
    }
  }

  Future<void> _finish() async {
    final targetLockScore = (_totalScore / 10).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SwipeDodgeTestScreen(
          session:          widget.session,
          reactionScore:    widget.reactionScore,
          stroopScore:      widget.stroopScore,
          memoryScore:      widget.memoryScore,
          sequenceScore:    widget.sequenceScore,
          impulseScore:     widget.impulseScore,
          patternScore:     widget.patternScore,
          circleScore:      widget.circleScore,
          laserScore:       widget.laserScore,
          timingScore:      widget.timingScore,
          pulseScore:       widget.pulseScore,
          balanceScore:     widget.balanceScore,
          dartScore:        widget.dartScore,
          skyScore:         widget.skyScore,
          targetLockScore:  targetLockScore,
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
            onTapDown: (_) => _onTap(),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // Progress header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Test 14 / 29',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _totalLocked / _totalToLock,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            color: const Color(0xFF00C853),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$_totalLocked/$_totalToLock kilitli',
                          style: const TextStyle(
                              color: Color(0xFF00C853), fontSize: 13)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Target Lock — Tarama geçerken dokun!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: RadarPainter(
                          sweepAngle:   _sweepAngle,
                          targetAngles: _targetAngles,
                          targetLocked: _targetLocked,
                          tolerance:    _tolerance,
                        ),
                        size: const Size(300, 300),
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
                  child: Text(
                    'Puan: $_totalScore',
                    style: const TextStyle(
                        color: Color(0xFFBB86FC),
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
