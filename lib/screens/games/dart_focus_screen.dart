import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/arcade_result_overlay.dart';
import '../../painters/dart_board_painter.dart';

class DartFocusScreen extends StatefulWidget {
  const DartFocusScreen({super.key});

  @override
  State<DartFocusScreen> createState() => _DartFocusScreenState();
}

class _DartFocusScreenState extends State<DartFocusScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'dart_focus';
  static const _xpReward = 35;
  static const _gameName = 'Dart Focus';

  static const List<Color> _hitColors = [
    Color(0xFF00C853),
    Color(0xFF00B4FF),
    Color(0xFFBB86FC),
    Color(0xFFFDD835),
    Color(0xFFFF7043),
  ];

  // ── Crosshair movement via Ticker + continuous time ─────────────────────────
  Ticker? _crossTicker;
  double _elapsedSec = 0;
  double _realSec    = 0; // wall-clock time for speed modulation
  int    _prevTickMs = 0;
  double _crossX = 0;
  double _crossY = 0;

  // ── Game state ───────────────────────────────────────────────────────────────
  final List<Offset> _dartHits   = [];
  final List<int>    _dartScores = [];
  int  _shotsLeft     = 5;
  int  _lastScore     = 0;
  bool _showLastScore = false;
  bool _gameEnded     = false;

  @override
  void initState() {
    super.initState();
    _crossTicker = createTicker(_onTick)..start();
  }

  // Continuously-accumulating time → three irrational frequency components.
  // Frequencies chosen so no pair has a rational ratio → path never repeats
  // in any reasonable session.
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMilliseconds;
    final dt = ms - _prevTickMs;
    _prevTickMs = ms;
    if (dt <= 0) return;
    final dtSec = dt / 1000.0;
    _realSec    += dtSec;
    // Speed oscillates 0.3x … 1.8x, period ≈ 6 s
    final speedMul = 1.05 + 0.75 * sin(_realSec * 1.05);
    _elapsedSec += dtSec * speedMul;

    final t = _elapsedSec;
    // Spirograph: outer arm R=0.45, inner arm r=0.38 (ratio ≈ 4.3:1)
    // → big sweeping arcs (max radius 0.88) intersecting near center (min 0.02)
    // + tiny 3rd harmonic for texture.  All continuous — no loop jump.
    setState(() {
      _crossX =  0.45 * cos(2.5 * t) + 0.38 * cos(10.75 * t) + 0.05 * cos(17.3 * t);
      _crossY =  0.45 * sin(2.5 * t) - 0.38 * sin(10.75 * t) - 0.05 * sin(17.3 * t);
    });
  }

  @override
  void dispose() {
    _crossTicker?.dispose();
    super.dispose();
  }

  void _shoot(double boardRadius) {
    if (_shotsLeft <= 0 || _gameEnded) return;

    final dist  = sqrt(_crossX * _crossX + _crossY * _crossY);
    final score = (100 - dist * 200).round().clamp(0, 100);

    setState(() {
      _dartHits.add(Offset(_crossX, _crossY));
      _dartScores.add(score);
      _shotsLeft--;
      _lastScore     = score;
      _showLastScore = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showLastScore = false);
    });

    if (_shotsLeft <= 0) {
      setState(() => _gameEnded = true);
      final total = _dartScores.fold(0, (a, b) => a + b);
      _gameOver(total);
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
        onReplay: () { Navigator.pop(context); _restart(); },
        onBack:   () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  void _restart() {
    _dartHits.clear();
    _dartScores.clear();
    setState(() {
      _shotsLeft     = 5;
      _lastScore     = 0;
      _showLastScore = false;
      _gameEnded     = false;
    });
    // Continue from current phase — no reset, no jump.
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
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final boardSize =
                        min(constraints.maxWidth, constraints.maxHeight) * 0.85;
                    final boardRadius = boardSize / 2;
                    return GestureDetector(
                      onTap: () => _shoot(boardRadius),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            painter: DartBoardPainter(),
                            size: Size(boardSize, boardSize),
                          ),
                          // Hit marks
                          ...List.generate(_dartHits.length, (i) {
                            final hit   = _dartHits[i];
                            final color = _hitColors[i % _hitColors.length];
                            return Positioned(
                              left: constraints.maxWidth / 2 +
                                  hit.dx * boardRadius - 10,
                              top:  constraints.maxHeight / 2 +
                                  hit.dy * boardRadius - 10,
                              child: _PlusMark(color: color),
                            );
                          }),
                          // Crosshair
                          Positioned(
                            left: constraints.maxWidth / 2 +
                                _crossX * boardRadius - 20,
                            top:  constraints.maxHeight / 2 +
                                _crossY * boardRadius - 20,
                            child: _Crosshair(),
                          ),
                          if (_showLastScore)
                            Text(
                              '+$_lastScore',
                              style: TextStyle(
                                color: _lastScore > 60
                                    ? const Color(0xFF00C853)
                                    : _lastScore > 30
                                        ? const Color(0xFFFDD835)
                                        : const Color(0xFFFF7043),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.dartShots(_shotsLeft),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16)),
                    Text(
                      S.dartScore(_dartScores.fold(0, (a, b) => a + b)),
                      style: const TextStyle(
                          color: Color(0xFFFF7043),
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
            child: Text('Dart Focus',
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

// ─── Crosshair widget ─────────────────────────────────────────────────────────
class _Crosshair extends StatelessWidget {
  const _Crosshair();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 10)
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 1.5, height: 40,
              color: Colors.white.withValues(alpha: 0.8)),
          Container(width: 40, height: 1.5,
              color: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

// ─── "+" hit marker ───────────────────────────────────────────────────────────
class _PlusMark extends StatelessWidget {
  final Color color;
  const _PlusMark({required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)
              ],
            ),
          ),
          Container(width: 3, height: 16,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          Container(width: 16, height: 3,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
