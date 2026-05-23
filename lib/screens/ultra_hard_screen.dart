import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../models/test_result.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';
import 'result_screen.dart';

/// Ultra Hard mode — stricter timing, more memory rounds, harder sequence.
class UltraHardScreen extends StatefulWidget {
  const UltraHardScreen({super.key});

  @override
  State<UltraHardScreen> createState() => _UltraHardScreenState();
}

enum _UltraPhase {
  intro,
  reaction,
  stroop,
  memory,
  sequence,
  impulse,
  pattern,
  done,
}

class _UltraHardScreenState extends State<UltraHardScreen> {
  _UltraPhase _phase = _UltraPhase.intro;
  final GameSession _session = GameSession();

  // Collected scores
  int _reactionScore = 0;
  int _stroopScore = 0;
  int _memoryScore = 0;
  int _sequenceScore = 0;
  int _impulseScore = 0;

  void _startTest() => setState(() => _phase = _UltraPhase.reaction);

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _UltraPhase.intro:
        return _buildIntro();
      case _UltraPhase.reaction:
        return _UHReaction(onDone: (s) {
          setState(() {
            _reactionScore = s;
            _phase = _UltraPhase.stroop;
          });
        });
      case _UltraPhase.stroop:
        return _UHStroop(onDone: (s) {
          setState(() {
            _stroopScore = s;
            _phase = _UltraPhase.memory;
          });
        });
      case _UltraPhase.memory:
        return _UHMemory(onDone: (s) {
          setState(() {
            _memoryScore = s;
            _phase = _UltraPhase.sequence;
          });
        });
      case _UltraPhase.sequence:
        return _UHSequence(onDone: (s) {
          setState(() {
            _sequenceScore = s;
            _phase = _UltraPhase.impulse;
          });
        });
      case _UltraPhase.impulse:
        return _UHImpulse(onDone: (s) {
          setState(() {
            _impulseScore = s;
            _phase = _UltraPhase.pattern;
          });
        });
      case _UltraPhase.pattern:
        return _UHPattern(
          session: _session,
          reactionScore: _reactionScore,
          stroopScore: _stroopScore,
          memoryScore: _memoryScore,
          sequenceScore: _sequenceScore,
          impulseScore: _impulseScore,
        );
      case _UltraPhase.done:
        return _buildIntro();
    }
  }

  Widget _buildIntro() {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CinHost(size: 100),
                const SizedBox(height: 16),
                Text(
                  S.ultraTitle,
                  style: const TextStyle(
                    color: Color(0xFFFF7043),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(color: Color(0xFFFF7043), blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Daha hızlı. Daha zor. Daha acımasız.\nNormal mod senin için kolay mı? O zaman dene!',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFF7043).withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HardStat('Reaksiyon', '1.0–2.0 s pencere'),
                      _HardStat('Stroop', '2 sn/soru'),
                      _HardStat('Hafıza', '4 tur (4-6-7-8 kutu)'),
                      _HardStat('Sayı Sıralama', '2 sn/tur'),
                      _HardStat('İmpuls', '500ms/şekil'),
                      _HardStat('Pattern IQ', 'Aynı'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                NeonButton(
                  text: S.ultraTitle,
                  onPressed: _startTest,
                  color: const Color(0xFFFF7043),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.local_fire_department_rounded,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  text: S.back,
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white38,
                  width: double.infinity,
                  icon: Icons.arrow_back_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HardStat extends StatelessWidget {
  final String name;
  final String detail;
  const _HardStat(this.name, this.detail);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Color(0xFFFF7043), size: 14),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  color: Color(0xFFFF7043), fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(detail,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

// --------------- UH Sub-tests ---------------

/// UH Reaction: 1.0-2.0s window
class _UHReaction extends StatefulWidget {
  final ValueChanged<int> onDone;
  const _UHReaction({required this.onDone});

  @override
  State<_UHReaction> createState() => _UHReactionState();
}

enum _RPhase { waiting, ready, green, done, falseStart }

class _UHReactionState extends State<_UHReaction> {
  _RPhase _phase = _RPhase.waiting;
  int _reactionMs = 0;
  int _score = 0;
  Timer? _timer;
  DateTime? _greenAt;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() async {
    setState(() => _phase = _RPhase.waiting);
    await Future.delayed(const Duration(milliseconds: 600));
    _scheduleGreen();
  }

  void _scheduleGreen() {
    final delay = 1000 + Random().nextInt(1000); // 1.0-2.0s
    _timer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() => _phase = _RPhase.green);
        _greenAt = DateTime.now();
        // 800ms window
        _timer = Timer(const Duration(milliseconds: 800), () {
          if (_phase == _RPhase.green) {
            setState(() {
              _phase = _RPhase.done;
              _score = 0;
            });
            Future.delayed(const Duration(milliseconds: 1000),
                () => widget.onDone(0));
          }
        });
      }
    });
    setState(() => _phase = _RPhase.ready);
  }

  void _onTap() {
    if (_phase == _RPhase.ready) {
      _timer?.cancel();
      setState(() {
        _phase = _RPhase.falseStart;
        _score = 0;
      });
      Future.delayed(const Duration(milliseconds: 1200),
          () => widget.onDone(0));
    } else if (_phase == _RPhase.green) {
      _timer?.cancel();
      final ms = DateTime.now().difference(_greenAt!).inMilliseconds;
      setState(() {
        _reactionMs = ms;
        _score = _calcScore(ms);
        _phase = _RPhase.done;
      });
      Future.delayed(const Duration(milliseconds: 1400),
          () => widget.onDone(_score));
    }
  }

  int _calcScore(int ms) {
    if (ms < 150) return 100;
    if (ms <= 200) return 90;
    if (ms <= 250) return 75;
    if (ms <= 350) return 55;
    if (ms <= 500) return 35;
    return 20;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildBar(),
              Expanded(
                child: GestureDetector(
                  onTap: _phase == _RPhase.ready || _phase == _RPhase.green
                      ? _onTap
                      : null,
                  child: Center(child: _buildContent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: const [
          Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFFF7043), size: 18),
          SizedBox(width: 6),
          Text('MANYAK 1/6 – Reaksiyon',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _RPhase.waiting:
        return const Text('Hazırlan...',
            style: TextStyle(color: Colors.white54, fontSize: 20));
      case _RPhase.ready:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.redAccent, size: 100),
            SizedBox(height: 16),
            Text('Yeşil olunca HEMEN dokun!',
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        );
      case _RPhase.green:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Color(0xFF00C853), size: 120),
            SizedBox(height: 16),
            Text('DOKUN!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
          ],
        );
      case _RPhase.done:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_reactionMs ms',
                style: const TextStyle(
                    color: Color(0xFF00C853), fontSize: 48)),
            Text('Skor: $_score',
                style: const TextStyle(color: Colors.white70)),
          ],
        );
      case _RPhase.falseStart:
        return const Text('Erken Dokundun! 0 puan',
            style: TextStyle(color: Colors.redAccent, fontSize: 22));
    }
  }
}

