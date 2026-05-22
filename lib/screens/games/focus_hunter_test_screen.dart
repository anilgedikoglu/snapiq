// Full-test version of Focus Hunter (Test 24/29).
// 10 rounds — same as arcade.
// Score = clamp(score / 10 * 100, 0, 100).
// Mid-chain screen — navigates to ImpulseControlTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'impulse_control_test_screen.dart';

class FocusHunterTestScreen extends StatefulWidget {
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

  const FocusHunterTestScreen({
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
  });

  @override
  State<FocusHunterTestScreen> createState() => _FHTState();
}

class _FHTState extends State<FocusHunterTestScreen> {
  static const _totalRounds = 10;

  static const _pairs = [
    ['😊', '😄'],
    ['🐱', '🐶'],
    ['🍎', '🍊'],
    ['⭐', '🌟'],
    ['🎯', '🎪'],
    ['❤️', '💛'],
    ['🚗', '🚕'],
    ['🌸', '🌺'],
  ];

  int _score = 0;
  int _round = 0;
  List<String> _emojis = [];
  int _oddIndex = -1;
  double _timeLeft = 5.0;
  bool _started = false;
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _gridSize() {
    if (_round < 3) return 4;
    if (_round < 6) return 5;
    return 6;
  }

  void _start() {
    setState(() => _started = true);
    _nextRound();
  }

  void _nextRound() {
    if (_round >= _totalRounds) {
      _endGame();
      return;
    }
    _timer?.cancel();
    final gs = _gridSize();
    final total = gs * gs;
    final pair = _pairs[_rand.nextInt(_pairs.length)];
    final baseEmoji = pair[0];
    final oddEmoji = pair[1];
    final oddIdx = _rand.nextInt(total);
    final emojis =
        List.generate(total, (i) => i == oddIdx ? oddEmoji : baseEmoji);

    setState(() {
      _emojis = emojis;
      _oddIndex = oddIdx;
      _timeLeft = 5.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        setState(() => _round++);
        _nextRound();
      }
    });
  }

  void _tap(int index) {
    if (_gameEnded || !_started) return;
    _timer?.cancel();
    if (index == _oddIndex) {
      setState(() => _score++);
    }
    setState(() => _round++);
    _nextRound();
  }

  void _endGame() {
    if (_gameEnded) return;
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final focusHunterScore = (_score / _totalRounds * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ImpulseControlTestScreen(
          session:           widget.session,
          reactionScore:     widget.reactionScore,
          stroopScore:       widget.stroopScore,
          memoryScore:       widget.memoryScore,
          sequenceScore:     widget.sequenceScore,
          impulseScore:      widget.impulseScore,
          patternScore:      widget.patternScore,
          circleScore:       widget.circleScore,
          laserScore:        widget.laserScore,
          timingScore:       widget.timingScore,
          pulseScore:        widget.pulseScore,
          balanceScore:      widget.balanceScore,
          dartScore:         widget.dartScore,
          skyScore:          widget.skyScore,
          targetLockScore:   widget.targetLockScore,
          swipeDodgeScore:   widget.swipeDodgeScore,
          colorPanicScore:   widget.colorPanicScore,
          dontTapRedScore:   widget.dontTapRedScore,
          tapTargetScore:    widget.tapTargetScore,
          shapeStrikeScore:  widget.shapeStrikeScore,
          memoryFlashScore:  widget.memoryFlashScore,
          mirrorBrainScore:  widget.mirrorBrainScore,
          sequenceRushScore: widget.sequenceRushScore,
          reactionWallScore: widget.reactionWallScore,
          focusHunterScore:  focusHunterScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = _gridSize();
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
                    Text('Test 24 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _round / _totalRounds,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFF00C853),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${_round + 1}/$_totalRounds',
                        style: const TextStyle(
                            color: Color(0xFF00C853), fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Focus Hunter — Farklı olanı bul!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tur: ${_round + 1}/$_totalRounds',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    Text('$_score puan',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_started) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_timeLeft / 5.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF00C853)),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: _started
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: GridView.count(
                          crossAxisCount: gs,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(_emojis.length, (i) {
                            return GestureDetector(
                              onTap: () => _tap(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1B2A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Center(
                                  child: Text(_emojis[i],
                                      style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                    : Center(
                        child: GestureDetector(
                          onTap: _start,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B4FF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF00B4FF)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: const Text('BAŞLA',
                                style: TextStyle(
                                    color: Color(0xFF00B4FF),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
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
