import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import 'sequence_test_screen.dart';

class MemoryTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;

  const MemoryTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
  });

  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

enum _MemPhase { showing, selecting, feedback }

class _MemoryTestScreenState extends State<MemoryTestScreen> {
  static const _rounds = [3, 4, 5];
  int _round = 0;
  _MemPhase _phase = _MemPhase.showing;
  Set<int> _targets = {};
  Set<int> _selected = {};
  int _totalCorrect = 0;
  int _totalTarget = 0;
  int _totalWrong = 0;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() async {
    final count = _rounds[_round];
    final all = List.generate(9, (i) => i)..shuffle();
    _targets = all.take(count).toSet();
    _selected = {};
    setState(() => _phase = _MemPhase.showing);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _phase = _MemPhase.selecting);
  }

  void _onTileTap(int index) {
    if (_phase != _MemPhase.selecting) return;
    final count = _rounds[_round];
    if (_selected.contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() => _selected.add(index));
    if (_selected.length == count) {
      _checkRound();
    }
  }

  void _checkRound() async {
    final count = _rounds[_round];
    int correct = 0;
    int wrong = 0;
    for (final s in _selected) {
      if (_targets.contains(s)) {
        correct++;
      } else {
        wrong++;
      }
    }
    _totalCorrect += correct;
    _totalTarget += count;
    _totalWrong += wrong;

    setState(() => _phase = _MemPhase.feedback);
    await Future.delayed(const Duration(milliseconds: 900));

    if (_round + 1 < _rounds.length) {
      _round++;
      _startRound();
    } else {
      _done();
    }
  }

  void _done() {
    final raw =
        (_totalCorrect / _totalTarget) * 100 - (_totalWrong * 5);
    final score = raw.round().clamp(0, 100);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SequenceTestScreen(
          session: widget.session,
          reactionScore: widget.reactionScore,
          stroopScore: widget.stroopScore,
          memoryScore: score,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              const SizedBox(height: 12),
              Text(
                'Round ${_round + 1} / ${_rounds.length}  •  '
                '${S.memBoxCount(_rounds[_round])}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                _phase == _MemPhase.showing
                    ? S.memWhichBoxes
                    : _phase == _MemPhase.selecting
                        ? S.memSelectBoxes
                        : S.memChecking,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 9,
                    itemBuilder: (_, i) => _buildTile(i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int i) {
    final isTarget = _targets.contains(i);
    final isSelected = _selected.contains(i);

    Color color = const Color(0xFF1A2744);
    Color border = const Color(0xFF2A3F6F);

    if (_phase == _MemPhase.showing && isTarget) {
      color = const Color(0xFF00B4FF);
      border = const Color(0xFF00B4FF);
    } else if (_phase == _MemPhase.selecting && isSelected) {
      color = const Color(0xFF7B2FBE).withValues(alpha: 0.5);
      border = const Color(0xFFBB86FC);
    } else if (_phase == _MemPhase.feedback) {
      if (isTarget && isSelected) {
        color = const Color(0xFF00C853).withValues(alpha: 0.4);
        border = const Color(0xFF00C853);
      } else if (isTarget && !isSelected) {
        color = const Color(0xFFFF6D00).withValues(alpha: 0.3);
        border = const Color(0xFFFF6D00);
      } else if (!isTarget && isSelected) {
        color = const Color(0xFFE53935).withValues(alpha: 0.3);
        border = const Color(0xFFE53935);
      }
    }

    return GestureDetector(
      onTap: () => _onTileTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 2),
          boxShadow: _phase == _MemPhase.showing && isTarget
              ? [BoxShadow(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.5),
                  blurRadius: 12)]
              : null,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.grid_view, color: Color(0xFF00B4FF), size: 18),
          const SizedBox(width: 6),
          const Text('Test 3/6',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(S.memTestLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
