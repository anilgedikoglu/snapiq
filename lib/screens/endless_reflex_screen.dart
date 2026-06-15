import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import '../services/ad_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import 'home_screen.dart';

enum _MiniType { tapGreen, avoidShape, sequence }

class EndlessReflexScreen extends StatefulWidget {
  const EndlessReflexScreen({super.key});

  @override
  State<EndlessReflexScreen> createState() => _EndlessReflexScreenState();
}

class _EndlessReflexScreenState extends State<EndlessReflexScreen> {
  int _lives = 3;
  int _round = 0;
  int _survivalSecs = 0;
  bool _gameOver = false;
  bool _started = false;
  Timer? _clockTimer;
  Timer? _roundTimer;
  final Random _rand = Random();

  // Current challenge
  _MiniType _currentType = _MiniType.tapGreen;
  bool _showTarget = false;
  bool _roundActive = false;
  bool _tapped = false;

  // For tapGreen
  Color _circleColor = Colors.red;
  Offset _circlePos = const Offset(0.5, 0.5);

  // For avoidShape — shape to avoid = square; circle is safe
  bool _shapeIsCircle = true;

  // For sequence mini
  List<int> _seqNumbers = [];
  int _seqExpected = 0;
  List<int> _seqChoices = [];

  double get _speed => 1.0 - (_round * 0.03).clamp(0.0, 0.6);

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      _started = true;
      _lives = 3;
      _round = 0;
      _survivalSecs = 0;
      _gameOver = false;
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_gameOver) setState(() => _survivalSecs++);
    });
    _nextRound();
  }

  void _nextRound() {
    if (_gameOver || !mounted) return;
    _round++;
    _tapped = false;
    _roundActive = false;
    _showTarget = false;

    final types = _MiniType.values;
    _currentType = types[_rand.nextInt(types.length)];

    switch (_currentType) {
      case _MiniType.tapGreen:
        _setupTapGreen();
      case _MiniType.avoidShape:
        _setupAvoidShape();
      case _MiniType.sequence:
        _setupSequence();
    }
  }

  void _setupTapGreen() {
    // Show red first, switch to green after 800-1500ms
    setState(() {
      _circleColor = Colors.redAccent;
      _circlePos = Offset(
          0.2 + _rand.nextDouble() * 0.6, 0.2 + _rand.nextDouble() * 0.4);
      _showTarget = true;
      _roundActive = false;
    });
    final delay = (800 + _rand.nextInt(700)) * _speed;
    Future.delayed(Duration(milliseconds: delay.round()), () {
      if (!mounted || _gameOver) return;
      setState(() {
        _circleColor = const Color(0xFF00C853);
        _roundActive = true;
      });
      // Miss window
      _roundTimer = Timer(
          Duration(milliseconds: (900 * _speed).round()), () {
        if (!_tapped && !_gameOver) {
          _loseLife();
        } else {
          _nextRound();
        }
      });
    });
  }

  void _setupAvoidShape() {
    _shapeIsCircle = _rand.nextBool();
    setState(() {
      _showTarget = true;
      _roundActive = true;
    });
    _roundTimer = Timer(
        Duration(milliseconds: (1200 * _speed).round()), () {
      if (!_tapped && !_gameOver) {
        // Didn't tap — if shape was circle (target), miss
        if (_shapeIsCircle) {
          _loseLife();
        } else {
          _nextRound();
        }
      }
    });
  }

  void _setupSequence() {
    // Show 3 numbers, user picks which comes next
    final start = _rand.nextInt(10);
    _seqNumbers = [start, start + 1, start + 2];
    _seqExpected = start + 3;
    final wrong1 = start + _rand.nextInt(3) + 4;
    final wrong2 = start - _rand.nextInt(3) - 1;
    _seqChoices = [_seqExpected, wrong1, wrong2]..shuffle(_rand);
    setState(() {
      _showTarget = true;
      _roundActive = true;
    });
    _roundTimer = Timer(
        Duration(milliseconds: (3000 * _speed).round()), () {
      if (!_tapped && !_gameOver) _loseLife();
    });
  }

  void _loseLife() {
    if (_gameOver) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _lives--;
      _showTarget = false;
      _roundActive = false;
    });
    if (_lives <= 0) {
      _endGame();
    } else {
      Future.delayed(const Duration(milliseconds: 400), _nextRound);
    }
  }

  void _endGame() {
    _roundTimer?.cancel();
    _clockTimer?.cancel();
    setState(() => _gameOver = true);
    _checkAchievements();
    AdService().showInterstitialIfNeeded();
  }

  Future<void> _checkAchievements() async {
    if (_survivalSecs >= 60) {
      final s = await StorageService.getInstance();
      await AchievementService.unlockEndless60(s);
    }
  }

  void _onTapGreen() {
    if (!_roundActive || _tapped || _gameOver) return;
    _tapped = true;
    _roundTimer?.cancel();
    if (_circleColor == const Color(0xFF00C853)) {
      HapticFeedback.selectionClick();
      _nextRound();
    } else {
      _loseLife();
    }
  }

  void _onTapAvoidShape(bool tapped) {
    if (!_roundActive || _tapped || _gameOver) return;
    _tapped = true;
    _roundTimer?.cancel();
    if (_shapeIsCircle && tapped) {
      // Correct — tapped circle
      HapticFeedback.selectionClick();
      _nextRound();
    } else if (!_shapeIsCircle && !tapped) {
      // Correct — didn't tap square (handled by timer)
      _nextRound();
    } else {
      _loseLife();
    }
  }

  void _onSequenceChoice(int value) {
    if (!_roundActive || _tapped || _gameOver) return;
    _tapped = true;
    _roundTimer?.cancel();
    if (value == _seqExpected) {
      HapticFeedback.selectionClick();
      _nextRound();
    } else {
      _loseLife();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _roundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildIntro();
    if (_gameOver) return _buildGameOver();
    return _buildGame();
  }

  Widget _buildIntro() {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('♾️',
                    style: TextStyle(fontSize: 64)),
                const SizedBox(height: 20),
                Text(S.endlessTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  '3 canın var. Mini görevleri tamamla, hayatta kal!\nHız her turda artar.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                NeonButton(
                  text: S.start,
                  onPressed: _startGame,
                  color: const Color(0xFF00C853),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.play_arrow_rounded,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  text: S.back,
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white38,
                  width: double.infinity,
                  icon: Icons.arrow_back_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💀',
                    style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('Oyun Bitti',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(S.endlessSeconds(_survivalSecs),
                    style: const TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 48,
                        fontWeight: FontWeight.bold)),
                Text(S.endlessSurvived,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 8),
                Text(S.endlessRoundsDone(_round),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 40),
                NeonButton(
                  text: S.tryAgain,
                  onPressed: _startGame,
                  color: const Color(0xFF00C853),
                  width: double.infinity,
                  height: 52,
                  icon: Icons.refresh_rounded,
                ),
                const SizedBox(height: 12),
                NeonButton(
                  text: S.menu,
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HomeScreen()),
                    (_) => false,
                  ),
                  color: const Color(0xFF00B4FF),
                  width: double.infinity,
                  height: 52,
                  icon: Icons.home_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame() {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHUD(),
              Expanded(child: _buildChallenge()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
                3,
                (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.favorite,
                        color: i < _lives
                            ? Colors.redAccent
                            : Colors.white12,
                        size: 22,
                      ),
                    )),
          ),
          Text('$_survivalSecs s',
              style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(S.endlessRound(_round),
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildChallenge() {
    switch (_currentType) {
      case _MiniType.tapGreen:
        return _buildTapGreenChallenge();
      case _MiniType.avoidShape:
        return _buildAvoidShapeChallenge();
      case _MiniType.sequence:
        return _buildSequenceChallenge();
    }
  }

  Widget _buildTapGreenChallenge() {
    return LayoutBuilder(builder: (ctx, constraints) {
      return GestureDetector(
        onTap: _onTapGreen,
        child: Stack(
          children: [
            Container(color: Colors.transparent),
            if (_showTarget)
              Positioned(
                left: _circlePos.dx * constraints.maxWidth - 50,
                top: _circlePos.dy * constraints.maxHeight - 50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _circleColor.withValues(alpha: 0.25),
                    border: Border.all(color: _circleColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: _circleColor.withValues(alpha: 0.4),
                          blurRadius: 20)
                    ],
                  ),
                ),
              ),
            Center(
              child: Text(S.endlessCircle,
                  style: const TextStyle(
                      color: Colors.white30, fontSize: 12)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAvoidShapeChallenge() {
    return GestureDetector(
      onTap: () => _onTapAvoidShape(true),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.endlessShape,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (_showTarget)
              _shapeIsCircle
                  ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C853).withValues(alpha: 0.2),
                        border: Border.all(
                            color: const Color(0xFF00C853), width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF00C853)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20)
                        ],
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFBB86FC).withValues(alpha: 0.2),
                        border: Border.all(
                            color: const Color(0xFFBB86FC), width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequenceChallenge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(S.endlessSeq,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _seqNumbers
                .map((n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$n',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          const Text('... ?',
              style: TextStyle(color: Colors.white54, fontSize: 24)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _seqChoices
                .map((n) => GestureDetector(
                      onTap: () => _onSequenceChoice(n),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4FF)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF00B4FF)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Center(
                          child: Text(
                            '$n',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
