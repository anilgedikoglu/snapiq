import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../painters/orbit_sync_painter.dart';

// Set true during development to see timing overlay; false for release
const _kDebug = false;

// ---------------------------------------------------------------------------
// Difficulty config
// ---------------------------------------------------------------------------
enum _Difficulty { easy, normal, hard }

class _DiffConfig {
  final int ringCount;
  final List<double> speedsDeg; // degrees/s, sign = direction
  final List<double> radiiFrac;
  final int segCount;

  const _DiffConfig({
    required this.ringCount,
    required this.speedsDeg,
    required this.radiiFrac,
    required this.segCount,
  });
}

const _easyConfig = _DiffConfig(
  ringCount: 3,
  speedsDeg: [25, -38, 55],
  radiiFrac: [0.88, 0.62, 0.38],
  segCount: 8,
);

const _normalConfig = _DiffConfig(
  ringCount: 3,
  speedsDeg: [35, -52, 76],
  radiiFrac: [0.88, 0.62, 0.38],
  segCount: 8,
);

const _hardConfig = _DiffConfig(
  ringCount: 4,
  speedsDeg: [35, -52, 76, -95],
  radiiFrac: [0.90, 0.68, 0.48, 0.28],
  segCount: 10,
);

// ---------------------------------------------------------------------------
// Per-round data — the sync moment is mathematically guaranteed
// ---------------------------------------------------------------------------
class _RoundData {
  /// ms from round start when all rings show targetColor at 12 o'clock
  final double targetSyncMs;
  final Color targetColor;

  /// one initialRotation (radians) per ring, chosen so that at
  /// targetSyncMs each ring's targetColor segment is exactly at 12 o'clock
  final List<double> initialRotations;

  const _RoundData({
    required this.targetSyncMs,
    required this.targetColor,
    required this.initialRotations,
  });
}

// ---------------------------------------------------------------------------
// Scoring result
// ---------------------------------------------------------------------------
class _RoundResult {
  final int score;
  final int errorMs; // absolute; 9999 = auto-miss
  final bool isEarly;
  final String label;
  final bool isMiss;

  const _RoundResult({
    required this.score,
    required this.errorMs,
    required this.isEarly,
    required this.label,
    required this.isMiss,
  });
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class OrbitSyncScreen extends StatefulWidget {
  const OrbitSyncScreen({super.key});

  @override
  State<OrbitSyncScreen> createState() => _OrbitSyncScreenState();
}

class _OrbitSyncScreenState extends State<OrbitSyncScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'orbit_sync';
  static const _xpReward = 35;
  static const _totalRounds = 10;

  // After targetSyncMs + this many ms with no tap → auto-miss
  static const double _autoMissDelayMs = 380;

  static const _cyan = Color(0xFF00E5FF);
  static const _magenta = Color(0xFFFF2BD6);
  static const _yellow = Color(0xFFFFD84D);
  static const _green = Color(0xFF41FF7A);
  static const _palette = [_cyan, _magenta, _yellow, _green];

  _Difficulty _difficulty = _Difficulty.normal;
  _DiffConfig get _config {
    switch (_difficulty) {
      case _Difficulty.easy:
        return _easyConfig;
      case _Difficulty.normal:
        return _normalConfig;
      case _Difficulty.hard:
        return _hardConfig;
    }
  }

  // Phase: waiting / playing / feedback / finished
  String _phase = 'waiting';

  // Ticker
  Ticker? _ticker;
  double _elapsedSeconds = 0;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  // Per-round state
  _RoundData? _currentRound;
  double _roundStartSecs = 0;
  double get _roundElapsedSecs => _elapsedSeconds - _roundStartSecs;
  double get _roundElapsedMs => _roundElapsedSecs * 1000.0;
  bool _autoMissGuard = false;

  // Session tracking
  int _completedRounds = 0;
  int _currentRoundNum = 0; // 1-based, for display
  int _totalScore = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _perfectCount = 0;
  int _greatCount = 0;
  int _missCount = 0;
  int _bestMs = 9999;
  final List<int> _errorMsList = [];

