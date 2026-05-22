import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import '../l10n/app_strings.dart';
import 'memory_test_screen.dart';

class StroopTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;

  const StroopTestScreen(
      {super.key, required this.session, required this.reactionScore});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

/// Each item stores INDICES so the test works regardless of language.
/// Index mapping (0-3): Red, Blue, Green, Yellow
class _StroopItem {
  final int wordIdx;   // which colour-word to display
  final int inkIdx;    // which colour the text is rendered in (= correct answer)
  const _StroopItem({required this.wordIdx, required this.inkIdx});
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  // Fixed colour values — always the same regardless of language
  static const _colorValues = [
    Color(0xFFE53935), // 0 Red
    Color(0xFF1E88E5), // 1 Blue
    Color(0xFF43A047), // 2 Green
    Color(0xFFFDD835), // 3 Yellow
  ];

  // word=Blue(1) ink=Red(0), word=Green(2) ink=Yellow(3),
  // word=Red(0) ink=Green(2), word=Yellow(3) ink=Blue(1), word=Blue(1) ink=Green(2)
  static const _items = [
    _StroopItem(wordIdx: 1, inkIdx: 0),
    _StroopItem(wordIdx: 2, inkIdx: 3),
    _StroopItem(wordIdx: 0, inkIdx: 2),
    _StroopItem(wordIdx: 3, inkIdx: 1),
    _StroopItem(wordIdx: 1, inkIdx: 2),
  ];

  int _current    = 0;
  int _totalScore = 0;
  Timer? _questionTimer;
  DateTime? _questionStart;
  bool _answered  = false;
  int?  _lastChoiceIdx;
  bool _lastCorrect = false;

  /// Language-appropriate option labels (Red/Blue/Green/Yellow or TR equivalents)
  List<String> get _options => S.stroopOptions;

  @override
  void initState() {
    super.initState();
    _startQuestion();
  }

  void _startQuestion() {
    _answered      = false;
    _lastChoiceIdx = null;
    _questionStart = DateTime.now();
    _questionTimer = Timer(const Duration(seconds: 3), () {
      if (!_answered) _answer(null);
    });
  }

  void _answer(int? choiceIdx) {
    if (_answered) return;
    _questionTimer?.cancel();
    final elapsed =
        DateTime.now().difference(_questionStart!).inMilliseconds;
    final correct = choiceIdx == _items[_current].inkIdx;
    int pts = 0;
    if (correct) {
      pts = 20;
      if (elapsed < 1000) pts += 3;
    }
    setState(() {
      _answered      = true;
      _lastChoiceIdx = choiceIdx;
      _lastCorrect   = correct;
      _totalScore   += pts;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (_current + 1 < _items.length) {
        setState(() => _current++);
        _startQuestion();
      } else {
        _done();
      }
    });
  }

  void _done() {
    final score = _totalScore.clamp(0, 100);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryTestScreen(
          session:       widget.session,
          reactionScore: widget.reactionScore,
          stroopScore:   score,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_current];
    final displayWord = _options[item.wordIdx].toUpperCase();
    final inkColor    = _colorValues[item.inkIdx];

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              const SizedBox(height: 20),
              Text(
                S.stroopInstruction,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '${_current + 1} / ${_items.length}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 40),
              Text(
                displayWord,
                style: TextStyle(
                  color: inkColor,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: inkColor, blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: List.generate(_options.length, (i) {
                    final c = _colorValues[i];
                    Color borderColor = c.withValues(alpha: 0.5);
                    if (_answered && i == item.inkIdx) {
                      borderColor = const Color(0xFF00C853);
                    } else if (_answered &&
                        i == _lastChoiceIdx &&
                        !_lastCorrect) {
                      borderColor = const Color(0xFFE53935);
                    }
                    return GestureDetector(
                      onTap: _answered ? null : () => _answer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _options[i],
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
          const Icon(Icons.color_lens, color: Color(0xFF00B4FF), size: 18),
          const SizedBox(width: 6),
          const Text('Test 2/6',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(S.stroopTestLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
