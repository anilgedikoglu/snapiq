import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class ImpulseControlScreen extends StatefulWidget {
  const ImpulseControlScreen({super.key});

  @override
  State<ImpulseControlScreen> createState() => _ImpulseControlScreenState();
}

class _ImpulseControlScreenState extends State<ImpulseControlScreen> {
  static const _gameId = 'impulse_control';
  static const _xpReward = 25;
  static const _gameName = 'Impulse Control';
  static const _totalRounds = 20;

  int _lives = 3;
  int _score = 0;
  int _round = 0;
  bool _isGo = false;
  bool _showing = false;
  bool _tapped = false;
  String _message = '';
  bool _started = false;
  bool _gameEnded = false;
  Timer? _showTimer;
  Timer? _waitTimer;
  final _rand = Random();

  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
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
    _showTimer?.cancel();
    _waitTimer?.cancel();

    // Wait some time before showing
    final waitMs = 600 + _rand.nextInt(1400);
    setState(() {
      _showing = false;
      _isGo = false;
      _tapped = false;
      _message = '...';
    });
    _waitTimer = Timer(Duration(milliseconds: waitMs), () {
      if (!mounted || _gameEnded) return;
      final isGo = _rand.nextDouble() < 0.65;
      final displayMs = 500 + _rand.nextInt(1500);
      setState(() {
        _isGo = isGo;
        _showing = true;
        _tapped = false;
        _message = '';
      });
      _showTimer = Timer(Duration(milliseconds: displayMs), () {
        if (!mounted || _gameEnded) return;
        if (_isGo && !_tapped) {
          setState(() => _message = 'Kaçırdın!');
        }
        setState(() {
          _showing = false;
          _round++;
        });
        Timer(const Duration(milliseconds: 400), () {
          if (mounted && !_gameEnded) _nextRound();
        });
      });
    });
  }

  void _onTap() {
    if (_gameEnded || !_started || !_showing || _tapped) return;
    _tapped = true;
    _showTimer?.cancel();
    if (_isGo) {
      setState(() {
        _score++;
        _message = '✓';
        _showing = false;
        _round++;
      });
      Timer(const Duration(milliseconds: 400), () {
        if (mounted && !_gameEnded) _nextRound();
      });
    } else {
      setState(() {
        _lives--;
        _message = '✗';
        _showing = false;
        _round++;
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
      Timer(const Duration(milliseconds: 400), () {
        if (mounted && !_gameEnded) _nextRound();
      });
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    _showTimer?.cancel();
    _waitTimer?.cancel();
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
    _showTimer?.cancel();
    _waitTimer?.cancel();
    setState(() {
      _lives = 3;
      _score = 0;
      _round = 0;
      _isGo = false;
      _showing = false;
      _tapped = false;
      _message = '';
      _started = false;
      _gameEnded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color bgFlash = Colors.transparent;
    if (_showing) {
      bgFlash = _isGo
          ? Colors.green.withValues(alpha: 0.08)
          : Colors.red.withValues(alpha: 0.08);
    }

    return Scaffold(
      body: AnimatedBackground(
        child: Container(
          color: bgFlash,
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
                  child: _started
                      ? GestureDetector(
                          onTap: _onTap,
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_showing)
                                  Text(
                                    _isGo ? 'GO' : 'BEKLE',
                                    style: TextStyle(
                                      color: _isGo
                                          ? const Color(0xFF00C853)
                                          : Colors.red,
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: _isGo
                                              ? const Color(0xFF00C853)
                                              : Colors.red,
                                          blurRadius: 30,
                                        )
                                      ],
                                    ),
                                  )
                                else if (_message.isNotEmpty)
                                  Text(_message,
                                      style: TextStyle(
                                          color: _message == '✓'
                                              ? const Color(0xFF00C853)
                                              : _message == 'Kaçırdın!'
                                                  ? const Color(0xFFFDD835)
                                                  : Colors.red,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold))
                                else
                                  const Text('...',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 48)),
                                const SizedBox(height: 20),
                                if (!_showing)
                                  const Text('Ekrana dokun',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 14)),
                              ],
                            ),
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
            child: Text('Impulse Control',
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
