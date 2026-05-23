import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../l10n/app_strings.dart';
import '../../painters/circle_tap_reflex_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scoring result
// ─────────────────────────────────────────────────────────────────────────────
class _Result {
  final int score;
  final int errorMs; // absolute; 9999 = auto-miss
  final bool isEarly;
  final String label;
  final bool isMiss;
  final bool isPerfect;

  const _Result({
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
class CircleTapReflexScreen extends StatefulWidget {
  const CircleTapReflexScreen({super.key});

  @override
  State<CircleTapReflexScreen> createState() => _CircleTapReflexState();
}

class _CircleTapReflexState extends State<CircleTapReflexScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'circle_tap_reflex';
  static const _xpReward = 30;
  static const _totalRounds = 10;
  static const double _autoMissDelayMs = 380;
  static const double _targetAngleDeg = -90.0;
  static const double _radiusFraction = 0.33;
  static const double _arcWidthDeg = 26.0; // fixed, between easy & normal
  static const int _perfectMs = 20;

  // Colours
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF41FF7A);
  static const _yellow = Color(0xFFFFD84D);
  static const _magenta = Color(0xFFFF2BD6);
  static const _red = Color(0xFFFF4D6D);

  // phase: warming / playing / feedback / finished
  // 'warming' = brief pre-game display before auto-start
  String _phase = 'warming';

  Ticker? _ticker;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);
  late AnimationController _glowCtrl;
  late AnimationController _perfectCtrl;

  final Stopwatch _stopwatch = Stopwatch();
  final Random _rng = Random();

  // Ball animation
  double _currentAngleDeg = _targetAngleDeg;
  double _approachGlow = 0.0;

  // Round config
  double _roundStartMs = 0;
  double _targetHitMs = 0;
  double _initialAngleDeg = 0;
  double _speedDegPerMs = 0;
  int _direction = 1;
  bool _autoMissGuard = false;

  // Session
  int _roundNum = 0;
  int _totalScore = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _perfectCount = 0;
  int _greatCount = 0;
  int _missCount = 0;
  int _bestMs = 9999;
  final List<int> _errorMsList = [];

  // Feedback
  String _fbLabel = '';
  Color _fbColor = Colors.white;
  int _fbScore = 0;
  int _fbErrorMs = 0;
  bool _fbIsEarly = false;
  Color _glowColor = _cyan;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _perfectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ticker = createTicker(_onTick)..start();

    // Auto-start after a short display delay (no menu)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
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

  // ── Ticker ─────────────────────────────────────────────────────────────────
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

  // ── Round generation — speed ramps up each round ───────────────────────────
  void _generateRound() {
    // Round 1: ~130 deg/s → Round 10: ~265 deg/s (linear ramp + small random jitter)
    final baseSpeed = 130.0 + (_roundNum - 1) * 15.0;
    final speedDegPerSec = baseSpeed + _rng.nextDouble() * 20.0;
    _speedDegPerMs = speedDegPerSec / 1000.0;

    _roundStartMs = _stopwatch.elapsedMilliseconds.toDouble();
    _direction = _rng.nextBool() ? 1 : -1;

    final delayMs = 1200.0 + _rng.nextDouble() * 1600.0; // 1.2–2.8 s
    _targetHitMs = _roundStartMs + delayMs;
    _initialAngleDeg = _targetAngleDeg - _direction * _speedDegPerMs * delayMs;
    _autoMissGuard = false;
  }

