// Full-test version of Tap Rain (Test 26/29).
// 30 seconds, 3 lives. Auto-starts.
// Score = clamp(score / 15 * 100, 0, 100).
// Mid-chain screen — navigates to SpeedMathTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'speed_math_test_screen.dart';

class _RainItem {
  final int id;
  final String emoji;
  final double x; // horizontal position as a fraction 0..1 of play width
  double topFraction;

  _RainItem({
    required this.id,
    required this.emoji,
    required this.x,
    required this.topFraction,
  });
}

class TapRainTestScreen extends StatefulWidget {
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
  final int skyScore;
  final int targetLockScore;
  final int swipeDodgeScore;
  final int colorPanicScore;
  final int dontTapRedScore;
  final int tapTargetScore;
  final int shapeStrikeScore;
  final int memoryFlashScore;
  final int mirrorBrainScore;
  final int sequenceRushScore;
  final int reactionWallScore;
  final int focusHunterScore;
  final int impulseControlScore;

  const TapRainTestScreen({
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
    required this.skyScore,
    required this.targetLockScore,
    required this.swipeDodgeScore,
    required this.colorPanicScore,
    required this.dontTapRedScore,
    required this.tapTargetScore,
    required this.shapeStrikeScore,
    required this.memoryFlashScore,
    required this.mirrorBrainScore,
    required this.sequenceRushScore,
    required this.reactionWallScore,
    required this.focusHunterScore,
    required this.impulseControlScore,
  });

  @override
  State<TapRainTestScreen> createState() => _TRTState();
}

class _TRTState extends State<TapRainTestScreen> {
  static const _maxScore = 15;
  static const _types = ['🍎', '🍊', '⭐', '🔵', '❌'];
  static const _changeTargetEvery = 8;

  int _timeLeft = 30;
  int _score = 0;
  int _lives = 3;
  String _targetType = '🍎';
  final List<_RainItem> _items = [];
  bool _gameEnded = false;
  Timer? _countdownTimer;
  Timer? _spawnTimer;
  Timer? _moveTimer;
  Timer? _targetTimer;
  int _nextId = 0;
  final _rand = Random();
  // Falls start slow and ramp up over the 30s round.
  double _fallSpeed = 0.005;

  @override
  void initState() {
    super.initState();
    _targetType = _types[_rand.nextInt(_types.length - 1)];
    _startTimers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        _fallSpeed = (_fallSpeed + 0.0005).clamp(0.005, 0.016);
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        _items.add(_RainItem(
          id: _nextId++,
          emoji: _types[_rand.nextInt(_types.length)],
          x: _rand.nextDouble(),
          topFraction: 0.0,
        ));
      });
    });
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        for (final item in _items) {
          item.topFraction += _fallSpeed;
        }
        _items.removeWhere((item) => item.topFraction > 1.0);
      });
    });
    _targetTimer = Timer.periodic(
        Duration(seconds: _changeTargetEvery), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        _targetType = _types[_rand.nextInt(_types.length - 1)];
      });
    });
  }

  void _tap(_RainItem item) {
    if (_gameEnded) return;
    setState(() => _items.removeWhere((i) => i.id == item.id));
    if (item.emoji == _targetType) {
      setState(() => _score++);
    } else {
      setState(() => _lives--);
      if (_lives <= 0) {
        _endGame();
      }
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _targetTimer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final tapRainScore = (_score / _maxScore * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SpeedMathTestScreen(
          session:             widget.session,
          reactionScore:       widget.reactionScore,
          stroopScore:         widget.stroopScore,
          memoryScore:         widget.memoryScore,
          sequenceScore:       widget.sequenceScore,
          impulseScore:        widget.impulseScore,
          patternScore:        widget.patternScore,
          circleScore:         widget.circleScore,
          laserScore:          widget.laserScore,
          timingScore:         widget.timingScore,
          pulseScore:          widget.pulseScore,
          balanceScore:        widget.balanceScore,
          dartScore:           widget.dartScore,
          skyScore:            widget.skyScore,
          targetLockScore:     widget.targetLockScore,
          swipeDodgeScore:     widget.swipeDodgeScore,
          colorPanicScore:     widget.colorPanicScore,
          dontTapRedScore:     widget.dontTapRedScore,
          tapTargetScore:      widget.tapTargetScore,
          shapeStrikeScore:    widget.shapeStrikeScore,
          memoryFlashScore:    widget.memoryFlashScore,
          mirrorBrainScore:    widget.mirrorBrainScore,
          sequenceRushScore:   widget.sequenceRushScore,
          reactionWallScore:   widget.reactionWallScore,
          focusHunterScore:    widget.focusHunterScore,
          impulseControlScore: widget.impulseControlScore,
          tapRainScore:        tapRainScore,
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
                    Text('Test 26 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _timeLeft / 30.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFF00B4FF),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_timeLeft s',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.tapRainInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3,
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 18))),
                    ),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('TAP: ',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                  Text(_targetType, style: const TextStyle(fontSize: 28)),
                ],
              ),
              Expanded(
                child: LayoutBuilder(builder: (ctx, constraints) {
                  return Stack(
                    children: [
                      for (final item in List.from(_items))
                        Positioned(
                          left: item.x * (constraints.maxWidth - 36),
                          top: item.topFraction * constraints.maxHeight,
                          child: GestureDetector(
                            onTap: () => _tap(item),
                            child: Text(item.emoji,
                                style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
