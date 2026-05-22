import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import 'stroop_test_screen.dart';

class ReactionTestScreen extends StatefulWidget {
  final GameSession session;

  const ReactionTestScreen({super.key, required this.session});

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

enum _Phase { waiting, ready, green, done, falseStart }

class _ReactionTestScreenState extends State<ReactionTestScreen> {
  _Phase _phase = _Phase.waiting;
  int _reactionMs = 0;
  int _score = 0;
  Timer? _timer;
  DateTime? _greenAt;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    setState(() => _phase = _Phase.waiting);
    await Future.delayed(const Duration(milliseconds: 800));
    _scheduleGreen();
  }

  void _scheduleGreen() {
    final delay = 1500 + Random().nextInt(2500); // 1.5-4s
    _timer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() => _phase = _Phase.green);
        _greenAt = DateTime.now();
      }
    });
    setState(() => _phase = _Phase.ready);
  }

  void _onTap() {
    if (_phase == _Phase.ready) {
      // false start
      _timer?.cancel();
      setState(() {
        _phase = _Phase.falseStart;
        _score = 0;
      });
      Future.delayed(const Duration(milliseconds: 1500), _done);
    } else if (_phase == _Phase.green) {
      final ms = DateTime.now().difference(_greenAt!).inMilliseconds;
      setState(() {
        _reactionMs = ms;
        _score = _calcScore(ms);
        _phase = _Phase.done;
      });
      Future.delayed(const Duration(milliseconds: 1800), _done);
    }
  }

  int _calcScore(int ms) {
    if (ms < 180) return 100;
    if (ms <= 230) return 90;
    if (ms <= 300) return 75;
    if (ms <= 400) return 55;
    if (ms <= 550) return 35;
    return 20;
  }

  void _done() {
    widget.session.currentTestIndex = 1;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StroopTestScreen(
          session: widget.session,
          reactionScore: _score,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _bgColor {
    switch (_phase) {
      case _Phase.green:
        return const Color(0xFF00C853);
      case _Phase.falseStart:
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF8B0000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              Expanded(
                child: GestureDetector(
                  onTap: _phase == _Phase.ready || _phase == _Phase.green
                      ? _onTap
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _bgColor.withValues(alpha: 0.25),
                    child: Center(child: _buildContent()),
                  ),
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
          const Icon(Icons.bolt, color: Color(0xFF00B4FF), size: 18),
          const SizedBox(width: 6),
          const Text('Test 1/6',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(S.reactionTestLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.waiting:
        return Text(S.reactionGetReady,
            style: const TextStyle(color: Colors.white54, fontSize: 22));
      case _Phase.ready:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B0000).withValues(alpha: 0.6),
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              S.reactionWhenGreen,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(S.reactionEarlyNote,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        );
      case _Phase.green:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C853).withValues(alpha: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(S.reactionTap,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ],
        );
      case _Phase.done:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_reactionMs ms',
              style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 52,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              S.reactionScore(_score),
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        );
      case _Phase.falseStart:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(S.reactionTooEarly,
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(S.reactionZero,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        );
    }
  }
}