  // ── Game flow ──────────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _phase = 'playing';
      _roundNum = 1;
      _totalScore = 0;
      _combo = 0;
      _bestCombo = 0;
      _perfectCount = 0;
      _greatCount = 0;
      _missCount = 0;
      _bestMs = 9999;
      _errorMsList.clear();
    });
    _stopwatch
      ..reset()
      ..start();
    _generateRound();
  }

  void _scheduleRestart() {
    setState(() => _phase = 'warming');
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _startGame();
    });
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_phase == 'playing') {
      _processTap(_stopwatch.elapsedMilliseconds.toDouble());
    }
  }

  void _processTap(double tapMs) {
    if (_phase != 'playing') return;
    final result = _scoreRound(tapMs);

    setState(() {
      _totalScore += result.score;
      _fbLabel = result.label;
      _fbScore = result.score;
      _fbErrorMs = result.errorMs;
      _fbIsEarly = result.isEarly;
      _fbColor = _colorForLabel(result.label);
      _glowColor = result.isMiss ? _red : _fbColor;

      if (result.errorMs <= 90 && !result.isMiss) {
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
      } else if (result.errorMs > 140 || result.isMiss) {
        _combo = 0;
      }

      if (result.isMiss) _missCount++;
      if (result.isPerfect) _perfectCount++;
      if (result.label == S.great) _greatCount++;

      if (result.errorMs < 9999) {
        _errorMsList.add(result.errorMs);
        if (result.errorMs < _bestMs) _bestMs = result.errorMs;
      }

      _phase = 'feedback';
    });

    if (tapMs != double.infinity) {
      if (result.isPerfect) {
        HapticFeedback.mediumImpact();
        _perfectCtrl.forward(from: 0).then((_) {
          if (mounted) _perfectCtrl.reverse();
        });
      } else if (result.errorMs <= 50) {
        HapticFeedback.lightImpact();
      } else if (result.isMiss) {
        HapticFeedback.selectionClick();
      }
      _glowCtrl.forward(from: 0).then((_) {
        if (mounted) _glowCtrl.reverse();
      });
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_roundNum >= _totalRounds) {
        setState(() => _phase = 'finished');
        _finishGame();
      } else {
        setState(() {
          _phase = 'playing';
          _roundNum++;
        });
        _generateRound();
      }
    });
  }

  _Result _scoreRound(double tapMs) {
    if (tapMs == double.infinity) {
      return _Result(
        score: 0, errorMs: 9999, isEarly: false,
        label: S.missed, isMiss: true,
      );
    }

    final double err = tapMs - _targetHitMs;
    final int abs = err.abs().round();
    final bool early = err < 0;

    if (abs > 220) {
      return _Result(score: 0, errorMs: abs, isEarly: early,
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
      label = S.good;
      base = 65 + ((90 - abs) * 19 ~/ 40);
    } else if (abs <= 140) {
      label = S.slightlyOff;
      base = 40 + ((140 - abs) * 24 ~/ 50);
    } else {
      label = S.weak;
      base = 10 + ((220 - abs) * 29 ~/ 79);
    }

    final double mult = _combo >= 9 ? 1.35 : _combo >= 6 ? 1.2 : _combo >= 3 ? 1.1 : 1.0;
    final int final_ = (base * mult).round().clamp(0, 135);

    return _Result(score: final_, errorMs: abs, isEarly: early,
        label: label, isMiss: false, isPerfect: abs <= _perfectMs);
  }

  Color _colorForLabel(String label) {
    if (label == S.excellent) return _yellow;
    if (label == S.great) return _cyan;
    if (label == S.good) return _green;
    if (label == S.slightlyOff) return _magenta;
    return _red;
  }

  Future<void> _finishGame() async {
    final s = await StorageService.getInstance();
    final prev = s.arcadeBestScore(_gameId);
    await s.saveArcadeBestScore(_gameId, _totalScore > prev ? _totalScore : prev);
    await s.saveXP(_xpReward);
    await s.saveLevel(XpService.levelForXp(s.xp));
    await AchievementService.checkArcadeAchievements(_gameId, _totalScore, s);
    await AdService().incrementGameCountAndMaybeShow();
    if (mounted) setState(() {});
  }

  double _angDist(double a, double b) {
    final d = ((a - b) % 360 + 360) % 360;
    return d > 180 ? 360 - d : d;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: SafeArea(
          child: _phase == 'finished' ? _buildResult() : _buildGame(),
        ),
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildHeader(),
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

                    if (_phase == 'warming')
                      Center(
                        child: Text(
                          S.ready,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16,
                          ),
                        ),
                      ),

                    if (_phase == 'feedback') _buildFeedback(),

                    if (_phase == 'playing')
                      Positioned(
                        bottom: 16,
                        child: Text(
                          '${S.focusRound(_roundNum, _totalRounds)}  •  ${S.circleScore(_totalScore)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                      ),

                    if (_phase == 'playing' && _combo >= 3)
                      Positioned(
                        top: 12, right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _yellow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _yellow.withValues(alpha: 0.5)),
                          ),
                          child: Text('x$_combo COMBO',
                              style: const TextStyle(
                                  color: _yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
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
            child: Text('Circle Tap Reflex',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          if (_phase == 'playing' || _phase == 'feedback')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$_roundNum/$_totalRounds',
                  style: const TextStyle(color: _cyan, fontSize: 14)),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final showDir = _fbErrorMs < 9999 && _fbErrorMs > 0 &&
        _fbLabel != S.excellent && _fbLabel != S.missed;
    final sign = _fbIsEarly ? '-' : '+';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fbLabel,
            style: TextStyle(color: _fbColor, fontSize: 30, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: _fbColor, blurRadius: 24)])),
        if (_fbLabel == S.excellent && _fbErrorMs < 9999) ...[
          const SizedBox(height: 4),
          Text('${_fbErrorMs}ms',
              style: TextStyle(color: _fbColor.withValues(alpha: 0.65), fontSize: 14)),
        ],
        if (showDir) ...[
          const SizedBox(height: 4),
          Text('${_fbIsEarly ? S.early : S.late}: $sign${_fbErrorMs}ms',
              style: TextStyle(color: _fbColor.withValues(alpha: 0.75),
                  fontSize: 15, fontWeight: FontWeight.w500)),
        ],
        const SizedBox(height: 6),
        if (_fbScore > 0)
          Text('+$_fbScore',
              style: TextStyle(color: _fbColor.withValues(alpha: 0.60),
                  fontSize: 19, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Result ─────────────────────────────────────────────────────────────────
  Widget _buildResult() {
    final valid = _errorMsList.where((e) => e < 9999).toList();
    final avgMs = valid.isEmpty ? 0
        : (valid.reduce((a, b) => a + b) / valid.length).round();
    final bestMs = _bestMs == 9999 ? 0 : _bestMs;

    final String unvan;
    if (avgMs <= 20) { unvan = 'Refleks Ustası'; }
    else if (avgMs <= 50) { unvan = 'Çok Hızlı'; }
    else if (avgMs <= 90) { unvan = 'İyi Refleks'; }
    else if (avgMs <= 140) { unvan = 'Gelişiyor'; }
    else { unvan = 'Biraz Antrenman Lazım'; }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cyan.withValues(alpha: 0.35)),
                  ),
                  child: Text(unvan,
                      style: const TextStyle(color: _cyan, fontSize: 22,
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 20),
                Text('$_totalScore',
                    style: const TextStyle(color: Colors.white, fontSize: 72,
                        fontWeight: FontWeight.bold, height: 1)),
                Text(S.score,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45), fontSize: 16)),
                const SizedBox(height: 28),
                _buildStats(avgMs, bestMs),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(child: _resBtn(S.again, _cyan, _scheduleRestart)),
                    const SizedBox(width: 14),
                    Expanded(child: _resBtn(S.exit, _magenta, () => Navigator.pop(context))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(int avgMs, int bestMs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(children: [_stat('Ort. Refleks', '${avgMs}ms', _yellow), _stat(S.best, '${bestMs}ms', _green)]),
          const SizedBox(height: 12),
          Row(children: [_stat('Mükemmel', '$_perfectCount', _cyan), _stat('Harika', '$_greatCount', _green)]),
          const SizedBox(height: 12),
          Row(children: [_stat('Kaçtı', '$_missCount', _red), _stat('Best Combo', '$_bestCombo', _magenta)]),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _resBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
