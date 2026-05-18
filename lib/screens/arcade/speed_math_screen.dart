import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class SpeedMathScreen extends StatefulWidget {
  const SpeedMathScreen({super.key});

  @override
  State<SpeedMathScreen> createState() => _SpeedMathScreenState();
}

class _SpeedMathScreenState extends State<SpeedMathScreen> {
  static const _gameId = 'speed_math';
  static const _xpReward = 30;
  static const _gameName = 'Speed Math';
  static const _totalQ = 10;

  int _qIndex = 0;
  int _score = 0;
  double _timeLeft = 4.0;
  String _question = '';
  bool _isCorrect = false;
  bool _started = false;
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_qIndex >= _totalQ) {
      _endGame();
      return;
    }
    final a = 2 + _rand.nextInt(14);
    final b = 2 + _rand.nextInt(8);
    final opIdx = _rand.nextInt(3);
    final ops = ['+', '-', '×'];
    final op = ops[opIdx];
    int correct;
    if (op == '+') {
      correct = a + b;
    } else if (op == '-') {
      correct = a - b;
    } else {
      correct = a * b;
    }

    final showCorrect = _rand.nextBool();
    int displayed;
    if (showCorrect) {
      displayed = correct;
    } else {
      final off = 1 + _rand.nextInt(3);
      displayed = correct + (_rand.nextBool() ? off : -off);
    }

    _timer?.cancel();
    setState(() {
      _question = '$a $op $b = $displayed ?';
      _isCorrect = displayed == correct;
      _timeLeft = 4.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    setState(() => _qIndex++);
    _nextQuestion();
  }

  void _onUserAnswer(bool userSaysCorrect) {
    if (_gameEnded || !_started) return;
    _timer?.cancel();
    if (userSaysCorrect == _isCorrect) {
      setState(() => _score++);
    }
    setState(() => _qIndex++);
    _nextQuestion();
  }

  void _endGame() {
    if (_gameEnded) return;
    _timer?.cancel();
    setState(() => _gameEnded = true);
    _gameOver(_score * 10);
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
    setState(() {
      _qIndex = 0;
      _score = 0;
      _timeLeft = 4.0;
      _started = false;
      _gameEnded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_started) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Soru: ${_qIndex + 1}/$_totalQ',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                      Text('$_score/$_totalQ',
                          style: const TextStyle(
                              color: Color(0xFF00B4FF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_timeLeft / 4.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                          _timeLeft > 2.0
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF7043)),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            const Color(0xFF00B4FF).withValues(alpha: 0.3)),
                  ),
                  child: Text(_question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onUserAnswer(true),
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      Colors.green.withValues(alpha: 0.6)),
                            ),
                            child: const Center(
                              child: Text('✓ DOĞRU',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onUserAnswer(false),
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.6)),
                            ),
                            child: const Center(
                              child: Text('✗ YANLIŞ',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                Expanded(
                  child: Center(
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
            child: Text('Speed Math',
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