  // Feedback state
  String _feedbackLabel = '';
  Color _feedbackColor = Colors.white;
  int _feedbackScore = 0;
  int _feedbackErrorMs = 0;
  bool _feedbackIsEarly = false;

  // FX
  late AnimationController _shockwaveCtrl;
  late AnimationController _glowCtrl;
  Color _shockwaveColor = _cyan;
  Color _glowColor = _cyan;

  // Stars (fixed seed)
  late List<Offset> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _stars = List.generate(30, (_) => Offset(rng.nextDouble(), rng.nextDouble()));

    _shockwaveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _shockwaveCtrl.dispose();
    _glowCtrl.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Ticker
  // ---------------------------------------------------------------------------
  void _onTick(Duration elapsed) {
    _elapsedSeconds = elapsed.inMicroseconds / 1e6;

    // Auto-miss: player hasn't tapped and the window has expired
    if (_phase == 'playing' && _currentRound != null && !_autoMissGuard) {
      final deadline = _currentRound!.targetSyncMs + _autoMissDelayMs;
      if (_roundElapsedMs >= deadline) {
        _autoMissGuard = true;
        _processTap(double.infinity);
      }
    }

    _repaintNotifier.value++;
  }

  // ---------------------------------------------------------------------------
  // Round generation — guaranteed sync moment
  //
  // MATH:
  //   The painter draws segment `s` at canvas-angle:
  //     startAngle = ringAngle + s*segW - pi/2
  //
  //   `_colorAtTop` returns:
  //     a = (-pi/2 - ringAngle) mod 2pi
  //     segIdx = floor(a / segW)
  //     color  = palette[segIdx % paletteLen]
  //
  //   We want color == targetColor at t = targetSyncSecs.
  //   targetColor maps to paletteIdx in palette.
  //
  //   For segment paletteIdx to sit at 12 o'clock:
  //     a = paletteIdx*segW + segW/2   (centre of that segment = floor gives paletteIdx)
  //
  //   ringAngle at sync = initialRot + speed * syncSecs
  //   => -pi/2 - ringAngle = a
  //   => ringAngle = -pi/2 - a
  //   => initialRot = -pi/2 - a - speed * syncSecs
  //               = -pi/2 - paletteIdx*segW - segW/2 - speed*syncSecs
  // ---------------------------------------------------------------------------
  _RoundData _generateRound() {
    final cfg = _config;
    final rng = Random();

    final targetColor = _palette[rng.nextInt(_palette.length)];
    final paletteIdx = _palette.indexOf(targetColor);

    final double syncMs;
    switch (_difficulty) {
      case _Difficulty.easy:
        syncMs = 2000 + rng.nextDouble() * 1000; // 2000–3000 ms
        break;
      case _Difficulty.normal:
        syncMs = 1800 + rng.nextDouble() * 1400; // 1800–3200 ms
        break;
      case _Difficulty.hard:
        syncMs = 1500 + rng.nextDouble() * 1200; // 1500–2700 ms
        break;
    }

    final segW = 2 * pi / cfg.segCount;
    final syncSecs = syncMs / 1000.0;
    final speedsRad = cfg.speedsDeg.map((d) => d * pi / 180.0).toList();

    final initialRotations = List.generate(cfg.ringCount, (i) {
      final speed = speedsRad[i];
      return -pi / 2 - paletteIdx * segW - segW / 2 - speed * syncSecs;
    });

    return _RoundData(
      targetSyncMs: syncMs,
      targetColor: targetColor,
      initialRotations: initialRotations,
    );
  }

  // ---------------------------------------------------------------------------
  // Per-ring angle at current elapsed time
  // ---------------------------------------------------------------------------
  double _ringAngle(int i) {
    final speedRad = _config.speedsDeg[i] * pi / 180.0;
    return _currentRound!.initialRotations[i] + speedRad * _roundElapsedSecs;
  }

  // Color visible at 12 o'clock (top) for a given ring angle
  Color _colorAtTop(double ringAngle, int segCount) {
    final w = 2 * pi / segCount;
    final a = ((-pi / 2 - ringAngle) % (2 * pi) + 2 * pi) % (2 * pi);
    final i = (a / w).floor() % segCount;
    return _palette[i % _palette.length];
  }

