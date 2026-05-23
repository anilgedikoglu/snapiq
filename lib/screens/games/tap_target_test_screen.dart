// Full-test version of Tap Target (Test 18/19).
// 30 seconds, tap green targets avoid red decoys.
// Score = clamp(score / 20 * 100, 0, 100).
// Navigates to ShapeStrikeTestScreen on completion.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/animated_background.dart';
import 'shape_strike_test_screen.dart';

class _Target {
  final int id;
  double x;
  double y;
  double radius;
  final bool isDecoy;
  _Target({required this.id, required this.x, required this.y,
           required this.radius, required this.isDecoy});
}

class TapTargetTestScreen extends StatefulWidget {
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

  const TapTargetTestScreen({
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
  });

  @override
  State<TapTargetTestScreen> createState() => _TTTState();
}

class _TTTState extends State<TapTargetTestScreen> {
  static const _duration = 30;
  static const _maxScore = 20; // 20 correct taps = 100%

  int _timeLeft = _duration;
  int _score    = 0;
  final List<_Target> _targets = [];
  bool _gameEnded = false;
  Timer? _countdownTimer;
  Timer? _spawnTimer;
  Timer? _despawnTimer;
  int _nextId = 0;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _despawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _countdownTimer?.cancel();
        _spawnTimer?.cancel();
        _despawnTimer?.cancel();
        _endGame();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      _spawnTarget();
    });
    _despawnTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _targets.removeWhere((t) => t.radius <= 0));
    });
  }

  void _spawnTarget() {
    final isDecoy = _rand.nextDouble() < 0.3;
    final id = _nextId++;
    setState(() => _targets.add(_Target(
      id: id,
      x: 30 + _rand.nextDouble() * 280,
      y: 80 + _rand.nextDouble() * 420,
      radius: 35,
      isDecoy: isDecoy,
    )));
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _targets.removeWhere((t) => t.id == id));
    });
  }

  void _tapTarget(_Target t) {
    if (_gameEnded) return;
    setState(() {
      _targets.removeWhere((item) => item.id == t.id);
      if (!t.isDecoy) {
        _score++;
      } else {
        if (_score > 0) _score--;
      }
    });
  }

  void _endGame() {
    if (_gameEnded) return;
    setState(() => _gameEnded = true);
    _finish();
  }

  void _finish() {
    final tapTargetScore = (_score / _maxScore * 100).round().clamp(0, 100);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ShapeStrikeTestScreen(
          session:         widget.session,
          reactionScore:   widget.reactionScore,
          stroopScore:     widget.stroopScore,
          memoryScore:     widget.memoryScore,
          sequenceScore:   widget.sequenceScore,
          impulseScore:    widget.impulseScore,
          patternScore:    widget.patternScore,
          circleScore:     widget.circleScore,
          laserScore:      widget.laserScore,
          timingScore:     widget.timingScore,
          pulseScore:      widget.pulseScore,
          balanceScore:    widget.balanceScore,
          dartScore:       widget.dartScore,
          skyScore:        widget.skyScore,
          targetLockScore: widget.targetLockScore,
          swipeDodgeScore: widget.swipeDodgeScore,
          colorPanicScore: widget.colorPanicScore,
          dontTapRedScore: widget.dontTapRedScore,
          tapTargetScore:  tapTargetScore,
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
                    Text('Test 18 / 29',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _timeLeft / _duration,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: const Color(0xFF00C853),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_timeLeft s',
                        style: const TextStyle(
                            color: Color(0xFF00C853), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  S.tapTargetInstr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // Game area
              Expanded(
                child: Stack(
                  children: [
                    for (final t in List.from(_targets))
                      Positioned(
                        left: t.x - t.radius,
                        top: t.y - t.radius,
                        child: GestureDetector(
                          onTap: () => _tapTarget(t),
                          child: t.isDecoy
                              ? Container(
                                  width: t.radius * 2,
                                  height: t.radius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withValues(alpha: 0.85),
                                    boxShadow: [BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.5),
                                        blurRadius: 10)],
                                  ),
                                  child: const Center(
                                    child: Text('✗',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                )
                              : Container(
                                  width: t.radius * 2,
                                  height: t.radius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00C853)
                                        .withValues(alpha: 0.85),
                                    boxShadow: [BoxShadow(
                                        color: const Color(0xFF00C853)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 14)],
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
