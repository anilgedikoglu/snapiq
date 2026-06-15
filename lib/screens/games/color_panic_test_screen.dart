// Full-test version of Color Panic (Test 16/17).
// 20 rounds, 3 lives. Score = correct/20 * 100.
// Navigates to DontTapRedTestScreen on completion.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'dont_tap_red_test_screen.dart';

class ColorPanicTestScreen extends StatefulWidget {
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

  const ColorPanicTestScreen({
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
  });

  @override
  State<ColorPanicTestScreen> createState() => _CPTState();
}

class _CPTState extends State<ColorPanicTestScreen> {
  static const _totalRounds = 20;

  static const _colors = [
    Colors.red, Colors.blue, Colors.green,
    Colors.yellow, Colors.purple, Colors.orange,
  ];

  int _lives     = 3;
  int _correct   = 0;
  int _answered  = 0;
  int _intervalMs = 1200;
  String _word   = '';
  Color  _inkColor = Colors.white;
  bool   _isMatch  = false;
  bool   _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateRound();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateRound() {
    final words   = S.colorPanicWords;
    final wordIdx = _rand.nextInt(words.length);
    // ~50% of rounds force a real match, otherwise the ink is random.
    // Without this the match chance is only 1/6, so "DIFFERENT" is almost
    // always correct and the test fails to measure anything.
    final inkIdx  = _rand.nextBool() ? wordIdx : _rand.nextInt(_colors.length);
    _word     = words[wordIdx];
    _inkColor = _colors[inkIdx];
    _isMatch  = wordIdx == inkIdx;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _intervalMs), () {
      if (!mounted || _gameEnded) return;
      // Timeout — advance without answer, no penalty
      setState(() {
        _answered++;
        _generateRound();
      });
      if (_answered >= _totalRounds) {
        _endGame();
      } else {
        _startTimer();
      }
    });
  }

  void _answer(bool userSaysMatch) {
    if (_gameEnded) return;
    _timer?.cancel();

    setState(() {
      if (userSaysMatch == _isMatch) {
        _correct++;
        _intervalMs = max(400, _intervalMs - 40);
      } else {
        _lives--;
      }
      _answered++;
      _generateRound();
    });

    if (_lives <= 0 || _answered >= _totalRounds) {
      _endGame();
      return;
    }
    _startTimer();
  }

  void _endGame() {
    if (_gameEnded) return;
    _timer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final colorPanicScore = (_correct / _totalRounds * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DontTapRedTestScreen(
          session:          widget.session,
          reactionScore:    widget.reactionScore,
          stroopScore:      widget.stroopScore,
          memoryScore:      widget.memoryScore,
          sequenceScore:    widget.sequenceScore,
          impulseScore:     widget.impulseScore,
          patternScore:     widget.patternScore,
          circleScore:      widget.circleScore,
          laserScore:       widget.laserScore,
          timingScore:      widget.timingScore,
          pulseScore:       widget.pulseScore,
          balanceScore:     widget.balanceScore,
          dartScore:        widget.dartScore,
          skyScore:         widget.skyScore,
          targetLockScore:  widget.targetLockScore,
          swipeDodgeScore:  widget.swipeDodgeScore,
          colorPanicScore:  colorPanicScore,
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
                    Text('Test 16 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _answered / _totalRounds,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: Colors.purple,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_answered/$_totalRounds',
                        style: const TextStyle(
                            color: Colors.purple, fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.colorPanicInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Lives
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3,
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 20))),
                    ),
                    Text(S.colorPanicCorrect(_correct),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              // Game area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _word,
                        style: TextStyle(
                          color: _inkColor,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: _inkColor, blurRadius: 16)],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _answer(true),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.6)),
                                  ),
                                  child: Center(
                                    child: Text(S.colorMatch,
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _answer(false),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.red.withValues(alpha: 0.6)),
                                  ),
                                  child: Center(
                                    child: Text(S.colorDiff,
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