  // ---------------------------------------------------------------------------
  // Game flow
  // ---------------------------------------------------------------------------
  void _startGame() {
    setState(() {
      _phase = 'playing';
      _completedRounds = 0;
      _currentRoundNum = 1;
      _totalScore = 0;
      _combo = 0;
      _bestCombo = 0;
      _perfectCount = 0;
      _greatCount = 0;
      _missCount = 0;
      _bestMs = 9999;
      _errorMsList.clear();
    });
    _beginRound();
  }

  void _beginRound() {
    _currentRound = _generateRound();
    _roundStartSecs = _elapsedSeconds;
    _autoMissGuard = false;
  }

  void _onTap(PointerDownEvent event) {
    if (_phase != 'playing') return;
    _processTap(_roundElapsedMs);
  }

  void _processTap(double tapMs) {
    if (_phase != 'playing') return; // guard against double-fire
    final round = _currentRound!;
    final result = _scoreRound(tapMs, round);

    setState(() {
      _completedRounds++;
      _totalScore += result.score;
      _feedbackLabel = result.label;
      _feedbackScore = result.score;
      _feedbackErrorMs = result.errorMs;
      _feedbackIsEarly = result.isEarly;
      _feedbackColor = _colorForLabel(result.label);

      if (!result.isMiss) {
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
      } else {
        _combo = 0;
        _missCount++;
      }

      if (result.errorMs < 9999) {
        _errorMsList.add(result.errorMs);
        if (result.errorMs < _bestMs) _bestMs = result.errorMs;
      }

      if (result.label == 'Mükemmel Senkron!') _perfectCount++;
      if (result.label == 'Harika!') _greatCount++;

      _phase = 'feedback';
    });

    // FX (skip for auto-miss)
    if (tapMs != double.infinity) {
      _shockwaveColor = round.targetColor;
      _glowColor = round.targetColor;
      _shockwaveCtrl.forward(from: 0);
      _glowCtrl.forward(from: 0).then((_) {
        if (mounted) _glowCtrl.reverse();
      });

      if (result.errorMs <= 50) {
        HapticFeedback.mediumImpact();
      } else if (result.errorMs <= 90) {
        HapticFeedback.lightImpact();
      }
    }

    // Advance after feedback delay
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_completedRounds >= _totalRounds) {
        setState(() => _phase = 'finished');
        _finishGame();
      } else {
        setState(() {
          _phase = 'playing';
          _currentRoundNum = _completedRounds + 1;
        });
        _beginRound();
      }
    });
  }

  _RoundResult _scoreRound(double tapMs, _RoundData round) {
    // Auto-miss
    if (tapMs == double.infinity) {
      return const _RoundResult(
        score: 0,
        errorMs: 9999,
        isEarly: false,
        label: 'Miss',
        isMiss: true,
      );
    }

    final double error = tapMs - round.targetSyncMs;
    final int absError = error.abs().round();
    final bool isEarly = error < 0;

    if (absError > 220) {
      return _RoundResult(
        score: 0,
        errorMs: absError,
        isEarly: isEarly,
        label: 'Miss',
        isMiss: true,
      );
    }

    final String label;
    final int baseScore;

    if (absError <= 20) {
      label = 'Mükemmel Senkron!';
      baseScore = 100;
    } else if (absError <= 50) {
      label = 'Harika!';
      baseScore = 85 + ((50 - absError) * 14 ~/ 30); // 85–99
    } else if (absError <= 90) {
      label = 'İyi!';
      baseScore = 65 + ((90 - absError) * 19 ~/ 40); // 65–84
    } else if (absError <= 140) {
      label = 'Zayıf';
      baseScore = 40 + ((140 - absError) * 24 ~/ 50); // 40–63
    } else {
      label = 'Çok Zayıf';
      baseScore = 10 + ((220 - absError) * 29 ~/ 79); // 10–38
    }

    final double comboMult = _combo >= 9
        ? 1.35
        : _combo >= 6
            ? 1.2
            : _combo >= 3
                ? 1.1
                : 1.0;

    final int finalScore = (baseScore * comboMult).round().clamp(0, 135);

    return _RoundResult(
      score: finalScore,
      errorMs: absError,
      isEarly: isEarly,
      label: label,
      isMiss: false,
    );
  }

  Color _colorForLabel(String label) {
    switch (label) {
      case 'Mükemmel Senkron!':
        return _cyan;
      case 'Harika!':
        return _green;
      case 'İyi!':
        return _yellow;
      case 'Zayıf':
      case 'Çok Zayıf':
        return _magenta;
      default:
        return Colors.redAccent;
    }
  }

  Future<void> _finishGame() async {
    final score = _totalScore;
    final s = await StorageService.getInstance();
    final prevBest = s.arcadeBestScore(_gameId);
    await s.saveArcadeBestScore(_gameId, score > prevBest ? score : prevBest);
    await s.saveXP(_xpReward);
    await s.saveLevel(XpService.levelForXp(s.xp));
    await AchievementService.checkArcadeAchievements(_gameId, score, s);
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    setState(() {}); // triggers result screen
  }

  void _restart() {
    setState(() {
      _phase = 'waiting';
      _completedRounds = 0;
      _currentRoundNum = 0;
      _totalScore = 0;
      _combo = 0;
      _bestCombo = 0;
      _perfectCount = 0;
      _greatCount = 0;
      _missCount = 0;
      _bestMs = 9999;
      _errorMsList.clear();
      _feedbackLabel = '';
      _currentRound = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: SafeArea(
          child: _phase == 'finished' ? _buildResultScreen() : _buildGameScreen(),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Listener(
            onPointerDown: _phase == 'playing' ? _onTap : null,
            behavior: HitTestBehavior.opaque,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rings canvas
                    ValueListenableBuilder<int>(
                      valueListenable: _repaintNotifier,
                      builder: (ctx, _, __) {
                        List<RingState> rings = [];
                        double targetGlow = 0.0;
                        String? debugInfo;

                        if ((_phase == 'playing' || _phase == 'feedback') &&
                            _currentRound != null) {
                          final cfg = _config;
                          rings = List.generate(cfg.ringCount, (i) {
                            return RingState(
                              angle: _ringAngle(i),
                              radius: cfg.radiiFrac[i],
                              segCount: cfg.segCount,
                              palette: _palette,
                            );
                          });

                          if (_phase == 'playing') {
                            final msToSync =
                                _currentRound!.targetSyncMs - _roundElapsedMs;
                            if (msToSync > 0 && msToSync < 600) {
                              // Ramp up as sync approaches
                              targetGlow =
                                  ((600 - msToSync) / 600).clamp(0.0, 1.0);
                            } else if (msToSync <= 0 && msToSync > -200) {
                              // Brief fade after the sync moment
                              targetGlow =
                                  (1.0 + msToSync / 200).clamp(0.0, 1.0);
                            }

                            if (_kDebug) {
                              final tops = List.generate(cfg.ringCount, (i) {
                                final c = _colorAtTop(
                                    _ringAngle(i), cfg.segCount);
                                if (c == _cyan) return 'C';
                                if (c == _magenta) return 'M';
                                if (c == _yellow) return 'Y';
                                return 'G';
                              });
                              final tc = _currentRound!.targetColor == _cyan
                                  ? 'CYAN'
                                  : _currentRound!.targetColor == _magenta
                                      ? 'MAG'
                                      : _currentRound!.targetColor == _yellow
                                          ? 'YEL'
                                          : 'GRN';
                              final msLeft = (_currentRound!.targetSyncMs -
                                      _roundElapsedMs)
                                  .round();
                              debugInfo =
                                  'target:$tc  sync in:${msLeft}ms  top:${tops.join("/")}';
                            }
                          }
                        }

                        return AnimatedBuilder(
                          animation:
                              Listenable.merge([_shockwaveCtrl, _glowCtrl]),
                          builder: (ctx, _) {
                            return CustomPaint(
                              painter: OrbitSyncPainter(
                                rings: rings,
                                stars: _stars,
                                shockwave: _shockwaveCtrl.isAnimating ||
                                        _shockwaveCtrl.value > 0
                                    ? _shockwaveCtrl.value
                                    : -1,
                                shockwaveColor: _shockwaveColor,
                                glow: _glowCtrl.value,
                                glowColor: _glowColor,
                                targetGlow: targetGlow,
                                targetColor:
                                    _currentRound?.targetColor ?? _cyan,
                                debugInfo: debugInfo,
                              ),
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                            );
                          },
                        );
                      },
                    ),

                    if (_phase == 'waiting') _buildWaitingOverlay(),
                    if (_phase == 'feedback') _buildFeedbackOverlay(),

                    if (_phase == 'playing')
                      Positioned(
                        bottom: 16,
                        child: Text(
                          'Tur $_currentRoundNum / $_totalRounds  •  Skor: $_totalScore',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),

                    if (_phase == 'playing' && _combo >= 3)
                      Positioned(
                        top: 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _yellow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _yellow.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'x$_combo COMBO',
                            style: const TextStyle(
                              color: _yellow,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildWaitingOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Orbit Sync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '12\'de aynı renk hizalandığında dokun!',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _diffButton('Kolay', _Difficulty.easy, _green),
              const SizedBox(width: 10),
              _diffButton('Normal', _Difficulty.normal, _cyan),
              const SizedBox(width: 10),
              _diffButton('Zor', _Difficulty.hard, _magenta),
            ],
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cyan.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.2),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Text(
                'BAŞLA',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffButton(String label, _Difficulty diff, Color color) {
    final selected = _difficulty == diff;
    return GestureDetector(
      onTap: () => setState(() => _difficulty = diff),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.22)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.8)
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : color.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackOverlay() {
    final showDirection = _feedbackErrorMs < 9999 &&
        _feedbackErrorMs > 0 &&
        _feedbackLabel != 'Mükemmel Senkron!' &&
        _feedbackLabel != 'Miss';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _feedbackLabel,
          style: TextStyle(
            color: _feedbackColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: _feedbackColor, blurRadius: 22)],
          ),
        ),
        if (showDirection) ...[
          const SizedBox(height: 4),
          Text(
            '${_feedbackIsEarly ? "Erken" : "Geç"} ${_feedbackErrorMs}ms',
            style: TextStyle(
              color: _feedbackColor.withValues(alpha: 0.75),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 5),
        if (_feedbackScore > 0)
          Text(
            '+$_feedbackScore',
            style: TextStyle(
              color: _feedbackColor.withValues(alpha: 0.65),
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Orbit Sync',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (_phase == 'playing' || _phase == 'feedback')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_currentRoundNum/$_totalRounds',
                style: const TextStyle(color: _cyan, fontSize: 14),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result screen
  // ---------------------------------------------------------------------------
  Widget _buildResultScreen() {
    final validErrors =
        _errorMsList.where((e) => e < 9999).toList();
    final avgMs = validErrors.isEmpty
        ? 0
        : (validErrors.reduce((a, b) => a + b) / validErrors.length).round();
    final displayBestMs = _bestMs == 9999 ? 0 : _bestMs;

    final String unvan;
    if (avgMs <= 20) {
      unvan = 'Orbit Ustası';
    } else if (avgMs <= 50) {
      unvan = 'Senkron Uzmanı';
    } else if (avgMs <= 90) {
      unvan = 'Keskin Refleks';
    } else if (avgMs <= 140) {
      unvan = 'Neredeyse Hizalı';
    } else {
      unvan = 'Kalibrasyon Gerekli';
    }

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _cyan.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    unvan,
                    style: const TextStyle(
                      color: _cyan,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$_totalScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  'puan',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16),
                ),
                const SizedBox(height: 28),
                _buildStatsGrid(avgMs, displayBestMs),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: _resultButton(
                        label: 'Tekrar Oyna',
                        color: _cyan,
                        onTap: _restart,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _resultButton(
                        label: 'Çıkış',
                        color: _magenta,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int avgMs, int bestMs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(children: [
            _statCell('Ort. Hata', '${avgMs}ms', _yellow),
            _statCell('En İyi', '${bestMs}ms', _green),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCell('Mükemmel', '$_perfectCount', _cyan),
            _statCell('Harika', '$_greatCount', _green),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCell('Miss', '$_missCount', Colors.redAccent),
            _statCell('Best Combo', '$_bestCombo', _magenta),
          ]),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _resultButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