/// UH Stroop: 2s per question
class _UHStroop extends StatefulWidget {
  final ValueChanged<int> onDone;
  const _UHStroop({required this.onDone});

  @override
  State<_UHStroop> createState() => _UHStroopState();
}

class _StroopItem2 {
  final String word;
  final Color textColor;
  final String correctAnswer;
  const _StroopItem2(this.word, this.textColor, this.correctAnswer);
}

class _UHStroopState extends State<_UHStroop> {
  static const _options = ['Kırmızı', 'Mavi', 'Yeşil', 'Sarı'];
  static const _colorMap = {
    'Kırmızı': Color(0xFFE53935),
    'Mavi': Color(0xFF1E88E5),
    'Yeşil': Color(0xFF43A047),
    'Sarı': Color(0xFFFDD835),
  };
  static const _items = [
    _StroopItem2('MAVİ', Color(0xFFE53935), 'Kırmızı'),
    _StroopItem2('YEŞİL', Color(0xFFFDD835), 'Sarı'),
    _StroopItem2('KIRMIZI', Color(0xFF43A047), 'Yeşil'),
    _StroopItem2('SARI', Color(0xFF1E88E5), 'Mavi'),
    _StroopItem2('MAVİ', Color(0xFF43A047), 'Yeşil'),
  ];

