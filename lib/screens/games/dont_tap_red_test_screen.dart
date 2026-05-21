// Full-test version of Don't Tap Red (Test 17/18).
// 20 rounds, 3 lives. Score = correct/20 * 100.
// Navigates to TapTargetTestScreen on completion.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'tap_target_test_screen.dart';

class DontTapRedTestScreen extends StatefulWidget {
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

  const DontTapRedTestScreen({
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
  });

  @override
  State<DontTapRedTestScreen> createState() => _DTRTState();
}

class _DTRTState extends State<DontTapRedTestScreen> {
  static const _totalRounds = 20;

  static const _palette = [
    Colors.blue, Colors.green, Colors.yellow,
    Colors.purple, Colors.orange, Colors.red,
  ];

  int _lives    = 3;
  int _correct  = 0;
  int _answered = 0;
  int _speed    = 1200;
  List<Color> _grid = [];
  bool _gameEnded   = false;
  Timer? _autoTimer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateGrid();
    _startAutoTimer();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _generateGrid() {
    _grid = List.generate(6, (_) => _palette[_rand.nextInt(_palette.length)]);
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer(Duration(milliseconds: _speed), () {
      if (!mounted || _gameEnded) return;
      // Timeout — advance without answer, no penalty
      setState(() {
        _answered++;
        _generateGrid();
      });
      if (_answered >= _totalRounds) {
        _endGame();
      } else {
        _startAutoTimer();
      }
    });
  }

  void _tap(int index) {
    if (_gameEnded) return;
    _autoTimer?.cancel();
    final color = _grid[index];
    setState(() {
      if (color == Colors.red) {
        _lives--;
      } else {
        _correct++;
        _speed = max(400, _speed - 40);
      }
      _answered++;
      _generateGrid();
    });

    if (_lives <= 0 || _answered >= _totalRounds) {
      _endGame();
      return;
    }
    _startAutoTimer();
  }

  void _endGame() {
    if (_gameEnded) return;
    _autoTimer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final dontTapRedScore = (_correct / _totalRounds * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TapTargetTestScreen(
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
          dontTapRedScore:  dontTapRedScore,
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
                    Text('Test 17 / 29',
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
                          color: Colors.red,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_answered/$_totalRounds',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  "Don't Tap Red — Kırmızıya dokunma!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Lives + correct count
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
                    Text('$_correct doğru',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              // Grid — centered vertically
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: List.generate(6, (i) {
                        return GestureDetector(
                          onTap: () => _tap(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _grid[i].withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: _grid[i].withValues(alpha: 0.4),
                                    blurRadius: 12)
                              ],
                            ),
                          ),
                        );
                      }),
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
