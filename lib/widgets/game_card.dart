import 'package:flutter/material.dart';
import '../models/mini_game.dart';
import 'neon_chip.dart';

class GameCard extends StatefulWidget {
  final MiniGameInfo game;
  final int bestScore;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.game,
    required this.bestScore,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  double _scale = 1.0;

  String _difficultyLabel(GameDifficulty d) {
    switch (d) {
      case GameDifficulty.easy:
        return 'Kolay';
      case GameDifficulty.medium:
        return 'Orta';
      case GameDifficulty.hard:
        return 'Zor';
    }
  }

  Color _difficultyColor(GameDifficulty d) {
    switch (d) {
      case GameDifficulty.easy:
        return const Color(0xFF00C853);
      case GameDifficulty.medium:
        return const Color(0xFFFDD835);
      case GameDifficulty.hard:
        return const Color(0xFFFF7043);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final diffColor = _difficultyColor(game.difficulty);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 160,
          height: 200,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: game.color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: game.color.withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Top 60%: icon with gradient bg
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        game.color.withValues(alpha: 0.18),
                        game.color.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: game.color.withValues(alpha: 0.12),
                        boxShadow: [
                          BoxShadow(
                            color: game.color.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(game.icon, size: 36, color: game.color),
                    ),
                  ),
                ),
              ),
              // Bottom 40%: info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: TextStyle(
                          color: game.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        game.subtitle,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          NeonChip(
                            label: _difficultyLabel(game.difficulty),
                            color: diffColor,
                          ),
                          const SizedBox(width: 4),
                          NeonChip(label: game.duration, color: game.color),
                          const Spacer(),
                          Text(
                            '${widget.bestScore}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9),
                          ),
                        ],
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
}
