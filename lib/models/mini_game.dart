import 'package:flutter/material.dart';

enum GameCategory { timing, aimShoot, reflexArcade, brainFocus }
enum GameDifficulty { easy, medium, hard }

class MiniGameInfo {
  final String id;
  final String title;
  final String subtitle;
  final GameCategory category;
  final GameDifficulty difficulty;
  final Color color;
  final IconData icon;
  final String duration;
  final Widget Function() builder;

  const MiniGameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.difficulty,
    required this.color,
    required this.icon,
    required this.duration,
    required this.builder,
  });
}
