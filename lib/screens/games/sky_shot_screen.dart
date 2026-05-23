import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/arcade_result_overlay.dart';

class SkyShotScreen extends StatefulWidget {
  const SkyShotScreen({super.key});

  @override
  State<SkyShotScreen> createState() => _SkyShotScreenState();
}

class _SkyShotScreenState extends State<SkyShotScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'sky_shot';
  static const _xpReward = 30;
  static const _gameName = 'Sky Shot';

  // ── Target continuous movement via Ticker ──────────────────────────────────
  Ticker? _moveTicker;
  double _targetNorm = 0.3; // 0..1 normalized X
  double _phase = 0.3;      // 0..2 triangle-wave phase
  int    _prevMs = 0;
  double _speedFactor = 1.0; // increases 0.3 per shot (base period = 2400ms)

  // ── Projectile ─────────────────────────────────────────────────────────────
  AnimationController? _projectileCtrl;
  int    _pendingScore = 0; // computed at fire time, applied at anim end

  // ── Layout (set in build, used in hit detection) ────────────────────────────
  double _screenWidth = 400;

  // ── Game state ──────────────────────────────────────────────────────────────
  int  _shotsLeft  = 5;
  int  _totalScore = 0;
  List<int> _shotScores = [];
  bool _canShoot   = true;
  bool _gameEnded  = false;
  int  _lastShotScore = 0;
  bool _showLastScore = false;
  bool _showHitEffect = false;

  @override
  void initState() {
    super.initState();
    _moveTicker = createTicker(_onMoveTick)..start();
  }

  // Smooth triangle-wave movement — never resets position.
  void _onMoveTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMilliseconds;
    final dt = ms - _prevMs;
    _prevMs = ms;
    if (dt <= 0) return;

    // basePeriod=2400ms for a full left→right trip; speedFactor increases per shot.
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

    // ── Score based on predicted position at anim end (200 ms from now) ─────
    {
      const animMs = 500.0;
      final advance    = animMs * _speedFactor / 2400.0;
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
        _totalScore += score;
        _shotScores.add(score);
        _lastShotScore = score;
        _showLastScore = true;
        _shotsLeft--;
        _canShoot = true;
        _showHitEffect = score > 0;
      });

      // Speed up target by 30% per shot (no position reset).
      _speedFactor += 0.3;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() { _showHitEffect = false; });
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showLastScore = false);
      });

      if (_shotsLeft <= 0) {
        setState(() => _gameEnded = true);
        _moveTicker?.stop();
        _gameOver(_totalScore);
      }
    });
    _projectileCtrl!.forward();
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
        onReplay: () { Navigator.pop(context); _restart(); },
        onBack:   () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  void _restart() {
    _projectileCtrl?.dispose();
    _projectileCtrl = null;
    setState(() {
      _shotsLeft = 5;
      _totalScore = 0;
      _shotScores = [];
      _canShoot = true;
      _gameEnded = false;
      _lastShotScore = 0;
      _showLastScore = false;
      _showHitEffect = false;
      _speedFactor = 1.0;
      _phase = 0.3;
      _prevMs = 0;
    });
    _moveTicker?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: GestureDetector(
                  onTap: _shoot,
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      _screenWidth = w; // store for pixel-accurate hit detection
                      final targetX = _targetNorm * (w - 60);
                      final projY = _projectileCtrl != null
                          ? h - (h * 0.9 * _projectileCtrl!.value) - 30
                          : h - 50.0;

                      return Stack(
                        children: [
                          // Target UFO
                          Positioned(
                            left: targetX,
                            top: h * 0.08,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Hit flash glow
                                if (_showHitEffect)
                                  Container(
                                    width: 80,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF7043)
                                          .withValues(alpha: 0.45),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF7043)
                                              .withValues(alpha: 0.7),
                                          blurRadius: 24,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  width: 60,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _showHitEffect
                                        ? const Color(0xFFFF7043)
                                            .withValues(alpha: 0.5)
                                        : const Color(0xFF00B4FF)
                                            .withValues(alpha: 0.2),
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
                                width: 8,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDD835),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFDD835)
                                          .withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Cannon at bottom
                          Positioned(
                            bottom: 16,
                            left: w / 2 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853)
                                    .withValues(alpha: 0.2),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Text(
                          i < _shotsLeft ? '🚀' : '⭕',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Text(
                      S.skyScore(_totalScore),
                      style: const TextStyle(
                          color: Color(0xFF00B4FF),
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
            child: Text('Sky Shot',
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
