// Full-test version of Number Hunter (Test 28/29).
// 30 seconds â€” same as arcade. Auto-starts.
// Score = clamp(score / 15 * 100, 0, 100).
// Mid-chain screen â€” navigates to PatternMasterTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'pattern_master_test_screen.dart';

class NumberHunterTestScreen extends StatefulWidget {
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
  final int speedMathScore;

  const NumberHunterTestScreen({
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
    required this.speedMathScore,
  });

  @override
  State<NumberHunterTestScreen> createState() => _NHTState();
}

class _NHTState extends State<NumberHunterTestScreen> {
  static const _maxScore = 15;
  static const _duration = 30;

  int _timeLeft = _duration;
  int _score = 0;
  int _target = 0;
  List<int> _numbers = [];
  bool _gameEnded = false;
  int? _flashIndex;
  Timer? _flashTimer;
  Timer? _countdownTimer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _nextTarget();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameEnded) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _countdownTimer?.cancel();
        setState(() => _gameEnded = true);
        _finish();
      }
    });
  }

  void _nextTarget() {
    final nums = List.generate(20, (i) => i + 1)..shuffle(_rand);
    final targetPos = _rand.nextInt(nums.length);
    setState(() {
      _numbers = nums;
      _target = nums[targetPos];
      _flashIndex = null;
    });
  }

  void _tap(int index) {
    if (_gameEnded) return;
    if (_numbers[index] == _target) {
      _flashTimer?.cancel();
      setState(() {
        _score++;
        _flashIndex = index;
      });
      _flashTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) _nextTarget();
      });
    }
  }

  Future<void> _finish() async {
    final numberHunterScore = (_score / _maxScore * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PatternMasterTestScreen(
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
          speedMathScore:      widget.speedMathScore,
          numberHunterScore:   numberHunterScore,
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
                    Text('Test 28 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _timeLeft / _duration,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: _timeLeft > 10
                              ? const Color(0xFF00B4FF)
                              : Colors.redAccent,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_timeLeft s',
                        style: TextStyle(
                            color: _timeLeft > 10
                                ? const Color(0xFF00B4FF)
                                : Colors.redAccent,
                            fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Number Hunter â€” SayÄ±yÄ± bul!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_timeLeft s',
                        style: TextStyle(
                            color: _timeLeft > 10
                                ? Colors.white54
                                : Colors.redAccent,
                            fontSize: 14)),
                    Text('$_score bulundu',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Bulunacak: $_target',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Color(0xFF00B4FF), blurRadius: 12)
                      ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(_numbers.length, (i) {
                      final isFlash = _flashIndex == i;
                      final isTarget = _numbers[i] == _target;
                      return GestureDetector(
                        onTap: () => _tap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isFlash
                                ? const Color(0xFF00C853).withValues(alpha: 0.4)
                                : const Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFlash
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF00B4FF)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${_numbers[i]}',
                              style: TextStyle(
                                color: isFlash
                                    ? const Color(0xFF00C853)
                                    : isTarget
                                        ? Colors.white
                                        : Colors.white70,
                                fontSize: 18,
                                fontWeight: isTarget
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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
