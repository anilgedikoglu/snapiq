import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';
import '../../painters/dart_board_painter.dart';

class DartFocusScreen extends StatefulWidget {
  const DartFocusScreen({super.key});

  @override
  State<DartFocusScreen> createState() => _DartFocusScreenState();
}

class _DartFocusScreenState extends State<DartFocusScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId = 'dart_focus';
  static const _xpReward = 35;
  static const _gameName = 'Dart Focus';

  late AnimationController _ctrl;
  final _rand = Random();

  List<Offset> _dartHits = []; // normalized -1..1
  List<int> _dartScores = [];
  int _shotsLeft = 5;
  double _crossX = 0;
  double _crossY = 0;
  double _noiseX = 0;
  double _noiseY = 0;
  int _lastScore = 0;
  bool _showLastScore = false;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _ctrl.addListener(_updateCross);

    // Periodic noise
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || _gameEnded) return false;
      setState(() {
        _noiseX = (_rand.nextDouble() - 0.5) * 0.2;
        _noiseY = (_rand.nextDouble() - 0.5) * 0.2;
      });
      return true;
    });
  }

  void _updateCross() {
    if (!mounted) return;
    final t = _ctrl.value * 2 * pi;
    setState(() {
      _crossX = sin(t * 2.3 + 0.5) * 0.4 + _noiseX;
      _crossY = sin(t * 1.7) * 0.4 + _noiseY;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _shoot(double boardRadius) {
    if (_shotsLeft <= 0 || _gameEnded) return;

    final dist = sqrt(_crossX * _crossX + _crossY * _crossY);
    final score = (100 - dist * 200).round().clamp(0, 100);

    setState(() {
      _dartHits.add(Offset(_crossX, _crossY));
      _dartScores.add(score);
      _shotsLeft--;
      _lastScore = score;
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
    setState(() {
      _dartHits = [];
      _dartScores = [];
      _shotsLeft = 5;
      _lastScore = 0;
      _showLastScore = false;
      _gameEnded = false;
      _noiseX = 0;
      _noiseY = 0;
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
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final boardSize = min(constraints.maxWidth, constraints.maxHeight) * 0.85;
                    final boardRadius = boardSize / 2;
                    return GestureDetector(
                      onTap: () => _shoot(boardRadius),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Board
                          CustomPaint(
                            painter: DartBoardPainter(),
                            size: Size(boardSize, boardSize),
                          ),
                          // Hit marks
                          ...List.generate(_dartHits.length, (i) {
                            final hit = _dartHits[i];
                            return Positioned(
                              left: constraints.maxWidth / 2 +
                                  hit.dx * boardRadius -
                                  5,
                              top: constraints.maxHeight / 2 +
                                  hit.dy * boardRadius -
                                  5,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7043),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF7043)
                                          .withValues(alpha: 0.7),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Crosshair
                          Positioned(
                            left: constraints.maxWidth / 2 +
                                _crossX * boardRadius -
                                20,
                            top: constraints.maxHeight / 2 +
                                _crossY * boardRadius -
                                20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 10)
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 1.5,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 1.5,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Score popup
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
                    Text(
                      'Atışlar: $_shotsLeft',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      'Puan: ${_dartScores.fold(0, (a, b) => a + b)}',
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
