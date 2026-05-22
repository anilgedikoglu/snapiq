// Full-test version of Pattern Master (Test 29/29).
// 10 questions â€” same as arcade. Auto-starts.
// Score = clamp(score / 10 * 100, 0, 100).
// LAST SCREEN â€” creates TestResult, saves, navigates to ResultScreen.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../models/test_result.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../result_screen.dart';

class _PQ {
  final String series;
  final List<String> options;
  final String answer;
  const _PQ({required this.series, required this.options, required this.answer});
}

class PatternMasterTestScreen extends StatefulWidget {
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
  final int impulseControlScore;
  final int tapRainScore;
  final int speedMathScore;
  final int numberHunterScore;

  const PatternMasterTestScreen({
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
    required this.impulseControlScore,
    required this.tapRainScore,
    required this.speedMathScore,
    required this.numberHunterScore,
  });

  @override
  State<PatternMasterTestScreen> createState() => _PMTState();
}

class _PMTState extends State<PatternMasterTestScreen> {
  static const _totalQ = 10;
  static const _ptsPerQ = 10;

  static const _allQuestions = [
    _PQ(series: '2  4  8  16  ?', options: ['24', '28', '30', '32'], answer: '32'),
    _PQ(series: '1  3  6  10  ?', options: ['14', '15', '16', '13'], answer: '15'),
    _PQ(series: 'A  C  E  G  ?', options: ['H', 'I', 'J', 'K'], answer: 'I'),
    _PQ(series: 'â–²  â–   â–²  â–   ?', options: ['â–²', 'â– ', 'â—', 'â˜…'], answer: 'â–²'),
    _PQ(series: '3  6  12  24  ?', options: ['36', '42', '48', '32'], answer: '48'),
    _PQ(series: '1  4  9  16  ?', options: ['20', '24', '25', '30'], answer: '25'),
    _PQ(series: 'Z  X  V  T  ?', options: ['S', 'R', 'P', 'Q'], answer: 'R'),
    _PQ(series: 'ğŸ”´ğŸ”µğŸ”´ğŸ”µ?', options: ['ğŸ”´', 'ğŸ”µ', 'ğŸŸ¢', 'ğŸŸ¡'], answer: 'ğŸ”´'),
    _PQ(series: '5  10  20  40  ?', options: ['60', '70', '80', '50'], answer: '80'),
    _PQ(series: '2  3  5  8  13  ?', options: ['18', '19', '20', '21'], answer: '21'),
    _PQ(series: '100  50  25  ?', options: ['10', '12', '12.5', '15'], answer: '12.5'),
    _PQ(series: 'AB  CD  EF  ?', options: ['GH', 'HI', 'GI', 'GJ'], answer: 'GH'),
    _PQ(series: 'â–   â–   â–²  â–   â–   ?', options: ['â– ', 'â–²', 'â—', 'â˜…'], answer: 'â–²'),
    _PQ(series: '7  14  21  28  ?', options: ['33', '34', '35', '36'], answer: '35'),
    _PQ(series: 'ğŸŒ‘ğŸŒ’ğŸŒ“ğŸŒ”?', options: ['ğŸŒ•', 'ğŸŒ–', 'ğŸŒ’', 'ğŸŒ™'], answer: 'ğŸŒ•'),
    _PQ(series: '1  2  4  7  11  ?', options: ['14', '15', '16', '18'], answer: '16'),
    _PQ(series: 'B  D  F  H  ?', options: ['I', 'J', 'K', 'L'], answer: 'J'),
    _PQ(series: '9  3  1  ?', options: ['0.5', '0.33', '0.25', '1/4'], answer: '0.33'),
    _PQ(series: 'ğŸ±ğŸ±ğŸ¶ğŸ±ğŸ±?', options: ['ğŸ±', 'ğŸ¶', 'ğŸ°', 'ğŸ¦Š'], answer: 'ğŸ¶'),
    _PQ(series: '10  8  6  4  ?', options: ['1', '2', '3', '0'], answer: '2'),
  ];

  int _qIndex = 0;
  int _score = 0;
  List<_PQ> _questions = [];
  double _timeLeft = 15.0;
  String? _flash;
  bool _gameEnded = false;
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
      _flash = correct ? 'correct' : 'wrong';
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
    _finish();
  }

  Future<void> _finish() async {
    final patternMasterScore = (_score / _totalQ * 100).round().clamp(0, 100);

    final result = TestResult(
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
      impulseControlScore: widget.impulseControlScore,
      tapRainScore:        widget.tapRainScore,
      speedMathScore:      widget.speedMathScore,
      numberHunterScore:   widget.numberHunterScore,
      patternMasterScore:  patternMasterScore,
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
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Progress header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('Test 29 / 29',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 13)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _qIndex / _totalQ,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              color: const Color(0xFF00C853),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${_qIndex + 1}/$_totalQ',
                            style: const TextStyle(
                                color: Color(0xFF00C853), fontSize: 13)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Pattern Master â€” SÄ±radaki ne?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  if (_qIndex < _totalQ && _questions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Soru: ${_qIndex + 1}/$_totalQ',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                          Text('${_score * _ptsPerQ} puan',
                              style: const TextStyle(
                                  color: Color(0xFF00B4FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
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
              // Feedback pill
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
}
