import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class ColorPanicScreen extends StatefulWidget {
  const ColorPanicScreen({super.key});

  @override
  State<ColorPanicScreen> createState() => _ColorPanicScreenState();
}

class _ColorPanicScreenState extends State<ColorPanicScreen> {
  static const _gameId = 'color_panic';
  static const _xpReward = 30;
  static const _gameName = 'Color Panic';

  static const _words = ['KIRMIZI', 'MAVİ', 'YEŞİL', 'SARI', 'MOR', 'TURUNCU'];
  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  int _lives = 3;
  int _score = 0;
  int _intervalMs = 1200;
  String _word = 'KIRMIZI';
  Color _inkColor = Colors.red;
  bool _isMatch = false;
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateRound();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateRound() {
    final wordIdx = _rand.nextInt(_words.length);
    final inkIdx = _rand.nextInt(_colors.length);
    _word = _words[wordIdx];
    _inkColor = _colors[inkIdx];
    _isMatch = wordIdx == inkIdx;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _intervalMs), () {
      if (!mounted || _gameEnded) return;
      // Auto-advance without answer — counts as miss, no penalty on timeout
      setState(() {
        _generateRound();
        _startTimer();
      });
    });
  }

  void _answer(bool userSaysMatch) {
    if (_gameEnded) return;
    _timer?.cancel();
    if (userSaysMatch == _isMatch) {
      setState(() {
        _score++;
        _intervalMs = max(400, _intervalMs - 30);
        _generateRound();
      });
    } else {
      setState(() {
        _lives--;
        _generateRound();
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
    }
    _startTimer();
  }

  void _endGame() {
    _timer?.cancel();
    setState(() => _gameEnded = true);
    _gameOver(_score);
  }

  Future<void> _gameOver(int score) async {
    final s = await StorageService.getInstance();
    final prevBest = s.arcadeBestScore(_gameId);
    final isNewBest = score > prevBest;
    await s.saveArcadeBestScore(_gameId, score);
    await s.saveXP(_xpReward);
    final newLevel = XpService.levelForXp(s.xp);
    await s.saveLevel(newLevel);
    await AchievementService.checkArcadeAchievements(_gameId, score, s);
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
      _lives = 3;
      _score = 0;
      _intervalMs = 1200;
      _gameEnded = false;
      _generateRound();
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTopRow(),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _word,
                        style: TextStyle(
                          color: _inkColor,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: _inkColor, blurRadius: 16)],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _answer(true),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.6)),
                                  ),
                                  child: const Center(
                                    child: Text('✓ EŞLEŞME',
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
                                onTap: () => _answer(false),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.red.withValues(alpha: 0.6)),
                                  ),
                                  child: const Center(
                                    child: Text('✗ FARKLI',
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
                    ],
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
            child: Text('Color Panic',
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

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Text(i < _lives ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          Text('$_score',
              style: const TextStyle(
                  color: Color(0xFF00B4FF),
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
