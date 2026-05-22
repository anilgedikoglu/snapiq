import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import 'impulse_test_screen.dart';

class SequenceTestScreen extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;

  const SequenceTestScreen({
    super.key,
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
  });

  @override
  State<SequenceTestScreen> createState() => _SequenceTestScreenState();
}

class _SequenceTestScreenState extends State<SequenceTestScreen> {
  static const _configs = [
    (5, 20),  // 5 numbers, max 20
    (6, 50),  // 6 numbers, max 50
    (7, 99),  // 7 numbers, max 99
  ];

  int _round = 0;
  List<int> _numbers = [];
  List<int> _order = [];   // sorted target
  int _nextToTap = 0;      // index in sorted order
  Timer? _roundTimer;
  double _timeLeft = 8;
  bool _roundOver = false;

  int _totalCorrect = 0;
  int _totalWrong = 0;
  int _totalNumbers = 0;
  int _bonusMs = 0;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final (count, max) = _configs[_round];
    final nums = _generateUnique(count, max);
    _order = List<int>.from(nums)..sort();
    setState(() {
      _numbers = nums;
      _nextToTap = 0;
      _timeLeft = 8;
      _roundOver = false;
    });
    _totalNumbers += count;

    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft -= 0.1;
        if (_timeLeft <= 0) {
          t.cancel();
          _timeLeft = 0;
          _endRound(timeout: true);
        }
      });
    });
  }

  List<int> _generateUnique(int count, int max) {
    final r = Random();
    final Set<int> set = {};
    while (set.length < count) { set.add(r.nextInt(max) + 1); }
    return set.toList()..shuffle();
  }

  void _onTap(int num) {
    if (_roundOver) return;
    if (num == _order[_nextToTap]) {
      HapticFeedback.selectionClick();
      setState(() => _nextToTap++);
      _totalCorrect++;
      if (_nextToTap == _order.length) {
        _roundTimer?.cancel();
        _bonusMs += (_timeLeft * 10).toInt();
        _endRound(timeout: false);
      }
    } else {
      HapticFeedback.mediumImpact();
      _totalWrong++;
    }
  }

  void _endRound({required bool timeout}) async {
    setState(() => _roundOver = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (_round + 1 < _configs.length) {
      _round++;
      _startRound();
    } else {
      _done();
    }
  }

  void _done() {
    final raw = (_totalCorrect / _totalNumbers) * 100 -
        (_totalWrong * 5) +
        (_bonusMs ~/ 10);
    final score = raw.clamp(0, 100).round();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ImpulseTestScreen(
          session: widget.session,
          reactionScore: widget.reactionScore,
          stroopScore: widget.stroopScore,
          memoryScore: widget.memoryScore,
          sequenceScore: score,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              const SizedBox(height: 8),
              Text(
                'Round ${_round + 1} / ${_configs.length}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                S.seqInstruction,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Timer bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LinearProgressIndicator(
                  value: _timeLeft / 8,
                  backgroundColor:
                      const Color(0xFF00B4FF).withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timeLeft > 4
                        ? const Color(0xFF00B4FF)
                        : _timeLeft > 2
                            ? Colors.orange
                            : Colors.red,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_timeLeft.toStringAsFixed(1)}s',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: _numbers.map((n) {
                      final tapped = _nextToTap > 0 &&
                          _order.indexOf(n) < _nextToTap;
                      return _NumberTile(
                        number: n,
                        tapped: tapped,
                        onTap: () => _onTap(n),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _nextToTap < _order.length
                    ? S.seqNext(_order[_nextToTap])
                    : '✓',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
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
          const Icon(Icons.sort, color: Color(0xFF00B4FF), size: 18),
          const SizedBox(width: 6),
          const Text('Test 4/6',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(S.seqTestLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NumberTile extends StatefulWidget {
  final int number;
  final bool tapped;
  final VoidCallback onTap;

  const _NumberTile(
      {required this.number, required this.tapped, required this.onTap});

  @override
  State<_NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<_NumberTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: GestureDetector(
        onTap: widget.tapped ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: widget.tapped
                ? const Color(0xFF00C853).withValues(alpha: 0.2)
                : const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.tapped
                  ? const Color(0xFF00C853)
                  : const Color(0xFF00B4FF).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${widget.number}',
              style: TextStyle(
                color: widget.tapped
                    ? const Color(0xFF00C853)
                    : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