  int _current = 0;
  int _totalScore = 0;
  Timer? _qTimer;
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
    _qTimer = Timer(const Duration(seconds: 2), () {
      if (!_answered) _answer(null);
    });
    setState(() {});
  }

  void _answer(String? choice) {
    if (_answered) return;
    _qTimer?.cancel();
    final item = _items[_current];
    final correct = choice == item.correctAnswer;
    if (correct) _totalScore += 20;
    setState(() {
      _answered = true;
      _lastChoice = choice;
      _lastCorrect = correct;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_current + 1 < _items.length) {
        setState(() => _current++);
        _startQuestion();
      } else {
        widget.onDone(_totalScore.clamp(0, 100));
      }
    });
  }

  @override
  void dispose() {
    _qTimer?.cancel();
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
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF7043), size: 18),
                    SizedBox(width: 6),
                    Text('MANYAK 2/6 – Stroop (2 sn)',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.word,
                style: TextStyle(
                    color: item.textColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Rengi seç',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _options.map((opt) {
                    final color = _colorMap[opt]!;
                    Color btnColor = color;
                    if (_answered) {
                      if (opt == _items[_current].correctAnswer) {
                        btnColor = const Color(0xFF00C853);
                      } else if (opt == _lastChoice && !_lastCorrect) {
                        btnColor = const Color(0xFFE53935);
                      } else {
                        btnColor = Colors.white24;
                      }
                    }
                    return GestureDetector(
                      onTap: _answered ? null : () => _answer(opt),
                      child: Container(
                        decoration: BoxDecoration(
                          color: btnColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: btnColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(opt,
                              style: TextStyle(
                                  color: btnColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// UH Memory: 4 rounds with 4-6-7-8 boxes
class _UHMemory extends StatefulWidget {
  final ValueChanged<int> onDone;
  const _UHMemory({required this.onDone});

  @override
  State<_UHMemory> createState() => _UHMemoryState();
}

enum _MemPhase2 { showing, selecting, feedback }

class _UHMemoryState extends State<_UHMemory> {
  static const _roundBoxCounts = [4, 6, 7, 8];
  int _round = 0;
  _MemPhase2 _phase = _MemPhase2.showing;
  Set<int> _targets = {};
  Set<int> _selected = {};
  int _score = 0;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final count = _roundBoxCounts[_round];
    final total = 16;
    _targets = {};
    while (_targets.length < count) {
      _targets.add(_rand.nextInt(total));
    }
    _selected = {};
    setState(() => _phase = _MemPhase2.showing);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _phase = _MemPhase2.selecting);
    });
  }

  void _onTap(int idx) {
    if (_phase != _MemPhase2.selecting) return;
    setState(() {
      if (_selected.contains(idx)) {
        _selected.remove(idx);
      } else {
        _selected.add(idx);
      }
    });
  }

  void _submit() {
    if (_phase != _MemPhase2.selecting) return;
    final correct = _selected.length == _targets.length &&
        _selected.every(_targets.contains);
    final partial = _selected.where(_targets.contains).length;
    setState(() {
      _phase = _MemPhase2.feedback;
      if (correct) {
        _score += 25;
        HapticFeedback.selectionClick();
      } else {
        _score += (partial * 3).clamp(0, 15);
        HapticFeedback.mediumImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (_round + 1 < _roundBoxCounts.length) {
        setState(() => _round++);
        _startRound();
      } else {
        widget.onDone(_score.clamp(0, 100));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF7043), size: 18),
                    const SizedBox(width: 6),
                    Text(
                        'MANYAK 3/6 – Hafıza (${_roundBoxCounts[_round]} kutu)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Text(
                _phase == _MemPhase2.showing
                    ? 'Ezberle!'
                    : _phase == _MemPhase2.selecting
                        ? 'Hangileri yandı?'
                        : 'Sonuç...',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 16,
                  itemBuilder: (_, i) {
                    final isTarget = _targets.contains(i);
                    final isSelected = _selected.contains(i);
                    Color color;
                    if (_phase == _MemPhase2.showing) {
                      color = isTarget
                          ? const Color(0xFFBB86FC)
                          : const Color(0xFF0D1B2A);
                    } else if (_phase == _MemPhase2.selecting) {
                      color = isSelected
                          ? const Color(0xFF00B4FF)
                          : const Color(0xFF0D1B2A);
                    } else {
                      if (isTarget && isSelected) {
                        color = const Color(0xFF00C853);
                      } else if (isTarget && !isSelected) {
                        color = const Color(0xFFBB86FC);
                      } else if (!isTarget && isSelected) {
                        color = const Color(0xFFE53935);
                      } else {
                        color = const Color(0xFF0D1B2A);
                      }
                    }
                    return GestureDetector(
                      onTap: _phase == _MemPhase2.selecting
                          ? () => _onTap(i)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 1.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_phase == _MemPhase2.selecting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: NeonButton(
                    text: 'Onayla',
                    onPressed: _submit,
                    color: const Color(0xFF00B4FF),
                    width: double.infinity,
                    height: 50,
                    icon: Icons.check_rounded,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// UH Sequence: 2s per round
class _UHSequence extends StatefulWidget {
  final ValueChanged<int> onDone;
  const _UHSequence({required this.onDone});

  @override
  State<_UHSequence> createState() => _UHSequenceState();
}

class _UHSequenceState extends State<_UHSequence> {
  static const _configs = [(5, 20), (6, 50), (7, 99)];
  int _round = 0;
  List<int> _numbers = [];
  int _tapped = 0;
  int _score = 0;
  Timer? _roundTimer;
  int _timeLeft = 2;
  Timer? _countdownTimer;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  void _setupRound() {
    final (count, maxN) = _configs[_round];
    final nums = <int>{};
    while (nums.length < count) {
      nums.add(_rand.nextInt(maxN) + 1);
    }
    _numbers = nums.toList()..shuffle(_rand);
    _tapped = 0;
    _timeLeft = 2;

    _roundTimer?.cancel();
    _countdownTimer?.cancel();
    _roundTimer = Timer(const Duration(seconds: 2), _timeUp);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timeLeft = (_timeLeft - 1).clamp(0, 2));
    });
    setState(() {});
  }

  void _timeUp() {
    _countdownTimer?.cancel();
    _score += (_tapped * 10).clamp(0, 33);
    _next();
  }

  void _onTap(int value) {
    if (!_numbers.contains(value)) return;
    final sorted = List<int>.from(_numbers)..sort();
    if (value == sorted[_tapped]) {
      HapticFeedback.selectionClick();
      _tapped++;
      setState(() => _numbers.remove(value));
      if (_numbers.isEmpty) {
        _roundTimer?.cancel();
        _countdownTimer?.cancel();
        _score += 33;
        _next();
      }
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _next() {
    if (_round + 1 < _configs.length) {
      setState(() => _round++);
      _setupRound();
    } else {
      widget.onDone(_score.clamp(0, 100));
    }
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF7043), size: 18),
                    const SizedBox(width: 6),
                    const Text('MANYAK 4/6 – Sayı Sıralama (2 sn)',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    Text('$_timeLeft sn',
                        style: const TextStyle(
                            color: Color(0xFFFF7043), fontSize: 14)),
                  ],
                ),
              ),
              const Text('Küçükten büyüğe dokun!',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _numbers.map((n) {
                      return GestureDetector(
                        onTap: () => _onTap(n),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4FF)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF00B4FF)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Center(
                            child: Text('$n',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
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

/// UH Impulse: 500ms per shape
class _UHImpulse extends StatefulWidget {
  final ValueChanged<int> onDone;
  const _UHImpulse({required this.onDone});

  @override
  State<_UHImpulse> createState() => _UHImpulseState();
}

class _UHImpulseState extends State<_UHImpulse> {
  static const _shapes = ['daire', 'kare', 'üçgen', 'yıldız'];
  static const _total = 10;
  static const _circles = 4;

  List<String> _sequence = [];
  int _current = -1;
  bool _showing = false;
  Timer? _timer;
  int _score = 100;
  bool _tapped = false;
  bool _done = false;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _buildSeq();
    Future.delayed(const Duration(milliseconds: 500), _next);
  }

  void _buildSeq() {
    final seq = <String>[];
    seq.addAll(List.filled(_circles, 'daire'));
    seq.addAll(List.generate(
        _total - _circles, (_) => _shapes.skip(1).toList()[_rand.nextInt(3)]));
    seq.shuffle(_rand);
    _sequence = seq;
  }

  void _next() {
    if (_current + 1 >= _total) {
      _finish();
      return;
    }
    _current++;
    _tapped = false;
    setState(() => _showing = true);
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_sequence[_current] == 'daire' && !_tapped) {
        setState(() => _score = (_score - 10).clamp(0, 100));
      }
      setState(() => _showing = false);
      Future.delayed(const Duration(milliseconds: 150), _next);
    });
  }

  void _onTap() {
    if (!_showing || _done) return;
    _tapped = true;
    if (_sequence[_current] == 'daire') {
      HapticFeedback.selectionClick();
      setState(() => _score = (_score + 25).clamp(0, 100));
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _score = (_score - 20).clamp(0, 100));
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) widget.onDone(_score);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF7043), size: 18),
                    SizedBox(width: 6),
                    Text('MANYAK 5/6 – İmpuls (500ms)',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Text('Sadece DAİRE çıkınca dokun!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Puan: $_score',
                  style: const TextStyle(
                      color: Color(0xFF00B4FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Expanded(
                child: GestureDetector(
                  onTap: _onTap,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: _showing && _current >= 0
                          ? _buildShape(_sequence[_current])
                          : const SizedBox(width: 100, height: 100),
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

  Widget _buildShape(String shape) {
    switch (shape) {
      case 'daire':
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00B4FF).withValues(alpha: 0.2),
            border: Border.all(color: const Color(0xFF00B4FF), width: 3),
          ),
        );
      case 'kare':
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFBB86FC).withValues(alpha: 0.2),
            border: Border.all(color: const Color(0xFFBB86FC), width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      default:
        return Container(
          width: 100,
          height: 100,
          color: const Color(0xFF03DAC6).withValues(alpha: 0.2),
        );
    }
  }
}

/// UH Pattern — same as normal but with 'MANYAK' branding
class _UHPattern extends StatefulWidget {
  final GameSession session;
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;

  const _UHPattern({
    required this.session,
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
  });

  @override
  State<_UHPattern> createState() => _UHPatternState();
}

class _UHPatternQ {
  final String sequence;
  final List<String> options;
  final int correctIndex;
  const _UHPatternQ(this.sequence, this.options, this.correctIndex);
}

class _UHPatternState extends State<_UHPattern> {
  static const _questions = [
    _UHPatternQ('A  B  A  B  ?', ['A', 'B', 'C'], 0),
    _UHPatternQ('2  4  6  8  ?', ['9', '10', '12'], 1),
    _UHPatternQ('1  1  2  3  5  ?', ['7', '8', '9'], 1),
    _UHPatternQ('3  6  9  12  ?', ['13', '14', '15'], 2),
    _UHPatternQ('1  4  9  16  ?', ['20', '25', '30'], 1),
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
    Future.delayed(const Duration(milliseconds: 600), () {
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

  Future<void> _done() async {
    final result = TestResult(
      reactionScore: widget.reactionScore,
      stroopScore: widget.stroopScore,
      memoryScore: widget.memoryScore,
      sequenceScore: widget.sequenceScore,
      impulseScore: widget.impulseScore,
      patternScore: _score.clamp(0, 100),
    );
    widget.session.result = result;
    final storage = await StorageService.getInstance();
    await storage.saveResult(result);
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF7043), size: 18),
                    SizedBox(width: 6),
                    Text('MANYAK 6/6 – Pattern IQ',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Text('${_current + 1} / ${_questions.length}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('Örüntüyü tamamla.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.4)),
                ),
                child: Text(q.sequence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4)),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(q.options.length, (i) {
                    final isCorrect = i == q.correctIndex;
                    final isSelected = _selectedIdx == i;
                    Color color = const Color(0xFFFF7043);
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
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Text(q.options[i],
                              style: TextStyle(
                                  color: color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
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
}
