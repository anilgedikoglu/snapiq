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

class NumberHunterScreen extends StatefulWidget {
  const NumberHunterScreen({super.key});

  @override
  State<NumberHunterScreen> createState() => _NumberHunterScreenState();
}

class _NumberHunterScreenState extends State<NumberHunterScreen> {
  static const _gameId   = 'number_hunter';
  static const _xpReward = 25;
  static const _gameName = 'Number Hunter';
  static const _duration = 30;

  int _timeLeft   = _duration;
  int _score      = 0;
  int _target     = 0;
  List<int> _numbers = [];
  bool _gameEnded = false;
  int? _flashIndex;
  Timer? _flashTimer;
  Timer? _countdownTimer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _nextTarget();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameEnded) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _countdownTimer?.cancel();
        setState(() => _gameEnded = true);
        _gameOver(_score);
      }
    });
  }

  void _nextTarget() {
    final nums = List.generate(20, (i) => i + 1)..shuffle(_rand);
    // Pick target from a random position so it appears anywhere in the grid
    final targetPos = _rand.nextInt(nums.length);
    setState(() {
      _numbers   = nums;
      _target    = nums[targetPos];
      _flashIndex = null;
    });
  }

  void _tap(int index) {
    if (_gameEnded) return;
    if (_numbers[index] == _target) {
      _flashTimer?.cancel();
      setState(() {
        _score++;
        _flashIndex = index;
      });
      _flashTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) _nextTarget();
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
    _countdownTimer?.cancel();
    setState(() {
      _timeLeft  = _duration;
      _score     = 0;
      _gameEnded = false;
      _flashIndex = null;
    });
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // Timer progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _timeLeft / _duration,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: _timeLeft > 10
                        ? const Color(0xFF00B4FF)
                        : Colors.redAccent,
                    minHeight: 6,
                  ),
                ),
              ),
              // Score + time row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_timeLeft s',
                        style: TextStyle(
                            color: _timeLeft > 10
                                ? Colors.white54
                                : Colors.redAccent,
                            fontSize: 14)),
                    Text('$_score bulundu',
                        style: const TextStyle(
                            color: Color(0xFF00B4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Target label
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  S.numberTarget(_target),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Color(0xFF00B4FF), blurRadius: 12)]),
                ),
              ),
              // Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                  child: GridView.count(
                    shrinkWrap: true,
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
                            child: Text(
                              '${_numbers[i]}',
                              style: TextStyle(
                                color: isFlash
                                    ? const Color(0xFF00C853)
                                    : Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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
