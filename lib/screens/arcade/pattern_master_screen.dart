import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class _PQ {
  final String series;
  final List<String> options;
  final String answer;
  const _PQ(
      {required this.series,
      required this.options,
      required this.answer});
}

class PatternMasterScreen extends StatefulWidget {
  const PatternMasterScreen({super.key});

  @override
  State<PatternMasterScreen> createState() => _PatternMasterScreenState();
}

class _PatternMasterScreenState extends State<PatternMasterScreen> {
  static const _gameId  = 'pattern_master';
  static const _xpReward = 35;
  static const _gameName = 'Pattern Master';
  static const _totalQ  = 10;
  static const _ptsPerQ = 10;

  static const _allQuestions = [
    _PQ(series: '2  4  8  16  ?', options: ['24', '28', '30', '32'], answer: '32'),
    _PQ(series: '1  3  6  10  ?', options: ['14', '15', '16', '13'], answer: '15'),
    _PQ(series: 'A  C  E  G  ?', options: ['H', 'I', 'J', 'K'], answer: 'I'),
    _PQ(series: '▲  ■  ▲  ■  ?', options: ['▲', '■', '●', '★'], answer: '▲'),
    _PQ(series: '3  6  12  24  ?', options: ['36', '42', '48', '32'], answer: '48'),
    _PQ(series: '1  4  9  16  ?', options: ['20', '24', '25', '30'], answer: '25'),
    _PQ(series: 'Z  X  V  T  ?', options: ['S', 'R', 'P', 'Q'], answer: 'R'),
    _PQ(series: '🔴🔵🔴🔵?', options: ['🔴', '🔵', '🟢', '🟡'], answer: '🔴'),
    _PQ(series: '5  10  20  40  ?', options: ['60', '70', '80', '50'], answer: '80'),
    _PQ(series: '2  3  5  8  13  ?', options: ['18', '19', '20', '21'], answer: '21'),
    _PQ(series: '100  50  25  ?', options: ['10', '12', '12.5', '15'], answer: '12.5'),
    _PQ(series: 'AB  CD  EF  ?', options: ['GH', 'HI', 'GI', 'GJ'], answer: 'GH'),
    _PQ(series: '■  ■  ▲  ■  ■  ?', options: ['■', '▲', '●', '★'], answer: '▲'),
    _PQ(series: '7  14  21  28  ?', options: ['33', '34', '35', '36'], answer: '35'),
    _PQ(series: '🌑🌒🌓🌔?', options: ['🌕', '🌖', '🌒', '🌙'], answer: '🌕'),
    _PQ(series: '1  2  4  7  11  ?', options: ['14', '15', '16', '18'], answer: '16'),
    _PQ(series: 'B  D  F  H  ?', options: ['I', 'J', 'K', 'L'], answer: 'J'),
    _PQ(series: '9  3  1  ?', options: ['0.5', '0.33', '0.25', '1/4'], answer: '0.33'),
    _PQ(series: '🐱🐱🐶🐱🐱?', options: ['🐱', '🐶', '🐰', '🦊'], answer: '🐶'),
    _PQ(series: '10  8  6  4  ?', options: ['1', '2', '3', '0'], answer: '2'),
  ];

  int _qIndex  = 0;
  int _score   = 0;
  List<_PQ> _questions = [];
  double _timeLeft = 15.0;
  String? _flash;   // 'correct' | 'wrong'
  bool _gameEnded  = false;
  Timer? _timer;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    final shuffled = List<_PQ>.from(_allQuestions)..shuffle();
    setState(() => _questions = shuffled.take(_totalQ).toList());
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_qIndex >= _totalQ) {
      _endGame();
      return;
    }
    _timer?.cancel();
    setState(() => _timeLeft = 15.0);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        setState(() {
          _flash = 'wrong';
          _qIndex++;
        });
        _flashTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _flash = null);
            _nextQuestion();
          }
        });
      }
    });
  }

  void _answer(String option) {
    if (_gameEnded) return;
    _timer?.cancel();
    final correct = _questions[_qIndex].answer == option;
    setState(() {
      if (correct) _score++;
      _flash  = correct ? 'correct' : 'wrong';
      _qIndex++;
    });
    _flashTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _flash = null);
        _nextQuestion();
      }
    });
  }

  void _endGame() {
    if (_gameEnded) return;
    _timer?.cancel();
    setState(() => _gameEnded = true);
    _gameOver(_score * _ptsPerQ);
  }

  Future<void> _gameOver(int score) async {
    final s = await StorageService.getInstance();
    final prevBest = s.arcadeBestScore(_gameId);
    final isNewBest = score > prevBest;
    await s.saveArcadeBestScore(_gameId, score);
    await s.saveXP(_xpReward);
    final newLevel = XpService.levelForXp(s.xp);
    await s.saveLevel(newLevel);
    await AchievementService.checkArcadeAchievements(_gameId, _score, s);
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ArcadeResultOverlay(
        gameName: _gameName,
        score: score,
        bestScore: isNewBest ? score : prevBest,
        xpGained: _xpReward,
        isNewBest: isNewBest,
        onReplay: () {
          Navigator.pop(context);
          _restart();
        },
        onBack: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _restart() {
    _timer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _qIndex    = 0;
      _score     = 0;
      _questions = [];
      _timeLeft  = 15.0;
      _flash     = null;
      _gameEnded = false;
    });
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main content ──────────────────────────────────────
              Column(
                children: [
                  _buildHeader(),
                  if (_qIndex < _totalQ && _questions.isNotEmpty) ...[
                    // Question counter + score
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(S.patternQ(_qIndex + 1, _totalQ),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                          Text(S.patternPoints(_score, _ptsPerQ),
                              style: const TextStyle(
                                  color: Color(0xFF00B4FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Per-question timer bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_timeLeft / 15.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                              _timeLeft > 7
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFFFF7043)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Series card
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1B2A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFF00B4FF)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _questions[_qIndex < _totalQ
                                          ? _qIndex
                                          : _totalQ - 1]
                                      .series,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Answer options
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: GridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.5,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                children: _questions[_qIndex < _totalQ
                                        ? _qIndex
                                        : _totalQ - 1]
                                    .options
                                    .map((opt) => GestureDetector(
                                          onTap: () => _answer(opt),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  const Color(0xFF0D1B2A),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: const Color(
                                                          0xFFBB86FC)
                                                      .withValues(
                                                          alpha: 0.4)),
                                            ),
                                            child: Center(
                                              child: Text(opt,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),

              // ── Feedback pill (floats at top center) ──────────────
              if (_flash != null)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _flash != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _flash == 'correct'
                              ? const Color(0xFF00C853)
                              : Colors.redAccent,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: (_flash == 'correct'
                                      ? const Color(0xFF00C853)
                                      : Colors.redAccent)
                                  .withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _flash == 'correct'
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            if (_flash == 'correct') ...[
                              const SizedBox(width: 8),
                              Text(
                                '+$_ptsPerQ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Pattern Master',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
