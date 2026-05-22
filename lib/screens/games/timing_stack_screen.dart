import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

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
class TimingStackScreen extends StatefulWidget {
  const TimingStackScreen({super.key});

  @override
  State<TimingStackScreen> createState() => _TimingStackScreenState();
}

class _TimingStackScreenState extends State<TimingStackScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId   = 'timing_stack';
  static const _xpReward = 30;
  static const _gameName = 'Timing Stack';
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
  int    _colorIndex = 0;
  double _screenWidth = 0;
  int    _durationMs  = 1500;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: _durationMs));
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
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _gameOverDialog(_score);
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

  Future<void> _gameOverDialog(int score) async {
    final s = await StorageService.getInstance();
    final prevBest = s.arcadeBestScore(_gameId);
    final isNewBest = score > prevBest;
    await s.saveArcadeBestScore(_gameId, score);
    await s.saveXP(_xpReward);
    await s.saveLevel(XpService.levelForXp(s.xp));
    await AchievementService.checkArcadeAchievements(_gameId, score, s);
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ArcadeResultOverlay(
        gameName: _gameName, score: score,
        bestScore: isNewBest ? score : prevBest,
        xpGained: _xpReward, isNewBest: isNewBest,
        onReplay: () { Navigator.pop(context); _restart(); },
        onBack:   () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  void _restart() {
    _slideCtrl.stop();
    _placedBlocks.clear();
    setState(() {
      _score = 0; _gameOver = false; _colorIndex = 0;
      _durationMs = 1500; _initialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final barColor     = _palette[_colorIndex % _palette.length];
    final visibleCount = min(_placedBlocks.length, _maxVisible);
    final barBottom    = (visibleCount + 1) * _blockHeight;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
            child: Text('Timing Stack',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('Skor: $_score',
                style: const TextStyle(color: Color(0xFF03DAC6),
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
