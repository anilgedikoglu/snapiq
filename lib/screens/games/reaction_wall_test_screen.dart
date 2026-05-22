// Full-test version of Reaction Wall (Test 23/29).
// 30 seconds OR 3 lives lost.
// Score = clamp(score / 15 * 100, 0, 100).
// Mid-chain screen â€” navigates to FocusHunterTestScreen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/animated_background.dart';
import 'focus_hunter_test_screen.dart';

class _Wall {
  double y;
  final int gapLane;
  bool scored = false;
  _Wall({required this.y, required this.gapLane});
}

class ReactionWallTestScreen extends StatefulWidget {
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

  const ReactionWallTestScreen({
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
  });

  @override
  State<ReactionWallTestScreen> createState() => _RWTState();
}

class _RWTState extends State<ReactionWallTestScreen> {
  static const _maxScore = 15;
  static const _duration = 30;
  static const double _wallSpeed = 0.008;

  int _playerLane = 1;
  int _score = 0;
  int _lives = 3;
  int _timeLeft = _duration;
  final List<_Wall> _walls = [];
  bool _started = false;
  bool _gameEnded = false;
  Timer? _moveTimer;
  Timer? _spawnTimer;
  Timer? _countdownTimer;
  final _rand = Random();

  @override
  void dispose() {
    _moveTimer?.cancel();
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameEnded) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        _walls.add(_Wall(y: 0.0, gapLane: _rand.nextInt(3)));
      });
    });
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _gameEnded) return;
      setState(() {
        for (final w in _walls) {
          w.y += _wallSpeed;
        }
        for (final w in _walls) {
          if (!w.scored && w.y >= 0.88) {
            w.scored = true;
            if (w.gapLane == _playerLane) {
              _score++;
            } else {
              _lives--;
              if (_lives <= 0) {
                _endGame();
                return;
              }
            }
          }
        }
        _walls.removeWhere((w) => w.y > 1.1);
      });
    });
  }

  void _endGame() {
    if (_gameEnded) return;
    _moveTimer?.cancel();
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() => _gameEnded = true);
    _finish();
  }

  void _moveLeft() {
    if (_gameEnded || !_started) return;
    setState(() => _playerLane = max(0, _playerLane - 1));
  }

  void _moveRight() {
    if (_gameEnded || !_started) return;
    setState(() => _playerLane = min(2, _playerLane + 1));
  }

  Future<void> _finish() async {
    final reactionWallScore = (_score / _maxScore * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FocusHunterTestScreen(
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
          reactionWallScore: reactionWallScore,
        ),
      ),
    );
  }

  List<Widget> _buildWall(
      _Wall w, double totalW, double totalH, double laneW) {
    const wallH = 18.0;
    final top = w.y * totalH - wallH / 2;
    return [
      for (int lane = 0; lane < 3; lane++)
        if (lane != w.gapLane)
          Positioned(
            left: lane * laneW,
            top: top,
            child: Container(
              width: laneW - 1,
              height: wallH,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
    ];
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
                    Text('Test 23 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _started ? _timeLeft / _duration : 0,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFFFF7043),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_timeLeft s',
                        style: const TextStyle(
                            color: Color(0xFFFF7043), fontSize: 13)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Reaction Wall â€” DoÄŸru ÅŸeritte dur!',
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
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: _started
                    ? LayoutBuilder(builder: (ctx, constraints) {
                        final laneW = constraints.maxWidth / 3;
                        return Stack(
                          children: [
                            Positioned(
                              left: laneW,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 1, color: Colors.white12),
                            ),
                            Positioned(
                              left: laneW * 2,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 1, color: Colors.white12),
                            ),
                            for (final w in List.from(_walls))
                              ..._buildWall(w, constraints.maxWidth,
                                  constraints.maxHeight, laneW),
                            Positioned(
                              bottom: 20,
                              left: _playerLane * laneW + laneW / 2 - 20,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4FF),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF00B4FF)
                                            .withValues(alpha: 0.6),
                                        blurRadius: 12)
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      })
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
              if (_started) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _moveLeft,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBB86FC)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFBB86FC)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: const Center(
                              child: Text('â†',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 28)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _moveRight,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBB86FC)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFBB86FC)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: const Center(
                              child: Text('â†’',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 28)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
