// Full-test version of Mirror Brain (Test 21/29).
// 15 rounds, 3 lives â€” same mechanics as arcade.
// Score = clamp(score / 15 * 100, 0, 100).
// Mid-chain screen â€” navigates to SequenceRushTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'sequence_rush_test_screen.dart';

class MirrorBrainTestScreen extends StatefulWidget {
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

  const MirrorBrainTestScreen({
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
  });

  @override
  State<MirrorBrainTestScreen> createState() => _MBTState();
}

class _MBTState extends State<MirrorBrainTestScreen> {
  static const _totalRounds = 15;
  static const _arrows = ['â†', 'â†’', 'â†‘', 'â†“'];
  static const _opposites = {'â†': 'â†’', 'â†’': 'â†', 'â†‘': 'â†“', 'â†“': 'â†‘'};

  int _score = 0;
  int _lives = 3;
  int _round = 0;
  double _timeLeft = 3.0;
  String _arrow = 'â†';
  bool _started = false;
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    setState(() {
      _arrow = _arrows[_rand.nextInt(_arrows.length)];
      _timeLeft = 3.0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        setState(() {
          _lives--;
          _round++;
        });
        if (_lives <= 0) {
          _endGame();
        } else {
          _nextRound();
        }
      }
    });
  }

  void _tap(String direction) {
    if (_gameEnded || !_started) return;
    _timer?.cancel();
    final correct = _opposites[_arrow];
    if (direction == correct) {
      setState(() {
        _score++;
        _round++;
      });
    } else {
      setState(() {
        _lives--;
        _round++;
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
    }
    _nextRound();
  }

  void _endGame() {
    if (_gameEnded) return;
    _timer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final mirrorBrainScore = (_score / _totalRounds * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SequenceRushTestScreen(
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
          colorPanicScore:  widget.colorPanicScore,
          dontTapRedScore:  widget.dontTapRedScore,
          tapTargetScore:   widget.tapTargetScore,
          shapeStrikeScore: widget.shapeStrikeScore,
          memoryFlashScore: widget.memoryFlashScore,
          mirrorBrainScore: mirrorBrainScore,
        ),
      ),
    );
  }

  Widget _dirButton(String dir) {
    return GestureDetector(
      onTap: () => _tap(dir),
      child: Container(
        width: 80,
        height: 72,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFBB86FC).withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(dir,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
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
                    Text('Test 21 / 29',
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
                          color: const Color(0xFFFDD835),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_round/$_totalRounds',
                        style: const TextStyle(
                            color: Color(0xFFFDD835), fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Mirror Brain â€” Tersine dokun!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3,
                          (i) => Text(i < _lives ? 'â¤ï¸' : 'ğŸ–¤',
                              style: const TextStyle(fontSize: 18))),
                    ),
                    Text('$_score/$_totalRounds',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: _started
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_timeLeft / 3.0).clamp(0.0, 1.0),
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFFDD835)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('TERSÄ°NE DOKUN!',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  letterSpacing: 1)),
                          const SizedBox(height: 24),
                          Text(_arrow,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 32),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              _dirButton('â†‘'),
                              _dirButton('â†“'),
                              _dirButton('â†'),
                              _dirButton('â†’'),
                            ],
                          ),
                        ],
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
                            child: const Text('BAÅLA',
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
