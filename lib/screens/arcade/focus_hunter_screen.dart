import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class FocusHunterScreen extends StatefulWidget {
  const FocusHunterScreen({super.key});

  @override
  State<FocusHunterScreen> createState() => _FocusHunterScreenState();
}

class _FocusHunterScreenState extends State<FocusHunterScreen> {
  static const _gameId = 'focus_hunter';
  static const _xpReward = 25;
  static const _gameName = 'Focus Hunter';
  static const _totalRounds = 10;

  static const _pairs = [
    ['😊', '😄'],
    ['🐱', '🐶'],
    ['🍎', '🍊'],
    ['⭐', '🌟'],
    ['🎯', '🎪'],
    ['❤️', '💛'],
    ['🚗', '🚕'],
    ['🌸', '🌺'],
  ];

  int _score = 0;
  int _round = 0;
  List<String> _emojis = [];
  int _oddIndex = -1;
  double _timeLeft = 5.0;
  bool _started = false;
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _gridSize() {
    if (_round < 3) return 4;
    if (_round < 6) return 5;
    return 6;
  }

  void _start() {
    setState(() => _started = true);
    _nextRound();
  }

  void _nextRound() {
    if (_round >= _totalRounds) {
      _endGame();
      return;
    }
    _timer?.cancel();
    final gs = _gridSize();
    final total = gs * gs;
    final pair = _pairs[_rand.nextInt(_pairs.length)];
    final baseEmoji = pair[0];
    final oddEmoji = pair[1];
    final oddIdx = _rand.nextInt(total);
    final emojis = List.generate(total, (i) => i == oddIdx ? oddEmoji : baseEmoji);

    setState(() {
      _emojis = emojis;
      _oddIndex = oddIdx;
      _timeLeft = 5.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        setState(() => _round++);
        _nextRound();
      }
    });
  }

  void _tap(int index) {
    if (_gameEnded || !_started) return;
    _timer?.cancel();
    if (index == _oddIndex) {
      setState(() => _score++);
    }
    setState(() => _round++);
    _nextRound();
  }

  void _endGame() {
    if (_gameEnded) return;
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
      _score = 0;
      _round = 0;
      _emojis = [];
      _oddIndex = -1;
      _timeLeft = 5.0;
      _started = false;
      _gameEnded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = _gridSize();
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tur: ${_round + 1}/$_totalRounds',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    Text('$_score puan',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_started) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_timeLeft / 5.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF00C853)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Farklı olanı bul!',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
              Expanded(
                child: _started
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: GridView.count(
                          crossAxisCount: gs,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(_emojis.length, (i) {
                            return GestureDetector(
                              onTap: () => _tap(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1B2A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Center(
                                  child: Text(_emojis[i],
                                      style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
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
            child: Text('Focus Hunter',
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
