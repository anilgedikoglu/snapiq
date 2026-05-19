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

class TimingStackScreen extends StatefulWidget {
  const TimingStackScreen({super.key});

  @override
  State<TimingStackScreen> createState() => _TimingStackScreenState();
}

class _TimingStackScreenState extends State<TimingStackScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId = 'timing_stack';
  static const _xpReward = 30;
  static const _gameName = 'Timing Stack';

  static const _blockHeight = 22.0;
  static const List<Color> _palette = [
    Color(0xFF00B4FF),
    Color(0xFF03DAC6),
    Color(0xFF00C853),
    Color(0xFFFDD835),
    Color(0xFFFF7043),
    Color(0xFFE91E63),
    Color(0xFFBB86FC),
  ];

  late AnimationController _slideCtrl;
  double _blockWidth = 260;
  double _prevLeft = 0; // set in first build
  bool _initialized = false;
  int _score = 0;
  bool _gameOver = false;
  bool _gameStarted = false;
  List<_Block> _placedBlocks = [];
  int _colorIndex = 0;
  double _screenWidth = 0;
  int _durationMs = 1500;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
    _slideCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _initGame(double screenWidth) {
    _screenWidth = screenWidth;
    _blockWidth = screenWidth * 0.65;
    _prevLeft = (screenWidth - _blockWidth) / 2;
    _initialized = true;
  }

  double get _currLeft {
    // Animate from 0 to screenWidth - blockWidth and back
    final maxLeft = _screenWidth - _blockWidth;
    return _slideCtrl.value * maxLeft;
  }

  void _onTap() {
    if (_gameOver) return;

    if (!_gameStarted) {
      _gameStarted = true;
      _slideCtrl.repeat(reverse: true);
      return;
    }

    final currL = _currLeft;
    final currR = currL + _blockWidth;
    final prevR = _prevLeft + _blockWidth;

    // Calculate overlap
    final overlapLeft = currL > _prevLeft ? currL : _prevLeft;
    final overlapRight = currR < prevR ? currR : prevR;
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 8) {
      // Game over
      _slideCtrl.stop();
      setState(() => _gameOver = true);
      _triggerGameOver();
      return;
    }

    // Place block
    final color = _palette[_colorIndex % _palette.length];
    _colorIndex++;
    _placedBlocks.add(
        _Block(left: overlapLeft, width: overlap, color: color));

    // Update for next block
    _prevLeft = overlapLeft;
    _blockWidth = overlap;
    _score++;
    _durationMs = (_durationMs - 50).clamp(400, 1500);
    _slideCtrl.duration = Duration(milliseconds: _durationMs);
    _slideCtrl.reset();
    _slideCtrl.repeat(reverse: true);

    setState(() {});
  }

  void _triggerGameOver() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _gameOverDialog(_score);
    });
  }

  Future<void> _gameOverDialog(int score) async {
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
        onReplay: () {
          Navigator.pop(context);
          _restart();
        },
        onBack: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _restart() {
    _slideCtrl.stop();
    setState(() {
      _score = 0;
      _gameOver = false;
      _gameStarted = false;
      _placedBlocks = [];
      _colorIndex = 0;
      _durationMs = 1500;
      _initialized = false;
    });
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

                      final h = constraints.maxHeight;
                      final visibleBlocks = _placedBlocks.reversed.take(12).toList().reversed.toList();
                      const maxVisible = 12;

                      return Stack(
                        children: [
                          // Background lanes
                          Positioned.fill(
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                          // Placed blocks (stack from bottom)
                          ...List.generate(visibleBlocks.length, (i) {
                            final block = visibleBlocks[i];
                            final fromBottom = (visibleBlocks.length - i) * _blockHeight;
                            return Positioned(
                              left: block.left,
                              bottom: fromBottom - _blockHeight,
                              width: block.width,
                              height: _blockHeight - 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: block.color.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                        color: block.color.withValues(alpha: 0.4),
                                        blurRadius: 6)
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Base platform
                          Positioned(
                            left: _prevLeft,
                            bottom: 0,
                            width: _blockWidth,
                            height: _blockHeight - 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4FF).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFF00B4FF)
                                        .withValues(alpha: 0.7)),
                              ),
                            ),
                          ),
                          // Moving block (only show if game started)
                          if (_gameStarted && !_gameOver)
                            Positioned(
                              left: _currLeft,
                              top: h * 0.1,
                              width: _blockWidth,
                              height: _blockHeight - 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _palette[_colorIndex % _palette.length]
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _palette[_colorIndex % _palette.length]
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2)
                                  ],
                                ),
                              ),
                            ),
                          // Score
                          Center(
                            child: Text(
                              '$_score',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.15),
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Start instruction
                          if (!_gameStarted)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 40),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 28, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF03DAC6)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFF03DAC6)
                                              .withValues(alpha: 0.5)),
                                    ),
                                    child: const Text(
                                      'DOKUN!',
                                      style: TextStyle(
                                          color: Color(0xFF03DAC6),
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Bloğu hizalamak için dokun',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          // Max visible indicator
                          if (_placedBlocks.length >= maxVisible)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Text('↑',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 18)),
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
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'Skor: $_score',
              style: const TextStyle(
                  color: Color(0xFF03DAC6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
