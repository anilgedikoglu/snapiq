import '../services/storage_service.dart';

class PlayerProfile {
  final int level;
  final int xp;
  final int totalGames;
  final double avgSnapIQ;
  final int bestSnapIQ;
  final int bestReactionMs;
  final List<String> unlockedAchievements;
  final List<String> unlockedThemes;
  final String selectedTheme;

  const PlayerProfile({
    required this.level,
    required this.xp,
    required this.totalGames,
    required this.avgSnapIQ,
    required this.bestSnapIQ,
    required this.bestReactionMs,
    required this.unlockedAchievements,
    required this.unlockedThemes,
    required this.selectedTheme,
  });

  factory PlayerProfile.fromStorage(StorageService s) {
    return PlayerProfile(
      level: s.level,
      xp: s.xp,
      totalGames: s.totalGames,
      avgSnapIQ: s.avgSnapIQ,
      bestSnapIQ: s.bestSnapIQ,
      bestReactionMs: s.bestReactionMs,
      unlockedAchievements: s.unlockedAchievements,
      unlockedThemes: s.unlockedThemes,
      selectedTheme: s.selectedTheme,
    );
  }
}
