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

class SequenceRushScreen extends StatefulWidget {
  const SequenceRushScreen({super.key});

  @override
  State<SequenceRushScreen> createState() => _SequenceRushScreenState();
}

class _SequenceRushScreenState extends State<SequenceRushScreen> {
  static const _gameId = 'sequence_rush';
  static const _xpReward = 30;
  static const _gameName = 'Sequence Rush';

  static const _btnColors = [
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFFFDD835), // yellow
  ];

  List<int> _sequence = [];
  List<int> _userInput = [];
  bool _isWatching = false;
  int _level = 1;
  int _score = 0;
  int _lives = 3;
  int _litIndex = -1;
  bool _gameEnded = false;
  bool _inputEnabled = false;
  Timer? _watchTimer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _sequence = [_rand.nextInt(4)];
    _playSequence();
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    super.dispose();
  }

  void _playSequence() {
    setState(() {
      _isWatching = true;
      _inputEnabled = false;
      _userInput = [];
      _litIndex = -1;
    });
    int i = 0;
    void next() {
      if (!mounted) return;
      if (i < _sequence.length) {
        setState(() => _litIndex = _sequence[i]);
        _watchTimer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _litIndex = -1);
          _watchTimer = Timer(const Duration(milliseconds: 200), () {
            i++;
            next();
          });
        });
      } else {
        setState(() {
          _isWatching = false;
          _inputEnabled = true;
        });
      }
    }

    _watchTimer = Timer(const Duration(milliseconds: 400), next);
  }

  void _tap(int index) {
    if (_gameEnded || !_inputEnabled) return;
    setState(() {
      _userInput.add(index);
      _litIndex = index;
    });
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _litIndex = -1);
    });

    final pos = _userInput.length - 1;
    if (_userInput[pos] != _sequence[pos]) {
      // Wrong
      setState(() {
        _lives--;
        _inputEnabled = false;
      });
      if (_lives <= 0) {
        _endGame();
        return;
      }
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) _playSequence();
      });
      return;
    }
    if (_userInput.length == _sequence.length) {
      // Correct full sequence
      setState(() {
        _score++;
        _level++;
        _inputEnabled = false;
        _sequence.add(_rand.nextInt(4));
      });
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) _playSequence();
      });
    }
  }

  void _endGame() {
    if (_gameEnded) return;
    _watchTimer?.cancel();
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
    _watchTimer?.cancel();
    setState(() {
      _sequence = [_rand.nextInt(4)];
      _userInput = [];
      _isWatching = false;
      _level = 1;
      _score = 0;
      _lives = 3;
      _litIndex = -1;
      _gameEnded = false;
      _inputEnabled = false;
    });
    _playSequence();
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
                    Text(S.seqLevelScore(_level, _score),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isWatching ? S.seqRushWatch : (_inputEnabled ? S.seqRushRepeat : ''),
                style: TextStyle(
                    color: _isWatching
                        ? const Color(0xFFFDD835)
                        : const Color(0xFF00B4FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(4, (i) {
                      final isLit = _litIndex == i;
                      final color = _btnColors[i];
                      return GestureDetector(
                        onTap: () => _tap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 130,
                          height: 120,
                          decoration: BoxDecoration(
                            color: isLit
                                ? color
                                : color.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isLit
                                    ? color
                                    : color.withValues(alpha: 0.4),
                                width: 2),
                            boxShadow: isLit
                                ? [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.6),
                                        blurRadius: 20)
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
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
            child: Text('Sequence Rush',
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
