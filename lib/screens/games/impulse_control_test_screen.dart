// Full-test version of Impulse Control (Test 25/29).
// 20 rounds, 3 lives.
// Score = clamp(score / 20 * 100, 0, 100).
// Mid-chain screen — navigates to TapRainTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'tap_rain_test_screen.dart';

class ImpulseControlTestScreen extends StatefulWidget {
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

  const ImpulseControlTestScreen({
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
  });

  @override
  State<ImpulseControlTestScreen> createState() => _ICTState();
}

class _ICTState extends State<ImpulseControlTestScreen> {
  static const _totalRounds = 20;

  int _lives = 3;
  int _score = 0;
  int _round = 0;
  bool _isGo = false;
  bool _showing = false;
  bool _tapped = false;
  String _message = '';
  bool _started = false;
  bool _gameEnded = false;
  Timer? _showTimer;
  Timer? _waitTimer;
  final _rand = Random();

  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
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
    _showTimer?.cancel();
    _waitTimer?.cancel();

    final waitMs = 600 + _rand.nextInt(1400);
    setState(() {
      _showing = false;
      _isGo = false;
      _tapped = false;
      _message = '...';
    });
    _waitTimer = Timer(Duration(milliseconds: waitMs), () {
      if (!mounted || _gameEnded) return;
      final isGo = _rand.nextDouble() < 0.65;
      final displayMs = 500 + _rand.nextInt(1500);
      setState(() {
        _isGo = isGo;
        _showing = true;
        _tapped = false;
        _message = '';
      });
      _showTimer = Timer(Duration(milliseconds: displayMs), () {
        if (!mounted || _gameEnded) return;
        if (_isGo && !_tapped) {
          setState(() => _message = 'Kaçırdın!');
        }
        setState(() {
          _showing = false;
          _round++;
        });
        Timer(const Duration(milliseconds: 400), () {
          if (mounted && !_gameEnded) _nextRound();
        });
      });
    });
  }

  void _onTap() {
    if (_gameEnded || !_started || !_showing || _tapped) return;
    _tapped = true;
    _showTimer?.cancel();
    if (_isGo) {
      setState(() {
        _score++;
        _message = '✓';
        _showing = false;
        _round++;
      });
      Timer(const Duration(milliseconds: 400), () {
        if (mounted && !_gameEnded) _nextRound();
      });
    } else {
      setState(() {
        _lives--;
        _message = '✗';
        _showing = false;
        _round++;
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
      Timer(const Duration(milliseconds: 400), () {
        if (mounted && !_gameEnded) _nextRound();
      });
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    _showTimer?.cancel();
    _waitTimer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  Future<void> _finish() async {
    final impulseControlScore = (_score / _totalRounds * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TapRainTestScreen(
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
          impulseControlScore: impulseControlScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgFlash = Colors.transparent;
    if (_showing) {
      bgFlash = _isGo
          ? Colors.green.withValues(alpha: 0.08)
          : Colors.red.withValues(alpha: 0.08);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: Container(
          color: bgFlash,
          child: SafeArea(
            child: Column(
              children: [
                // Progress header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Test 25 / 29',
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
                            color: const Color(0xFF1E88E5),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$_round/$_totalRounds',
                          style: const TextStyle(
                              color: Color(0xFF1E88E5), fontSize: 13)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Impulse Control — GO mu BEKLE mi?',
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
                      ? GestureDetector(
                          onTap: _onTap,
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_showing)
                                  Text(
                                    _isGo ? 'GO' : 'BEKLE',
                                    style: TextStyle(
                                      color: _isGo
                                          ? const Color(0xFF00C853)
                                          : Colors.red,
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: _isGo
                                              ? const Color(0xFF00C853)
                                              : Colors.red,
                                          blurRadius: 30,
                                        )
                                      ],
                                    ),
                                  )
                                else if (_message.isNotEmpty)
                                  Text(_message,
                                      style: TextStyle(
                                          color: _message == '✓'
                                              ? const Color(0xFF00C853)
                                              : _message == 'Kaçırdın!'
                                                  ? const Color(0xFFFDD835)
                                                  : Colors.red,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold))
                                else
                                  const Text('...',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 48)),
                                const SizedBox(height: 20),
                                if (!_showing)
                                  const Text('Ekrana dokun',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 14)),
                              ],
                            ),
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
      ),
    );
  }
}
