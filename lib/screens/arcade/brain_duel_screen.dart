import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
// arcade_result_overlay not used — brain_duel has custom result screen

enum _DuelPhase { handover1, playing1, handover2, playing2, result }

class _Circle {
  final int id;
  double x;
  double y;
  _Circle({required this.id, required this.x, required this.y});
}

class BrainDuelScreen extends StatefulWidget {
  const BrainDuelScreen({super.key});

  @override
  State<BrainDuelScreen> createState() => _BrainDuelScreenState();
}

class _BrainDuelScreenState extends State<BrainDuelScreen> {
  static const _gameId = 'brain_duel';
  static const _xpReward = 35;

  _DuelPhase _phase = _DuelPhase.handover1;
  int _score1 = 0;
  int _score2 = 0;
  int _playTimeLeft = 10;
  final List<_Circle> _circles = [];
  int _nextId = 0;
  Timer? _countdownTimer;
  Timer? _spawnTimer;
  Timer? _despawnTimer;
  final _rand = Random();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _despawnTimer?.cancel();
    super.dispose();
  }

  void _startPlaying() {
    _circles.clear();
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _playTimeLeft--);
      if (_playTimeLeft <= 0) {
        _countdownTimer?.cancel();
        _spawnTimer?.cancel();
        if (_phase == _DuelPhase.playing1) {
          setState(() => _phase = _DuelPhase.handover2);
        } else {
          setState(() => _phase = _DuelPhase.result);
          _endGame();
        }
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      final id = _nextId++;
      setState(() {
        _circles.add(_Circle(
          id: id,
          x: 30 + _rand.nextDouble() * 280,
          y: 80 + _rand.nextDouble() * 420,
        ));
      });
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _circles.removeWhere((c) => c.id == id));
      });
    });
  }

  void _tapCircle(_Circle c) {
    if (_phase != _DuelPhase.playing1 && _phase != _DuelPhase.playing2) return;
    setState(() {
      _circles.removeWhere((item) => item.id == c.id);
      if (_phase == _DuelPhase.playing1) {
        _score1++;
      } else {
        _score2++;
      }
    });
  }

  void _endGame() {
    _gameOver(max(_score1, _score2));
  }

  Future<void> _gameOver(int score) async {
    final s = await StorageService.getInstance();
    await s.saveArcadeBestScore(_gameId, score);
    await s.saveXP(_xpReward);
    final newLevel = XpService.levelForXp(s.xp);
    await s.saveLevel(newLevel);
    await AchievementService.checkArcadeAchievements(_gameId, score, s);
    await AdService().incrementGameCountAndMaybeShow();
    // No dialog — result shown inline
  }

  void _restart() {
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    setState(() {
      _phase = _DuelPhase.handover1;
      _score1 = 0;
      _score2 = 0;
      _playTimeLeft = 10;
      _circles.clear();
      _nextId = 0;
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
              Expanded(child: _buildPhase()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _DuelPhase.handover1:
        return _buildHandover(
          playerNum: 1,
          onReady: () {
            setState(() {
              _phase = _DuelPhase.playing1;
              _playTimeLeft = 10;
            });
            _startPlaying();
          },
        );
      case _DuelPhase.playing1:
        return _buildPlayArea(playerNum: 1);
      case _DuelPhase.handover2:
        return _buildHandover(
          playerNum: 2,
          onReady: () {
            setState(() {
              _phase = _DuelPhase.playing2;
              _playTimeLeft = 10;
            });
            _startPlaying();
          },
        );
      case _DuelPhase.playing2:
        return _buildPlayArea(playerNum: 2);
      case _DuelPhase.result:
        return _buildResult();
    }
  }

  Widget _buildHandover({required int playerNum, required VoidCallback onReady}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$playerNum. Oyuncu',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              'Telefonu $playerNum. oyuncuya ver',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onReady,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00B4FF).withValues(alpha: 0.6)),
                ),
                child: const Text('HAZIR',
                    style: TextStyle(
                        color: Color(0xFF00B4FF),
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayArea({required int playerNum}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Oyuncu $playerNum',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13)),
              Text(
                '$_playTimeLeft s',
                style: const TextStyle(
                    color: Color(0xFFFDD835),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                playerNum == 1 ? '$_score1' : '$_score2',
                style: const TextStyle(
                    color: Color(0xFF00B4FF),
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              for (final c in List.from(_circles))
                Positioned(
                  left: c.x - 30,
                  top: c.y - 30,
                  child: GestureDetector(
                    onTap: () => _tapCircle(c),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C853).withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF00C853)
                                  .withValues(alpha: 0.5),
                              blurRadius: 14)
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final winner = _score1 > _score2
        ? '1. Oyuncu Kazandı! 🏆'
        : _score2 > _score1
            ? '2. Oyuncu Kazandı! 🏆'
            : 'Berabere! 🤝';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(winner,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFFDD835),
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreCard('Oyuncu 1', _score1),
                _scoreCard('Oyuncu 2', _score2),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Çıkış'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tekrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(String label, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00B4FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Text('$score',
              style: const TextStyle(
                  color: Color(0xFF00B4FF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
        ],
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
            child: Text('Brain Duel',
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
