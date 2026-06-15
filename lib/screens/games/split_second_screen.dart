import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/arcade_result_overlay.dart';

class SplitSecondScreen extends StatefulWidget {
  const SplitSecondScreen({super.key});

  @override
  State<SplitSecondScreen> createState() => _SplitSecondScreenState();
}

class _SplitSecondScreenState extends State<SplitSecondScreen> {
  static const _gameId = 'split_second';
  static const _xpReward = 25;
  static const _gameName = 'Split Second';

  final _rand = Random();
  int _lives = 3;
  int _score = 0;
  int _combo = 0;
  int _signal = 0; // 0=blank, 1=GO, 2=STOP
  int _round = 0;
  static const int _totalRounds = 30;
  Timer? _signalTimer;
  Timer? _blankTimer;
  bool _tapped = false;
  bool _gameOver = false;
  bool _gameStarted = false;
  bool _waitingForNext = false;

  @override
  void dispose() {
    _signalTimer?.cancel();
    _blankTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() => _gameStarted = true);
    _nextSignal();
  }

  void _nextSignal() {
    if (_gameOver || _round >= _totalRounds) {
      if (_round >= _totalRounds) {
        setState(() => _gameOver = true);
        _gameOverDialog(_score);
      }
      return;
    }

    setState(() {
      _tapped = false;
      _waitingForNext = false;
    });

    // 200-400ms blank before signal
    _blankTimer = Timer(Duration(milliseconds: 200 + _rand.nextInt(200)), () {
      if (!mounted || _gameOver) return;
      final isGo = _rand.nextBool();
      setState(() {
        _signal = isGo ? 1 : 2;
        _round++;
      });

      // Signal visible for 400-800ms
      final visible = 400 + _rand.nextInt(400);
      _signalTimer = Timer(Duration(milliseconds: visible), () {
        if (!mounted || _gameOver) return;
        // Time's up - if was GO and not tapped = miss, lose life
        if (_signal == 1 && !_tapped) {
          setState(() {
            _lives--;
            _combo = 0;
            _signal = 0;
          });
          if (_lives <= 0) {
            setState(() => _gameOver = true);
            _gameOverDialog(_score);
            return;
          }
        } else if (_signal == 2 && !_tapped) {
          // Correctly didn't tap STOP - reward
          setState(() {
            _combo++;
            final points = 1 * _combo.clamp(1, 5);
            _score += points;
            _signal = 0;
          });
        } else {
          setState(() => _signal = 0);
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_gameOver) _nextSignal();
        });
      });
    });
  }

  void _onTap() {
    if (!_gameStarted || _gameOver || _tapped || _signal == 0 || _waitingForNext) return;
    _tapped = true;

    if (_signal == 1) {
      // Correct: GO
      _signalTimer?.cancel();
      setState(() {
        _combo++;
        final points = 1 * _combo.clamp(1, 5);
        _score += points;
        _signal = 0;
        _waitingForNext = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_gameOver) _nextSignal();
      });
    } else if (_signal == 2) {
      // Wrong: tapped STOP
      _signalTimer?.cancel();
      setState(() {
        _lives--;
        _combo = 0;
        _signal = 0;
        _waitingForNext = true;
      });
      if (_lives <= 0) {
        setState(() => _gameOver = true);
        _gameOverDialog(_score);
        return;
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_gameOver) _nextSignal();
      });
    }
  }

  Future<void> _gameOverDialog(int score) async {
    _signalTimer?.cancel();
    _blankTimer?.cancel();
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
    _signalTimer?.cancel();
    _blankTimer?.cancel();
    setState(() {
      _lives = 3;
      _score = 0;
      _combo = 0;
      _signal = 0;
      _round = 0;
      _tapped = false;
      _gameOver = false;
      _gameStarted = false;
      _waitingForNext = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                            3,
                            (i) => Text(i < _lives ? '❤️' : '🖤',
                                style: const TextStyle(fontSize: 22))),
                      ),
                      Text(
                        S.circleScore(_score),
                        style: const TextStyle(
                            color: Color(0xFFFF7043),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_combo >= 2)
                  Text(
                    'x${_combo.clamp(1, 5)} COMBO',
                    style: const TextStyle(
                        color: Color(0xFFFDD835),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                Expanded(
                  child: Center(
                    child: _gameStarted
                        ? _buildSignal()
                        : GestureDetector(
                            onTap: _startGame,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7043)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFFF7043)
                                            .withValues(alpha: 0.5)),
                                  ),
                                  child: Text(S.startBtn,
                                      style: const TextStyle(
                                          color: Color(0xFFFF7043),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  S.splitSecondInstr,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    S.focusRound(_round, _totalRounds),
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignal() {
    if (_signal == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C853).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF00C853), width: 3),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5)
              ],
            ),
            child: const Center(
              child: Text('GO',
                  style: TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 56,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (_signal == 2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE91E63).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFFE91E63), width: 3),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5)
              ],
            ),
            child: const Center(
              child: Text('STOP',
                  style: TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 44,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }
    return const SizedBox(
      width: 160,
      height: 160,
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
            child: Text('Split Second',
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
