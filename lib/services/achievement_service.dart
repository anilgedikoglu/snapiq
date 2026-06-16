import '../models/achievement.dart';
import '../models/test_result.dart';
import 'storage_service.dart';

class AchievementService {
  /// Check which achievements are newly unlocked by this result.
  /// Also saves them to storage and awards XP.
  static Future<List<Achievement>> checkAndUnlock(
      TestResult result, StorageService storage) async {
    final alreadyUnlocked = storage.unlockedAchievements.toSet();
    final newlyUnlocked = <Achievement>[];

    Future<void> tryUnlock(Achievement ach) async {
      if (!alreadyUnlocked.contains(ach.id)) {
        await storage.saveAchievement(ach.id);
        await storage.saveXP(ach.xpReward);
        newlyUnlocked.add(ach);
      }
    }

    final totalGames = storage.totalGames;

    // first_game
    if (totalGames >= 1) {
      await tryUnlock(Achievement.all.firstWhere((a) => a.id == 'first_game'));
    }

    // games_10
    if (totalGames >= 10) {
      await tryUnlock(Achievement.all.firstWhere((a) => a.id == 'games_10'));
    }

    // games_50
    if (totalGames >= 50) {
      await tryUnlock(Achievement.all.firstWhere((a) => a.id == 'games_50'));
    }

    // games_100
    if (totalGames >= 100) {
      await tryUnlock(Achievement.all.firstWhere((a) => a.id == 'games_100'));
    }

    // reaction_200 — reaction score 100 means < 180ms
    if (result.reactionScore == 100) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'reaction_200'));
    }

    // stroop_perfect
    if (result.stroopScore >= 100) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'stroop_perfect'));
    }

    // memory_perfect
    if (result.memoryScore >= 100) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'memory_perfect'));
    }

    // snapiq_100
    if (result.snapIQ >= 100) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'snapiq_100'));
    }

    // snapiq_130
    if (result.snapIQ >= 130) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'snapiq_130'));
    }

    return newlyUnlocked;
  }

  /// Unlock beat_friend achievement.
  static Future<void> unlockBeatFriend(StorageService storage) async {
    final ach = Achievement.all.firstWhere((a) => a.id == 'beat_friend');
    if (!storage.unlockedAchievements.contains(ach.id)) {
      await storage.saveAchievement(ach.id);
      await storage.saveXP(ach.xpReward);
    }
  }

  /// Unlock daily_done achievement.
  static Future<void> unlockDailyDone(StorageService storage) async {
    final ach = Achievement.all.firstWhere((a) => a.id == 'daily_done');
    if (!storage.unlockedAchievements.contains(ach.id)) {
      await storage.saveAchievement(ach.id);
      await storage.saveXP(ach.xpReward);
    }
  }

  /// Unlock endless_60 achievement.
  static Future<void> unlockEndless60(StorageService storage) async {
    final ach = Achievement.all.firstWhere((a) => a.id == 'endless_60');
    if (!storage.unlockedAchievements.contains(ach.id)) {
      await storage.saveAchievement(ach.id);
      await storage.saveXP(ach.xpReward);
    }
  }

  static Future<void> checkArcadeAchievements(
      String gameId, int score, StorageService storage) async {
    Future<void> tryUnlock(Achievement ach) async {
      if (!storage.unlockedAchievements.contains(ach.id)) {
        await storage.saveAchievement(ach.id);
        await storage.saveXP(ach.xpReward);
      }
    }

    if (gameId == 'tap_target' && score >= 20) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'tap_master'));
    }
    if (gameId == 'focus_hunter' && score >= 10) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'focus_beast'));
    }
    if (gameId == 'speed_math' && score >= 10) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'math_demon'));
    }
    if (gameId == 'color_panic' && score >= 20) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'reflex_monster'));
    }
    if (gameId == 'pattern_master' && score >= 10) {
      await tryUnlock(
          Achievement.all.firstWhere((a) => a.id == 'pattern_king'));
    }
  }
}
