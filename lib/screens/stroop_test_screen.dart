import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import 'memory_test_screen.dart';

class StroopTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;

  const StroopTestScreen(
      {super.key, required this.session, required this.reactionScore});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopItem {
  final String word;
  final Color textColor;
  final String correctAnswer;

  const _StroopItem(
      {required this.word,
      required this.textColor,
      required this.correctAnswer});
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  static const _options = ['Kırmızı', 'Mavi', 'Yeşil', 'Sarı'];
  static const _colors = {
    'Kırmızı': Color(0xFFE53935),
    'Mavi': Color(0xFF1E88E5),
    'Yeşil': Color(0xFF43A047),
    'Sarı': Color(0xFFFDD835),
  };

  static const _items = [
    _StroopItem(
        word: 'MAVİ',
        textColor: Color(0xFFE53935),
        correctAnswer: 'Kırmızı'),
    _StroopItem(
        word: 'YEŞİL',
        textColor: Color(0xFFFDD835),
        correctAnswer: 'Sarı'),
    _StroopItem(
        word: 'KIRMIZI',
        textColor: Color(0xFF43A047),
        correctAnswer: 'Yeşil'),
    _StroopItem(
        word: 'SARI',
        textColor: Color(0xFF1E88E5),
        correctAnswer: 'Mavi'),
    _StroopItem(
        word: 'MAVİ',
        textColor: Color(0xFF43A047),
        correctAnswer: 'Yeşil'),
  ];

  int _current = 0;
  int _totalScore = 0;
  Timer? _questionTimer;
  DateTime? _questionStart;
  bool _answered = false;
  String? _lastChoice;
  bool _lastCorrect = false;

  @override
  void initState() {
    super.initState();
    _startQuestion();
  }

  void _startQuestion() {
    _answered = false;
    _lastChoice = null;
    _questionStart = DateTime.now();
    _questionTimer = Timer(const Duration(seconds: 3), () {
      if (!_answered) _answer(null); // timed out
    });
  }

  void _answer(String? choice) {
    if (_answered) return;
    _questionTimer?.cancel();
    final elapsed =
        DateTime.now().difference(_questionStart!).inMilliseconds;
    final correct = choice == _items[_current].correctAnswer;
    int pts = 0;
    if (correct) {
      pts = 20;
      if (elapsed < 1000) pts += 3;
    }
    setState(() {
      _answered = true;
      _lastChoice = choice;
      _lastCorrect = correct;
      _totalScore += pts;
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
          session: widget.session,
          reactionScore: widget.reactionScore,
          stroopScore: score,
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
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              const SizedBox(height: 20),
              Text(
                'Yazının RENGİNİ seç',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '${_current + 1} / ${_items.length}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 40),
              Text(
                item.word,
                style: TextStyle(
                  color: item.textColor,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: item.textColor, blurRadius: 16)],
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
                  children: _options.map((opt) {
                    final c = _colors[opt]!;
                    Color borderColor = c.withValues(alpha: 0.5);
                    if (_answered && opt == item.correctAnswer) {
                      borderColor = const Color(0xFF00C853);
                    } else if (_answered &&
                        opt == _lastChoice &&
                        !_lastCorrect) {
                      borderColor = const Color(0xFFE53935);
                    }
                    return GestureDetector(
                      onTap: _answered ? null : () => _answer(opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
          const Text('Stroop Renk',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
