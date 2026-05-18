import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

class NumberHunterScreen extends StatefulWidget {
  const NumberHunterScreen({super.key});

  @override
  State<NumberHunterScreen> createState() => _NumberHunterScreenState();
}

class _NumberHunterScreenState extends State<NumberHunterScreen> {
  static const _gameId = 'number_hunter';
  static const _xpReward = 25;
  static const _gameName = 'Number Hunter';
  static const _totalRounds = 10;

  int _round = 0;
  int _score = 0;
  int _target = 0;
  List<int> _numbers = [];
  bool _started = false;
  bool _gameEnded = false;
  DateTime? _roundStart;
  int? _flashIndex;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _nextRound();
  }

  void _nextRound() {
    if (_round >= _totalRounds) {
      setState(() => _gameEnded = true);
      _gameOver(_score);
      return;
    }
    final nums = List.generate(20, (i) => i + 1)..shuffle();
    final t = nums[0]; // guaranteed to be in list
    setState(() {
      _numbers = nums;
      _target = t;
      _roundStart = DateTime.now();
      _flashIndex = null;
    });
  }

  void _tap(int index) {
    if (_gameEnded || !_started) return;
    final num = _numbers[index];
    if (num == _target) {
      final elapsed = DateTime.now().difference(_roundStart!).inMilliseconds;
      final pts = (10 - (elapsed ~/ 500)).clamp(1, 10);
      _flashTimer?.cancel();
      setState(() {
        _score += pts;
        _flashIndex = index;
        _round++;
      });
      _flashTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _nextRound();
      });
    }
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
    _flashTimer?.cancel();
    setState(() {
      _round = 0;
      _score = 0;
      _started = false;
      _gameEnded = false;
      _flashIndex = null;
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
                const SizedBox(height: 12),
                Text('$_target\'i bul!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(_numbers.length, (i) {
                        final isFlash = _flashIndex == i;
                        return GestureDetector(
                          onTap: () => _tap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isFlash
                                  ? const Color(0xFF00C853).withValues(alpha: 0.4)
                                  : const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isFlash
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFF00B4FF)
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text('${_numbers[i]}',
                                  style: TextStyle(
                                      color: isFlash
                                          ? const Color(0xFF00C853)
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _start,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  const Color(0xFF00B4FF).withValues(alpha: 0.5)),
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
            child: Text('Number Hunter',
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
