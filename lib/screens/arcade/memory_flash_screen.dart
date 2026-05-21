import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/arcade_result_overlay.dart';

enum _Phase { idle, watch, recall, result }

class MemoryFlashScreen extends StatefulWidget {
  const MemoryFlashScreen({super.key});

  @override
  State<MemoryFlashScreen> createState() => _MemoryFlashScreenState();
}

class _MemoryFlashScreenState extends State<MemoryFlashScreen> {
  static const _gameId = 'memory_flash';
  static const _xpReward = 30;
  static const _gameName = 'Memory Flash';

  _Phase _phase = _Phase.idle;
  int _level = 1;
  int _gridSize = 3;
  int _patternSize = 2;
  List<int> _pattern = [];
  List<int> _selected = [];
  int _score = 0;
  int _lives = 3;
  bool _gameEnded = false;
  Timer? _watchTimer;

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    super.dispose();
  }

  void _nextRound() {
    final total = _gridSize * _gridSize;
    final indices = List.generate(total, (i) => i)..shuffle();
    final pat = indices.take(_patternSize).toList();
    setState(() {
      _pattern = pat;
      _selected = [];
      _phase = _Phase.watch;
    });
    final watchMs = 1500 + _level * 200;
    _watchTimer = Timer(Duration(milliseconds: watchMs), () {
      if (mounted) setState(() => _phase = _Phase.recall);
    });
  }

  void _tapCell(int index) {
    if (_phase != _Phase.recall || _gameEnded) return;
    if (_selected.contains(index)) return;
    setState(() => _selected.add(index));
    if (_selected.length == _pattern.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final correct = _selected.toSet().containsAll(_pattern) &&
        _pattern.toSet().containsAll(_selected);
    if (correct) {
      setState(() {
        _score++;
        _level++;
        if (_level % 2 == 0) _patternSize = (_patternSize + 1).clamp(2, 12);
        if (_level % 3 == 0) _gridSize = (_gridSize + 1).clamp(3, 5);
        _phase = _Phase.result;
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) _nextRound();
      });
    } else {
      setState(() {
        _lives--;
        _phase = _Phase.result;
      });
      if (_lives <= 0) {
        setState(() => _gameEnded = true);
        _gameOver(_score);
      } else {
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) _nextRound();
        });
      }
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
    _watchTimer?.cancel();
    setState(() {
      _level = 1;
      _gridSize = 3;
      _patternSize = 2;
      _pattern = [];
      _selected = [];
      _score = 0;
      _lives = 3;
      _gameEnded = false;
    });
    _nextRound();
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
                    Text('Seviye $_level | $_score puan',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildPhaseText(),
              const SizedBox(height: 16),
              Expanded(
                child: Center(child: _buildGrid()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseText() {
    String text = '';
    Color color = Colors.white54;
    switch (_phase) {
      case _Phase.watch:
        text = 'Ezberle!';
        color = const Color(0xFFFDD835);
        break;
      case _Phase.recall:
        text = 'Hangileri?';
        color = const Color(0xFF00B4FF);
        break;
      case _Phase.result:
        text = '';
        break;
      default:
        break;
    }
    return Text(text,
        style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildGrid() {
    final total = _gridSize * _gridSize;
    final size = (MediaQuery.of(context).size.width - 48) / _gridSize;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(total, (i) {
        final isPattern = _pattern.contains(i);
        final isSelected = _selected.contains(i);
        Color cellColor;
        if (_phase == _Phase.watch) {
          cellColor = isPattern
              ? const Color(0xFFBB86FC)
              : const Color(0xFF0D1B2A);
        } else if (_phase == _Phase.recall) {
          cellColor = isSelected
              ? const Color(0xFF00B4FF)
              : const Color(0xFF0D1B2A);
        } else {
          // result
          if (isPattern && isSelected) {
            cellColor = const Color(0xFF00C853);
          } else if (isPattern) {
            cellColor = const Color(0xFFFF7043);
          } else if (isSelected) {
            cellColor = Colors.red.withValues(alpha: 0.5);
          } else {
            cellColor = const Color(0xFF0D1B2A);
          }
        }
        return GestureDetector(
          onTap: () => _tapCell(i),
          child: Container(
            width: size - 6,
            height: size - 6,
            decoration: BoxDecoration(
              color: cellColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cellColor == const Color(0xFF0D1B2A)
                    ? Colors.white12
                    : cellColor,
              ),
              boxShadow: cellColor != const Color(0xFF0D1B2A)
                  ? [BoxShadow(color: cellColor.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
          ),
        );
      }),
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
            child: Text('Memory Flash',
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
