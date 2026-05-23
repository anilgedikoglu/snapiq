// Full-test version of Laser Gate.
// Player passes all 3 rings once; time recorded → score 0-100.
// Max time 45s → auto-end with score 0.
// On completion builds TestResult and navigates to ResultScreen.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../models/game_session.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../painters/laser_gate_painter.dart';
import '../../l10n/app_strings.dart';
import 'timing_stack_test_screen.dart';

class LaserGateTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;
  final int circleScore;

  const LaserGateTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
    required this.patternScore,
    required this.circleScore,
  });

  @override
  State<LaserGateTestScreen> createState() => _LGTState();
}

class _LGTState extends State<LaserGateTestScreen>
    with TickerProviderStateMixin {

  static const double _tolerance = 25 * pi / 180;
  static const int _maxMs = 45000; // auto-end after 45s

  final List<double> _ringSpeed = [0.96, -1.44, 2.0];
  late List<AnimationController> _ringCtrl;
  late AnimationController _impactCtrl;
  int _impactRing = -1;
  Ticker? _uiTicker;

  int _ballRing = 0;
  bool _canTap = true;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _done = false;

  final Stopwatch _stopwatch = Stopwatch();
  int _displayMs = 0;

  static int _timeScore(int ms) =>
      ((25000 - ms) / 22000.0 * 100).round().clamp(0, 100);

  @override
  void initState() {
    super.initState();
    _impactCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _initControllers();
    _stopwatch.start();
    _uiTicker = createTicker((_) {
      if (!mounted || _done) return;
      final ms = _stopwatch.elapsedMilliseconds;
      setState(() => _displayMs = ms);
      if (ms >= _maxMs) _finish(ms);
    })..start();
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
    final v = _ringCtrl[i].value;
    return _ringSpeed[i] >= 0 ? v * 2 * pi : (1 - v) * 2 * pi;
  }

  bool _isGapAtTop(int idx) {
    final a = _ringAngle(idx) % (2 * pi);
    return a.abs() < _tolerance || (a - 2 * pi).abs() < _tolerance;
  }

  void _onTap() {
    if (!_canTap || _done || _ballRing >= 3) return;
    _canTap = false;

    if (_isGapAtTop(_ballRing)) {
      setState(() {
        _ballRing++;
        _feedback = ['Geçti! ✓', 'Harika! ✓', 'Dışarı! 🎯'][_ballRing - 1];
        _feedbackColor = const Color(0xFF00C853);
        _showFeedback = true;
      });

      if (_ballRing >= 3) {
        _stopwatch.stop();
        final ms = _stopwatch.elapsedMilliseconds;
        setState(() { _displayMs = ms; _done = true; });
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _finish(ms);
        });
      } else {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() { _showFeedback = false; _canTap = true; });
        });
      }
    } else {
      _impactRing = _ballRing;
      _impactCtrl.forward(from: 0);
      setState(() {
        _ballRing = 0;
        _feedback = 'Çarptı!';
        _feedbackColor = const Color(0xFFFF7043);
        _showFeedback = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _showFeedback = false; _canTap = true; });
      });
    }
  }

  Future<void> _finish(int ms) async {
    if (!mounted) return;
    _done = true;
    _stopwatch.stop();

    final laserScore = _timeScore(ms);

    await AdService().incrementGameCountAndMaybeShow();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TimingStackTestScreen(
          session: widget.session,
          reactionScore: widget.reactionScore,
          stroopScore: widget.stroopScore,
          memoryScore: widget.memoryScore,
          sequenceScore: widget.sequenceScore,
          impulseScore: widget.impulseScore,
          patternScore: widget.patternScore,
          circleScore: widget.circleScore,
          laserScore: laserScore,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uiTicker?.dispose();
    _impactCtrl.dispose();
    for (final c in _ringCtrl) { c.dispose(); }
    super.dispose();
  }

  String get _timeDisplay {
    final s = _displayMs ~/ 1000;
    final cs = (_displayMs % 1000) ~/ 10;
    return '${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _done
        ? const Color(0xFF00C853)
        : const Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Test header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Test 8 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _done ? 1.0 : _displayMs / _maxMs,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: timerColor,
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.laserInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Big timer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _timeDisplay,
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: timerColor, blurRadius: 18)],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([..._ringCtrl, _impactCtrl]),
                        builder: (ctx, _) => CustomPaint(
                          painter: LaserGatePainter(
                            angles: List.generate(3, _ringAngle),
                            ballRing: _ballRing,
                            lives: 3,
                            score: 0,
                            impactRing: _impactRing,
                            impactGlow: 1.0 - _impactCtrl.value,
                          ),
                          size: Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.width,
                          ),
                        ),
                      ),
                      if (_showFeedback)
                        Text(
                          _feedback,
                          style: TextStyle(
                            color: _feedbackColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: _feedbackColor, blurRadius: 20)],
                          ),
                        ),
                      if (_done && _ballRing >= 3)
                        Text(
                          S.done,
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
