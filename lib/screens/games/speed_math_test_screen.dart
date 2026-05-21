// Full-test version of Speed Math (Test 27/29).
// 10 questions — same as arcade. Auto-starts.
// Score = clamp(score / 10 * 100, 0, 100).
// Mid-chain screen — navigates to NumberHunterTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'number_hunter_test_screen.dart';

class SpeedMathTestScreen extends StatefulWidget {
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
  final int tapRainScore;

  const SpeedMathTestScreen({
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
    required this.tapRainScore,
  });

  @override
  State<SpeedMathTestScreen> createState() => _SMTState();
}

class _SMTState extends State<SpeedMathTestScreen> {
  static const _totalQ = 10;

  int _qIndex = 0;
  int _score = 0;
  double _timeLeft = 4.0;
  String _question = '';
  bool _isCorrect = false;
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextQuestion() {
    if (_qIndex >= _totalQ) {
      _endGame();
      return;
    }
    final a = 2 + _rand.nextInt(14);
    final b = 2 + _rand.nextInt(8);
    final opIdx = _rand.nextInt(3);
    final ops = ['+', '-', '×'];
    final op = ops[opIdx];
    int correct;
    if (op == '+') {
      correct = a + b;
    } else if (op == '-') {
      correct = a - b;
    } else {
      correct = a * b;
    }

    final showCorrect = _rand.nextBool();
    int displayed;
    if (showCorrect) {
      displayed = correct;
    } else {
      final off = 1 + _rand.nextInt(3);
      displayed = correct + (_rand.nextBool() ? off : -off);
    }

    _timer?.cancel();
    setState(() {
      _question = '$a $op $b = $displayed ?';
      _isCorrect = displayed == correct;
      _timeLeft = 4.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    setState(() => _qIndex++);
    _nextQuestion();
  }

  void _onUserAnswer(bool userSaysCorrect) {
    if (_gameEnded) return;
    _timer?.cancel();
    if (userSaysCorrect == _isCorrect) {
      setState(() => _score++);
    }
    setState(() => _qIndex++);
    _nextQuestion();
  }

  void _endGame() {
    if (_gameEnded) return;
    _timer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final speedMathScore = (_score / _totalQ * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NumberHunterTestScreen(
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
          tapRainScore:        widget.tapRainScore,
          speedMathScore:      speedMathScore,
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
                    Text('Test 27 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _qIndex / _totalQ,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFF03DAC6),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${_qIndex + 1}/$_totalQ',
                        style: const TextStyle(
                            color: Color(0xFF03DAC6), fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Speed Math — Doğru mu yanlış mı?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Soru: ${_qIndex + 1}/$_totalQ',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    Text('$_score/$_totalQ',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_timeLeft / 4.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                        _timeLeft > 2.0
                            ? const Color(0xFF00C853)
                            : const Color(0xFFFF7043)),
                    minHeight: 8,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF00B4FF)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(_question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onUserAnswer(true),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.green
                                            .withValues(alpha: 0.6)),
                                  ),
                                  child: const Center(
                                    child: Text('✓ DOĞRU',
                                        style: TextStyle(
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
                                onTap: () => _onUserAnswer(false),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.red
                                            .withValues(alpha: 0.6)),
                                  ),
                                  child: const Center(
                                    child: Text('✗ YANLIŞ',
                                        style: TextStyle(
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
