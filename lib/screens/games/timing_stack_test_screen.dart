// Full-test version of Timing Stack (Test 9/9).
// score = min(100, placed * 10). Navigates to ResultScreen on game-over.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import 'pulse_stop_test_screen.dart';

class _Block {
  final double left;
  final double width;
  final Color color;
  const _Block({required this.left, required this.width, required this.color});
}

// ─── CustomPainter ────────────────────────────────────────────────────────────
class _StackPainter extends CustomPainter {
  final List<_Block> placedBlocks;
  /// Fixed initial base — never changes after _initGame.
  final double baseLeft;
  final double baseWidth;
  /// Current moving-bar reference (shrinks with each placement).
  final double blockWidth;
  final double currLeft;
  final double barBottom;
  final Color barColor;
  final bool gameOver;
  final int score;
  static const double bh = 22.0;
  static const int maxVisible = 12;

  const _StackPainter({
    required this.placedBlocks,
    required this.baseLeft,
    required this.baseWidth,
    required this.blockWidth,
    required this.currLeft,
    required this.barBottom,
    required this.barColor,
    required this.gameOver,
    required this.score,
  });

  void _drawBlock(Canvas canvas, double left, double bottom, double width,
      Color color, double screenH,
      {bool isBase = false}) {
    final top = screenH - bottom - (bh - 2);
    final rect = RRect.fromLTRBR(
      left, top, left + width, top + (bh - 2),
      const Radius.circular(4),
    );
    if (isBase) {
      canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFF00B4FF).withValues(alpha: 0.4)
            ..style = PaintingStyle.fill);
      canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFF00B4FF).withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    } else {
      canvas.drawRRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawRRect(
          rect, Paint()..color = color.withValues(alpha: 0.85));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final visibleCount = min(placedBlocks.length, maxVisible);
    final startIdx = placedBlocks.length - visibleCount;

    // Base platform — always the original wide one (never mutated).
    _drawBlock(canvas, baseLeft, 0, baseWidth, Colors.white, h, isBase: true);

    // Placed blocks: i=0 → oldest (bottom=1*bh), i=n-1 → newest (top=n*bh).
    for (int i = 0; i < visibleCount; i++) {
      final block = placedBlocks[startIdx + i];
      _drawBlock(canvas, block.left, (i + 1) * bh, block.width, block.color, h);
    }

    // Moving bar — uses current blockWidth (shrinks with each tap).
    if (!gameOver) {
      final top = h - barBottom - (bh - 2);
      final rect = RRect.fromLTRBR(
        currLeft, top, currLeft + blockWidth, top + (bh - 2),
        const Radius.circular(4),
      );
      canvas.drawRRect(
          rect,
          Paint()
            ..color = barColor.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawRRect(
          rect, Paint()..color = barColor.withValues(alpha: 0.9));
    }

    // Score watermark
    final tp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(
          color: Color(0x1FFFFFFF),
          fontSize: 120,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_StackPainter old) => true;
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class TimingStackTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;
  final int circleScore;
  final int laserScore;

  const TimingStackTestScreen({
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
  });

  @override
  State<TimingStackTestScreen> createState() => _TSTState();
}

class _TSTState extends State<TimingStackTestScreen>
    with SingleTickerProviderStateMixin {
  static const _blockHeight = 22.0;
  static const _maxVisible  = 12;
  static const List<Color> _palette = [
    Color(0xFF00B4FF), Color(0xFF03DAC6), Color(0xFF00C853),
    Color(0xFFFDD835), Color(0xFFFF7043), Color(0xFFE91E63), Color(0xFFBB86FC),
  ];

  late AnimationController _slideCtrl;

  // Fixed base — set once in _initGame, never touched again.
  double _baseLeft  = 0;
  double _baseWidth = 260;

  // Moving-bar reference — shrinks with every successful tap.
  double _prevLeft   = 0;
  double _blockWidth = 260;

  bool _initialized = false;
  int  _score       = 0;
  bool _gameOver    = false;
  final List<_Block> _placedBlocks = [];
  int    _colorIndex  = 0;
  double _screenWidth = 0;
  int    _durationMs  = 1500;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
    _slideCtrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _initGame(double screenWidth) {
    _screenWidth = screenWidth;
    final w = screenWidth * 0.65;
    final l = (screenWidth - w) / 2;
    // Fixed base — never updated after this point.
    _baseLeft  = l;
    _baseWidth = w;
    // Moving-bar reference starts at same position.
    _prevLeft   = l;
    _blockWidth = w;
    _initialized = true;
    _slideCtrl.repeat(reverse: true);
  }

  double get _currLeft => _slideCtrl.value * (_screenWidth - _blockWidth);

  void _onTap() {
    if (_gameOver) return;
    final currL = _currLeft;
    final currR = currL + _blockWidth;
    final prevR = _prevLeft + _blockWidth;

    final overlapLeft  = currL > _prevLeft ? currL : _prevLeft;
    final overlapRight = currR < prevR     ? currR : prevR;
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 8) {
      _slideCtrl.stop();
      setState(() => _gameOver = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _finish();
      });
      return;
    }

    final color = _palette[_colorIndex % _palette.length];
    _colorIndex++;
    _placedBlocks.add(_Block(left: overlapLeft, width: overlap, color: color));

    // Advance moving-bar reference — base stays untouched.
    _prevLeft   = overlapLeft;
    _blockWidth = overlap;
    _score++;
    _durationMs = (_durationMs - 50).clamp(400, 1500);
    _slideCtrl.duration = Duration(milliseconds: _durationMs);
    _slideCtrl.reset();
    _slideCtrl.repeat(reverse: true);
    setState(() {});
  }

  Future<void> _finish() async {
    final timingScore = (_score * 10).clamp(0, 100);

    await AdService().incrementGameCountAndMaybeShow();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PulseStopTestScreen(
          session:       widget.session,
          reactionScore: widget.reactionScore,
          stroopScore:   widget.stroopScore,
          memoryScore:   widget.memoryScore,
          sequenceScore: widget.sequenceScore,
          impulseScore:  widget.impulseScore,
          patternScore:  widget.patternScore,
          circleScore:   widget.circleScore,
          laserScore:    widget.laserScore,
          timingScore:   timingScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barColor     = _palette[_colorIndex % _palette.length];
    final visibleCount = min(_placedBlocks.length, _maxVisible);
    final barBottom    = (visibleCount + 1) * _blockHeight;

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
                    Text('Test 9 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_score / 10).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFF03DAC6),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF03DAC6), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.timingInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _onTap,
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      if (!_initialized) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && !_initialized) {
                            setState(() => _initGame(constraints.maxWidth));
                          }
                        });
                        return const SizedBox.expand();
                      }
                      return CustomPaint(
                        painter: _StackPainter(
                          placedBlocks: List.unmodifiable(_placedBlocks),
                          baseLeft:   _baseLeft,
                          baseWidth:  _baseWidth,
                          blockWidth: _blockWidth,
                          currLeft:   _currLeft,
                          barBottom:  barBottom,
                          barColor:   barColor,
                          gameOver:   _gameOver,
                          score:      _score,
                        ),
                        child: const SizedBox.expand(),
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
}
