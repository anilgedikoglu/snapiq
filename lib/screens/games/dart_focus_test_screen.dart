// Full-test version of Dart Focus (Test 12/12).
// 5 shots, max 100 pts each → normalized to 0-100.
// Navigates to ResultScreen on completion.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import '../../painters/dart_board_painter.dart';
import 'sky_shot_test_screen.dart';

class DartFocusTestScreen extends StatefulWidget {
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

  const DartFocusTestScreen({
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
  });

  @override
  State<DartFocusTestScreen> createState() => _DFTState();
}

class _DFTState extends State<DartFocusTestScreen>
    with TickerProviderStateMixin {
  static const List<Color> _hitColors = [
    Color(0xFF00C853),
    Color(0xFF00B4FF),
    Color(0xFFBB86FC),
    Color(0xFFFDD835),
    Color(0xFFFF7043),
  ];

  // ── Crosshair movement ───────────────────────────────────────────────────────
  Ticker? _crossTicker;
  double _elapsedSec = 0;
  double _realSec    = 0;
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

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMilliseconds;
    final dt = ms - _prevTickMs;
    _prevTickMs = ms;
    if (dt <= 0) return;
    final dtSec = dt / 1000.0;
    _realSec    += dtSec;
    final speedMul = 1.0 + 0.25 * sin(_realSec * 1.05); // peak lowered further
    _elapsedSec += dtSec * speedMul;

    final t = _elapsedSec;
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
      _finish();
    }
  }

  void _finish() {
    final dartScore =
        (_dartScores.fold(0, (a, b) => a + b) / 5).round().clamp(0, 100);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SkyShotTestScreen(
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
          dartScore:     dartScore,
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
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Test 12 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (5 - _shotsLeft) / 5,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFFFF7043),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(S.dartShots(_shotsLeft),
                        style: const TextStyle(
                            color: Color(0xFFFF7043), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.dartInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
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
                          Positioned(
                            left: constraints.maxWidth / 2 +
                                _crossX * boardRadius - 20,
                            top:  constraints.maxHeight / 2 +
                                _crossY * boardRadius - 20,
                            child: const _Crosshair(),
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
                child: Text(
                  S.dartScore(_dartScores.fold(0, (a, b) => a + b)),
                  style: const TextStyle(
                      color: Color(0xFFFF7043),
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

class _Crosshair extends StatelessWidget {
  const _Crosshair();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.3), blurRadius: 10)
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

class _PlusMark extends StatelessWidget {
  final Color color;
  const _PlusMark({required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.6), blurRadius: 8)
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
