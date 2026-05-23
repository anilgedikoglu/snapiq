import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class MirrorBrainScreen extends StatefulWidget {
  const MirrorBrainScreen({super.key});

  @override
  State<MirrorBrainScreen> createState() => _MirrorBrainScreenState();
}

class _MirrorBrainScreenState extends State<MirrorBrainScreen> {
  static const _gameId = 'mirror_brain';
  static const _xpReward = 30;
  static const _gameName = 'Mirror Brain';
  static const _totalRounds = 15;

  static const _arrows = ['←', '→', '↑', '↓'];
  static const _opposites = {'←': '→', '→': '←', '↑': '↓', '↓': '↑'};

  int _score = 0;
  int _lives = 3;
  int _round = 0;
  double _timeLeft = 3.0;
  String _arrow = '←';
  bool _gameEnded = false;
  Timer? _timer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextRound() {
    if (_round >= _totalRounds) {
      _endGame();
      return;
    }
    _timer?.cancel();
    setState(() {
      _arrow = _arrows[_rand.nextInt(_arrows.length)];
      _timeLeft = 3.0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        setState(() {
          _lives--;
          _round++;
        });
        if (_lives <= 0) {
          _endGame();
        } else {
          _nextRound();
        }
      }
    });
  }

  void _tap(String direction) {
    if (_gameEnded) return;
    _timer?.cancel();
    final correct = _opposites[_arrow];
    if (direction == correct) {
      setState(() {
        _score++;
        _round++;
      });
    } else {
      setState(() {
        _lives--;
        _round++;
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
    }
    _nextRound();
  }

  void _endGame() {
    if (_gameEnded) return;
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
      _score = 0;
      _lives = 3;
      _round = 0;
      _timeLeft = 3.0;
      _gameEnded = false;
    });
    _nextRound();
  }

  Widget _dirButton(String dir) {
    return GestureDetector(
      onTap: () => _tap(dir),
      child: Container(
        width: 80,
        height: 72,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFBB86FC).withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(dir,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
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
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (i) => Text(i < _lives ? '❤️' : '🖤',
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    Text('$_score/$_totalRounds',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_timeLeft / 3.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFFDD835)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(S.mirrorTapLabel,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            letterSpacing: 1)),
                    const SizedBox(height: 24),
                    Text(_arrow,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        _dirButton('↑'),
                        _dirButton('↓'),
                        _dirButton('←'),
                        _dirButton('→'),
                      ],
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
            child: Text('Mirror Brain',
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
