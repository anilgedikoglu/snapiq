// Full-test version of Memory Flash (Test 20/29).
// 5 rounds OR 3 lives — whichever first.
// Score = clamp(correct / 5 * 100, 0, 100).
// Mid-chain screen — navigates to MirrorBrainTestScreen.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'mirror_brain_test_screen.dart';

enum _Phase { watch, recall, result }

class MemoryFlashTestScreen extends StatefulWidget {
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

  const MemoryFlashTestScreen({
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
  });

  @override
  State<MemoryFlashTestScreen> createState() => _MFTState();
}

class _MFTState extends State<MemoryFlashTestScreen> {
  static const _maxRounds = 5;

  _Phase _phase = _Phase.watch;
  int _level = 1;
  int _gridSize = 3;
  int _patternSize = 2;
  List<int> _pattern = [];
  List<int> _selected = [];
  int _score = 0;
  int _lives = 3;
  int _roundsPlayed = 0;
  bool _gameEnded = false;
  Timer? _watchTimer;

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    super.dispose();
  }

  void _nextRound() {
    if (_roundsPlayed >= _maxRounds) {
      _endGame();
      return;
    }
    final total = _gridSize * _gridSize;
    final indices = List.generate(total, (i) => i)..shuffle();
    final pat = indices.take(_patternSize).toList();
    setState(() {
      _pattern = pat;
      _selected = [];
      _phase = _Phase.watch;
    });
    final watchMs = 1500 + _level * 200;
    _watchTimer = Timer(Duration(milliseconds: watchMs), () {
      if (mounted) setState(() => _phase = _Phase.recall);
    });
  }

  void _tapCell(int index) {
    if (_phase != _Phase.recall || _gameEnded) return;
    if (_selected.contains(index)) return;
    setState(() => _selected.add(index));
    if (_selected.length == _pattern.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final correct = _selected.toSet().containsAll(_pattern) &&
        _pattern.toSet().containsAll(_selected);
    setState(() => _phase = _Phase.result);
    if (correct) {
      setState(() {
        _score++;
        _level++;
        if (_level % 2 == 0) _patternSize = (_patternSize + 1).clamp(2, 12);
        if (_level % 3 == 0) _gridSize = (_gridSize + 1).clamp(3, 5);
        _roundsPlayed++;
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) _nextRound();
      });
    } else {
      setState(() {
        _lives--;
        _roundsPlayed++;
      });
      if (_lives <= 0) {
        setState(() => _gameEnded = true);
        _finish();
      } else {
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) _nextRound();
        });
      }
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final memoryFlashScore = (_score / _maxRounds * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MirrorBrainTestScreen(
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
          memoryFlashScore: memoryFlashScore,
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
                    Text('Test 20 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _roundsPlayed / _maxRounds,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFFBB86FC),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_roundsPlayed/$_maxRounds',
                        style: const TextStyle(
                            color: Color(0xFFBB86FC), fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Memory Flash — Hangi kareler?',
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
                          (i) => Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 18))),
                    ),
                    Text('$_score doğru',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              _buildPhaseText(),
              const SizedBox(height: 8),
              Expanded(
                child: Center(child: _buildGrid()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseText() {
    String text = '';
    Color color = Colors.white54;
    switch (_phase) {
      case _Phase.watch:
        text = 'Ezberle!';
        color = const Color(0xFFFDD835);
        break;
      case _Phase.recall:
        text = 'Hangileri?';
        color = const Color(0xFF00B4FF);
        break;
      case _Phase.result:
        text = '';
        break;
    }
    return Text(text,
        style: TextStyle(
            color: color, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildGrid() {
    final total = _gridSize * _gridSize;
    final size = (MediaQuery.of(context).size.width - 48) / _gridSize;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(total, (i) {
        final isPattern = _pattern.contains(i);
        final isSelected = _selected.contains(i);
        Color cellColor;
        if (_phase == _Phase.watch) {
          cellColor = isPattern
              ? const Color(0xFFBB86FC)
              : const Color(0xFF0D1B2A);
        } else if (_phase == _Phase.recall) {
          cellColor = isSelected
              ? const Color(0xFF00B4FF)
              : const Color(0xFF0D1B2A);
        } else {
          if (isPattern && isSelected) {
            cellColor = const Color(0xFF00C853);
          } else if (isPattern) {
            cellColor = const Color(0xFFFF7043);
          } else if (isSelected) {
            cellColor = Colors.red.withValues(alpha: 0.5);
          } else {
            cellColor = const Color(0xFF0D1B2A);
          }
        }
        return GestureDetector(
          onTap: () => _tapCell(i),
          child: Container(
            width: size - 6,
            height: size - 6,
            decoration: BoxDecoration(
              color: cellColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cellColor == const Color(0xFF0D1B2A)
                    ? Colors.white12
                    : cellColor,
              ),
              boxShadow: cellColor != const Color(0xFF0D1B2A)
                  ? [BoxShadow(
                      color: cellColor.withValues(alpha: 0.4),
                      blurRadius: 8)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
