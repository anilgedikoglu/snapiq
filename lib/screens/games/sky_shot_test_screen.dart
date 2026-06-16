// Full-test version of Sky Shot (Test 13/14).
// 5 shots, max 100 pts each → normalized to 0-100.
// Navigates to TargetLockTestScreen on completion.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'target_lock_test_screen.dart';

class SkyShotTestScreen extends StatefulWidget {
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

  const SkyShotTestScreen({
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
  });

  @override
  State<SkyShotTestScreen> createState() => _SSTState();
}

class _SSTState extends State<SkyShotTestScreen>
    with TickerProviderStateMixin {

  // ── Target movement ──────────────────────────────────────────────────────────
  Ticker? _moveTicker;
  double _targetNorm = 0.3;
  double _phase      = 0.3;
  int    _prevMs     = 0;
  double _speedFactor = 1.0;
  double _targetTopFrac = 0.10; // vertical position, changes each shot
  final _rng = Random();

  // ── Projectile ───────────────────────────────────────────────────────────────
  AnimationController? _projectileCtrl;
  int    _pendingScore = 0;

  // ── Layout ───────────────────────────────────────────────────────────────────
  double _screenWidth = 400;

  // ── Game state ───────────────────────────────────────────────────────────────
  int  _shotsLeft      = 5;
  int  _totalScore     = 0;
  bool _canShoot       = true;
  bool _gameEnded      = false;
  int  _lastShotScore  = 0;
  bool _showLastScore  = false;
  bool _showHitEffect  = false;

  @override
  void initState() {
    super.initState();
    _moveTicker = createTicker(_onMoveTick)..start();
  }

  void _onMoveTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMilliseconds;
    final dt = ms - _prevMs;
    _prevMs = ms;
    if (dt <= 0) return;
    const basePeriod = 2400.0;
    final advance = dt * _speedFactor / basePeriod;
    _phase = (_phase + advance) % 2.0;
    final x = _phase <= 1.0 ? _phase : 2.0 - _phase;
    setState(() => _targetNorm = x);
  }

  @override
  void dispose() {
    _moveTicker?.dispose();
    _projectileCtrl?.dispose();
    super.dispose();
  }

  void _shoot() {
    if (!_canShoot || _gameEnded) return;
    _canShoot = false;

    // Score computed at fire time, predicted 500 ms ahead
    {
      const animMs = 500.0;
      final advance     = animMs * _speedFactor / 2400.0;
      final futurePhase = (_phase + advance) % 2.0;
      final futureNorm  = futurePhase <= 1.0 ? futurePhase : 2.0 - futurePhase;
      final tl = futureNorm * (_screenWidth - 60);
      final pl = _screenWidth / 2 - 4;
      final pr = _screenWidth / 2 + 4;
      final os = pl > tl      ? pl      : tl;
      final oe = pr < tl + 60 ? pr      : tl + 60;
      final ov = oe - os;
      _pendingScore = ov >= 6 ? 100 : ov > 0 ? 70 : 0;
    }

    _projectileCtrl?.dispose();
    _projectileCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _projectileCtrl!.addListener(() { if (mounted) setState(() {}); });
    _projectileCtrl!.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      final score = _pendingScore;
      if (!mounted) return;
      setState(() {
        _totalScore     += score;
        _lastShotScore   = score;
        _showLastScore   = true;
        _shotsLeft--;
        _canShoot        = true;
        _showHitEffect   = score > 0;
      });
      _speedFactor += 0.3;
      // Move the target to a new height for the next shot.
      _targetTopFrac = 0.06 + _rng.nextDouble() * 0.40;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() { _showHitEffect = false; });
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showLastScore = false);
      });
      if (_shotsLeft <= 0) {
        setState(() => _gameEnded = true);
        _moveTicker?.stop();
        _finish();
      }
    });
    _projectileCtrl!.forward();
  }

  Future<void> _finish() async {
    final skyScore = (_totalScore / 5).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TargetLockTestScreen(
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
          balanceScore:  widget.balanceScore,
          dartScore:     widget.dartScore,
          skyScore:      skyScore,
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
          child: Column(
            children: [
              // Progress header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Test 13 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (5 - _shotsLeft) / 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFF00B4FF),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(S.dartShots(_shotsLeft),
                        style: const TextStyle(
                            color: Color(0xFF00B4FF), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.skyInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Game area
              Expanded(
                child: GestureDetector(
                  onTap: _shoot,
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      _screenWidth = w;
                      final targetX = _targetNorm * (w - 60);
                      // Projectile travels from the cannon up to the target's
                      // current height (which changes every shot).
                      final targetCenterY = h * _targetTopFrac + 20;
                      final projY = _projectileCtrl != null
                          ? (h - 50) +
                              (targetCenterY - (h - 50)) * _projectileCtrl!.value
                          : h - 50.0;

                      return Stack(
                        children: [
                          // Target
                          Positioned(
                            left: targetX,
                            top: h * _targetTopFrac,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_showHitEffect)
                                  Container(
                                    width: 80, height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF7043)
                                          .withValues(alpha: 0.45),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF7043)
                                              .withValues(alpha: 0.7),
                                          blurRadius: 24, spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  width: 60, height: 40,
                                  decoration: BoxDecoration(
                                    color: _showHitEffect
                                        ? const Color(0xFFFF7043).withValues(alpha: 0.5)
                                        : const Color(0xFF00B4FF).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: _showHitEffect
                                          ? const Color(0xFFFF7043)
                                          : const Color(0xFF00B4FF),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_showHitEffect
                                                ? const Color(0xFFFF7043)
                                                : const Color(0xFF00B4FF))
                                            .withValues(alpha: 0.5),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _showHitEffect ? '💥' : '🛸',
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Projectile
                          if (_projectileCtrl != null &&
                              _projectileCtrl!.isAnimating)
                            Positioned(
                              left: w / 2 - 4,
                              top: projY,
                              child: Container(
                                width: 8, height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDD835),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFDD835)
                                          .withValues(alpha: 0.8),
                                      blurRadius: 10, spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Cannon
                          Positioned(
                            bottom: 16,
                            left: w / 2 - 20,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF00C853), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C853)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_upward,
                                  color: Color(0xFF00C853), size: 22),
                            ),
                          ),
                          // Score popup
                          if (_showLastScore)
                            Center(
                              child: Text(
                                '+$_lastShotScore',
                                style: TextStyle(
                                  color: _lastShotScore > 60
                                      ? const Color(0xFF00C853)
                                      : _lastShotScore > 30
                                          ? const Color(0xFFFDD835)
                                          : const Color(0xFFFF7043),
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(color: Colors.black45, blurRadius: 8)
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Text(
                  S.skyScore(_totalScore),
                  style: const TextStyle(
                      color: Color(0xFF00B4FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
