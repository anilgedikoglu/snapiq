// Full-test version of Sequence Rush (Test 22/29).
// 8 sequences correct OR 3 lives — whichever first.
// Score = clamp(score / 8 * 100, 0, 100).
// Mid-chain screen — navigates to ReactionWallTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'reaction_wall_test_screen.dart';

class SequenceRushTestScreen extends StatefulWidget {
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

  const SequenceRushTestScreen({
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
  });

  @override
  State<SequenceRushTestScreen> createState() => _SRTState();
}

class _SRTState extends State<SequenceRushTestScreen> {
  static const _maxScore = 8;

  static const _btnColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
  ];

  List<int> _sequence = [];
  List<int> _userInput = [];
  bool _isWatching = false;
  int _level = 1;
  int _score = 0;
  int _lives = 3;
  int _litIndex = -1;
  bool _started = false;
  bool _gameEnded = false;
  bool _inputEnabled = false;
  Timer? _watchTimer;
  final _rand = Random();

  @override
  void dispose() {
    _watchTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _sequence = [_rand.nextInt(4)];
    });
    _playSequence();
  }

  void _playSequence() {
    setState(() {
      _isWatching = true;
      _inputEnabled = false;
      _userInput = [];
      _litIndex = -1;
    });
    int i = 0;
    void next() {
      if (!mounted) return;
      if (i < _sequence.length) {
        setState(() => _litIndex = _sequence[i]);
        _watchTimer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _litIndex = -1);
          _watchTimer = Timer(const Duration(milliseconds: 200), () {
            i++;
            next();
          });
        });
      } else {
        setState(() {
          _isWatching = false;
          _inputEnabled = true;
        });
      }
    }
    _watchTimer = Timer(const Duration(milliseconds: 400), next);
  }

  void _tap(int index) {
    if (_gameEnded || !_inputEnabled) return;
    setState(() {
      _userInput.add(index);
      _litIndex = index;
    });
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _litIndex = -1);
    });

    final pos = _userInput.length - 1;
    if (_userInput[pos] != _sequence[pos]) {
      setState(() {
        _lives--;
        _inputEnabled = false;
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) _playSequence();
      });
      return;
    }
    if (_userInput.length == _sequence.length) {
      setState(() {
        _score++;
        _level++;
        _inputEnabled = false;
        _sequence.add(_rand.nextInt(4));
      });
      if (_score >= _maxScore) {
        _endGame();
        return;
      }
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) _playSequence();
      });
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    _watchTimer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final sequenceRushScore = (_score / _maxScore * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReactionWallTestScreen(
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
          sequenceRushScore: sequenceRushScore,
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
                    Text('Test 22 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _score / _maxScore,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFFE53935),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_score/$_maxScore',
                        style: const TextStyle(
                            color: Color(0xFFE53935), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.seqRushInstr,
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
                    Text(S.seqRushLevel(_level),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_started)
                Text(
                  _isWatching ? S.seqRushWatch : (_inputEnabled ? S.seqRushRepeat : ''),
                  style: TextStyle(
                      color: _isWatching
                          ? const Color(0xFFFDD835)
                          : const Color(0xFF00B4FF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              Expanded(
                child: _started
                    ? Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(4, (i) {
                            final isLit = _litIndex == i;
                            final color = _btnColors[i];
                            return GestureDetector(
                              onTap: () => _tap(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 130,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: isLit
                                      ? color
                                      : color.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: isLit
                                          ? color
                                          : color.withValues(alpha: 0.4),
                                      width: 2),
                                  boxShadow: isLit
                                      ? [BoxShadow(
                                          color: color.withValues(alpha: 0.6),
                                          blurRadius: 20)]
                                      : null,
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
                            child: Text(S.startBtn,
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
