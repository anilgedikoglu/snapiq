import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../services/ad_service.dart';
import '../widgets/animated_background.dart';
import 'games/circle_tap_test_screen.dart';

class PatternTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;

  const PatternTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
  });

  @override
  State<PatternTestScreen> createState() => _PatternTestScreenState();
}

class _PatternQuestion {
  final String sequence;
  final List<String> options;
  final int correctIndex;
  final String hint;

  const _PatternQuestion({
    required this.sequence,
    required this.options,
    required this.correctIndex,
    required this.hint,
  });
}

class _PatternTestScreenState extends State<PatternTestScreen> {
  static List<_PatternQuestion> get _questions => [
    _PatternQuestion(
      sequence: 'A  B  A  B  ?',
      options: ['A', 'B', 'C'],
      correctIndex: 0,
      hint: S.patternHint1,
    ),
    _PatternQuestion(
      sequence: '2  4  6  8  ?',
      options: ['9', '10', '12'],
      correctIndex: 1,
      hint: S.patternHint2,
    ),
    _PatternQuestion(
      sequence: '⬜  ⬛  ⬜  ⬛  ?',
      options: ['⬛', '⬜', '🔲'],
      correctIndex: 1,
      hint: S.patternHint3,
    ),
    _PatternQuestion(
      sequence: '1  1  2  3  5  ?',
      options: ['7', '8', '9'],
      correctIndex: 1,
      hint: S.patternHint4,
    ),
    _PatternQuestion(
      sequence: '▲  ■  ▲  ■  ?',
      options: ['■', '▲', '●'],
      correctIndex: 1,
      hint: S.patternHint5,
    ),
  ];

  int _current = 0;
  int _score = 0;
  int? _selectedIdx;
  bool _answered = false;

  void _answer(int idx) {
    if (_answered) return;
    final correct = idx == _questions[_current].correctIndex;
    setState(() {
      _selectedIdx = idx;
      _answered = true;
      if (correct) _score += 20;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (_current + 1 < _questions.length) {
        setState(() {
          _current++;
          _selectedIdx = null;
          _answered = false;
        });
      } else {
        _done();
      }
    });
  }

  void _done() async {
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CircleTapTestScreen(
          session: widget.session,
          reactionScore: widget.reactionScore,
          stroopScore: widget.stroopScore,
          memoryScore: widget.memoryScore,
          sequenceScore: widget.sequenceScore,
          impulseScore: widget.impulseScore,
          patternScore: _score.clamp(0, 100),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              const SizedBox(height: 16),
              Text(
                '${_current + 1} / ${_questions.length}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                S.patternInstruction,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // Sequence display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00B4FF).withValues(alpha: 0.3)),
                ),
                child: Text(
                  q.sequence,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_answered)
                Text(
                  q.hint,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              const SizedBox(height: 32),
              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(q.options.length, (i) {
                    final isCorrect = i == q.correctIndex;
                    final isSelected = _selectedIdx == i;
                    Color color = const Color(0xFF00B4FF);
                    if (_answered) {
                      if (isCorrect) {
                        color = const Color(0xFF00C853);
                      } else if (isSelected && !isCorrect) {
                        color = const Color(0xFFE53935);
                      } else {
                        color = Colors.white24;
                      }
                    }
                    return GestureDetector(
                      onTap: _answered ? null : () => _answer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color, width: 2),
                          boxShadow: isSelected || (_answered && isCorrect)
                              ? [
                                  BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 12)
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            q.options[i],
                            style: TextStyle(
                              color: color,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.pattern, color: Color(0xFF00B4FF), size: 18),
          const SizedBox(width: 6),
          const Text('Test 6/6',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          const Text('Pattern IQ',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
