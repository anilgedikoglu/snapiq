// Full-test version of Circle Tap Reflex.
// 5 rounds, auto-starts, speed ramps up each round.
// On completion builds TestResult and navigates to ResultScreen.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../models/game_session.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../painters/circle_tap_reflex_painter.dart';
import '../../l10n/app_strings.dart';
import 'laser_gate_test_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scoring result (local)
// ─────────────────────────────────────────────────────────────────────────────
class _R {
  final int score;
  final int errorMs;
  final bool isEarly;
  final String label;
  final bool isMiss;
  final bool isPerfect;
  const _R({
    required this.score,
    required this.errorMs,
    required this.isEarly,
    required this.label,
    required this.isMiss,
    this.isPerfect = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CircleTapTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;

  const CircleTapTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
    required this.patternScore,
  });

  @override
  State<CircleTapTestScreen> createState() => _CTTState();
}

class _CTTState extends State<CircleTapTestScreen>
    with TickerProviderStateMixin {
  static const _totalRounds = 5;
  static const double _autoMissDelayMs = 380;
  static const double _targetAngleDeg = -90.0;
  static const double _radiusFraction = 0.33;
  static const double _arcWidthDeg = 24.0; // normal difficulty
  static const int _perfectMs = 20;

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF41FF7A);
  static const _yellow = Color(0xFFFFD84D);
  static const _magenta = Color(0xFFFF2BD6);
  static const _red = Color(0xFFFF4D6D);

  // phase: warming / playing / feedback / done
  String _phase = 'warming';

  Ticker? _ticker;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);
  late AnimationController _glowCtrl;
  late AnimationController _perfectCtrl;

  final Stopwatch _stopwatch = Stopwatch();
  final Random _rng = Random();

  double _currentAngleDeg = _targetAngleDeg;
  double _approachGlow = 0.0;

  double _roundStartMs = 0;
  double _targetHitMs = 0;
  double _initialAngleDeg = 0;
  double _speedDegPerMs = 0;
  int _direction = 1;
  bool _autoMissGuard = false;

  int _roundNum = 0;
  int _totalScore = 0;
  int _combo = 0;
  int _bestCombo = 0;

  String _fbLabel = '';
  Color _fbColor = Colors.white;
  int _fbScore = 0;
  int _fbErrorMs = 0;
  bool _fbIsEarly = false;
  Color _glowColor = _cyan;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _perfectCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _ticker = createTicker(_onTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _startGame();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _glowCtrl.dispose();
    _perfectCtrl.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (_phase == 'playing') {
      final nowMs = _stopwatch.elapsedMilliseconds.toDouble();
      final t = nowMs - _roundStartMs;
      _currentAngleDeg = _initialAngleDeg + _direction * _speedDegPerMs * t;

      final dist = _angDist(_currentAngleDeg, _targetAngleDeg);
      _approachGlow = dist < 28 ? ((28 - dist) / 28).clamp(0.0, 1.0) : 0.0;

      if (!_autoMissGuard && nowMs > _targetHitMs + _autoMissDelayMs) {
        _autoMissGuard = true;
        _processTap(double.infinity);
      }
    }
    _repaintNotifier.value++;
  }

  void _generateRound() {
    // Round 1: 150 deg/s → Round 5: 250 deg/s (step +25 per round)
    final baseSpeed = 150.0 + (_roundNum - 1) * 25.0;
    final speedDegPerSec = baseSpeed + _rng.nextDouble() * 20.0;
    _speedDegPerMs = speedDegPerSec / 1000.0;

    _roundStartMs = _stopwatch.elapsedMilliseconds.toDouble();
    _direction = _rng.nextBool() ? 1 : -1;
    final delayMs = 1200.0 + _rng.nextDouble() * 1400.0;
    _targetHitMs = _roundStartMs + delayMs;
    _initialAngleDeg = _targetAngleDeg - _direction * _speedDegPerMs * delayMs;
    _autoMissGuard = false;
  }

  void _startGame() {
    setState(() {
      _phase = 'playing';
      _roundNum = 1;
      _totalScore = 0;
      _combo = 0;
      _bestCombo = 0;
    });
    _stopwatch..reset()..start();
    _generateRound();
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_phase == 'playing') _processTap(_stopwatch.elapsedMilliseconds.toDouble());
  }

  void _processTap(double tapMs) {
    if (_phase != 'playing') return;
    final result = _score(tapMs);

    setState(() {
      _totalScore += result.score;
      _fbLabel = result.label;
      _fbScore = result.score;
      _fbErrorMs = result.errorMs;
      _fbIsEarly = result.isEarly;
      _fbColor = _colorFor(result.label);
      _glowColor = result.isMiss ? _red : _fbColor;

      if (result.errorMs <= 90 && !result.isMiss) {
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
      } else if (result.errorMs > 140 || result.isMiss) {
        _combo = 0;
      }

      _phase = 'feedback';
    });

    if (tapMs != double.infinity) {
      if (result.isPerfect) {
        HapticFeedback.mediumImpact();
        _perfectCtrl.forward(from: 0).then((_) {
          if (mounted) _perfectCtrl.reverse();
        });
      } else if (!result.isMiss) {
        HapticFeedback.lightImpact();
      }
      _glowCtrl.forward(from: 0).then((_) {
        if (mounted) _glowCtrl.reverse();
      });
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_roundNum >= _totalRounds) {
        setState(() => _phase = 'done');
        _finishTest();
      } else {
        setState(() {
          _phase = 'playing';
          _roundNum++;
        });
        _generateRound();
      }
    });
  }

  _R _score(double tapMs) {
    if (tapMs == double.infinity) {
      return _R(score: 0, errorMs: 9999, isEarly: false,
          label: S.missed, isMiss: true);
    }
    final double err = tapMs - _targetHitMs;
    final int abs = err.abs().round();
    final bool early = err < 0;
    if (abs > 220) {
      return _R(score: 0, errorMs: abs, isEarly: early,
          label: S.missed, isMiss: true);
    }
    final String label;
    final int base;
    if (abs <= _perfectMs) {
      label = S.excellent; base = 100;
    } else if (abs <= 50) {
      label = S.great;
      base = 85 + ((50 - abs) * 14 ~/ (50 - _perfectMs).clamp(1, 30));
    } else if (abs <= 90) {
      label = S.good; base = 65 + ((90 - abs) * 19 ~/ 40);
    } else if (abs <= 140) {
      label = S.slightlyOff; base = 40 + ((140 - abs) * 24 ~/ 50);
    } else {
      label = S.weak; base = 10 + ((220 - abs) * 29 ~/ 79);
    }
    final double mult = _combo >= 9 ? 1.35 : _combo >= 6 ? 1.2 : _combo >= 3 ? 1.1 : 1.0;
    final int final_ = (base * mult).round().clamp(0, 135);
    return _R(score: final_, errorMs: abs, isEarly: early, label: label,
        isMiss: false, isPerfect: abs <= _perfectMs);
  }

  Color _colorFor(String label) {
    if (label == S.excellent) return _yellow;
    if (label == S.great) return _cyan;
    if (label == S.good) return _green;
    if (label == S.slightlyOff) return _magenta;
    return _red;
  }

  double _angDist(double a, double b) {
    final d = ((a - b) % 360 + 360) % 360;
    return d > 180 ? 360 - d : d;
  }

  Future<void> _finishTest() async {
    // Normalize 5 rounds × 100 max = 500 → 0-100
    final circleScore = (_totalScore / 5).round().clamp(0, 100);

    await AdService().incrementGameCountAndMaybeShow();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LaserGateTestScreen(
          session: widget.session,
          reactionScore: widget.reactionScore,
          stroopScore: widget.stroopScore,
          memoryScore: widget.memoryScore,
          sequenceScore: widget.sequenceScore,
          impulseScore: widget.impulseScore,
          patternScore: widget.patternScore,
          circleScore: circleScore,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                    Text('Test 7 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _roundNum / _totalRounds,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: _cyan,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_roundNum/$_totalRounds',
                        style: const TextStyle(color: _cyan, fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  S.circleInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Expanded(
                child: Listener(
                  onPointerDown: _phase == 'playing' ? _onPointerDown : null,
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ValueListenableBuilder<int>(
                            valueListenable: _repaintNotifier,
                            builder: (ctx, _, __) {
                              final arcRad = _arcWidthDeg * pi / 180;
                              final angleRad = _currentAngleDeg * pi / 180;
                              return AnimatedBuilder(
                                animation: Listenable.merge([_glowCtrl, _perfectCtrl]),
                                builder: (ctx, _) {
                                  return CustomPaint(
                                    painter: CircleTapReflexPainter(
                                      radiusFraction: _radiusFraction,
                                      ballAngleRad: angleRad,
                                      direction: _direction,
                                      targetArcWidthRad: arcRad,
                                      approachGlow: _approachGlow,
                                      feedbackGlow: _glowCtrl.value,
                                      feedbackColor: _glowColor,
                                      perfectFlash: _perfectCtrl.value,
                                      showBall: _phase == 'playing' || _phase == 'feedback',
                                    ),
                                    size: Size(constraints.maxWidth, constraints.maxHeight),
                                  );
                                },
                              );
                            },
                          ),

                          if (_phase == 'warming' || _phase == 'done')
                            Center(
                              child: Text(
                                _phase == 'done' ? S.done : S.ready,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16),
                              ),
                            ),

                          if (_phase == 'feedback') _buildFeedback(),

                          if (_phase == 'playing')
                            Positioned(
                              bottom: 16,
                              child: Text('Skor: $_totalScore',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 13)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final showDir = _fbErrorMs < 9999 && _fbErrorMs > 0 &&
        _fbLabel != 'Mükemmel!' && _fbLabel != 'Kaçtı!';
    final sign = _fbIsEarly ? '-' : '+';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fbLabel,
            style: TextStyle(color: _fbColor, fontSize: 28, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: _fbColor, blurRadius: 20)])),
        if (_fbLabel == 'Mükemmel!' && _fbErrorMs < 9999) ...[
          const SizedBox(height: 3),
          Text('${_fbErrorMs}ms',
              style: TextStyle(color: _fbColor.withValues(alpha: 0.65), fontSize: 13)),
        ],
        if (showDir) ...[
          const SizedBox(height: 3),
          Text('${_fbIsEarly ? "Erken" : "Geç"}: $sign${_fbErrorMs}ms',
              style: TextStyle(color: _fbColor.withValues(alpha: 0.70),
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
        const SizedBox(height: 5),
        if (_fbScore > 0)
          Text('+$_fbScore',
              style: TextStyle(color: _fbColor.withValues(alpha: 0.55),
                  fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
