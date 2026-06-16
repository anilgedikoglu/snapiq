import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_result.dart';

class StorageService {
  static const _keyBestFinalScore = 'bestFinalScore';
  static const _keyBestSnapIQ = 'bestSnapIQ';
  static const _keyBestCognitiveAge = 'bestCognitiveAge';
  static const _keyTotalGames = 'totalGamesPlayed';
  static const _keyLastScores = 'lastScores';

  // New keys
  static const _keyTotalTestTimeSecs = 'totalTestTimeSecs';
  static const _keySnapIQHistory = 'snapIQHistory';
  static const _keyBestReactionMs = 'bestReactionMs';
  static const _keyXp = 'xp';
  static const _keyLevel = 'level';
  static const _keyUnlockedThemes = 'unlockedThemes';
  static const _keyUnlockedAchievements = 'unlockedAchievements';
  static const _keyDailyChallengLastDate = 'dailyChallengeLastDate';
  static const _keyDailyChallengeBestScore = 'dailyChallengeBestScore';
  static const _keyGameHistory = 'gameHistory';
  static const _keySpinWheelLastDate = 'spinWheelLastDate';
  static const _keySoundEnabled = 'soundEnabled';
  static const _keyVibrationEnabled = 'vibrationEnabled';
  static const _keySelectedTheme = 'selectedTheme';
  static const _keyReduceAnimations = 'reduceAnimations';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  double get bestFinalScore => _prefs.getDouble(_keyBestFinalScore) ?? 0;
  int get bestSnapIQ => _prefs.getInt(_keyBestSnapIQ) ?? 0;
  int get bestCognitiveAge => _prefs.getInt(_keyBestCognitiveAge) ?? 0;
  int get totalGames => _prefs.getInt(_keyTotalGames) ?? 0;

  // New getters
  int get totalTestTimeSecs => _prefs.getInt(_keyTotalTestTimeSecs) ?? 0;
  int get bestReactionMs => _prefs.getInt(_keyBestReactionMs) ?? 0;
  int get xp => _prefs.getInt(_keyXp) ?? 0;
  int get level => _prefs.getInt(_keyLevel) ?? 1;
  List<String> get unlockedThemes =>
      _prefs.getStringList(_keyUnlockedThemes) ?? ['neon'];
  List<String> get unlockedAchievements =>
      _prefs.getStringList(_keyUnlockedAchievements) ?? [];
  String get dailyChallengeLastDate =>
      _prefs.getString(_keyDailyChallengLastDate) ?? '';
  int get dailyChallengeBestScore =>
      _prefs.getInt(_keyDailyChallengeBestScore) ?? 0;
  String get spinWheelLastDate =>
      _prefs.getString(_keySpinWheelLastDate) ?? '';
  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  String get selectedTheme =>
      _prefs.getString(_keySelectedTheme) ?? 'neon';
  bool get reduceAnimations =>
      _prefs.getBool(_keyReduceAnimations) ?? false;

  double get avgSnapIQ {
    final list = _prefs.getStringList(_keySnapIQHistory) ?? [];
    if (list.isEmpty) return 0;
    final vals = list.map((s) => double.tryParse(s) ?? 0).toList();
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  List<Map<String, dynamic>> get gameHistory {
    final raw = _prefs.getStringList(_keyGameHistory) ?? [];
    return raw.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
  }

  List<TestResult> get lastScores {
    final raw = _prefs.getStringList(_keyLastScores) ?? [];
    return raw
        .map((s) {
          try {
            return TestResult.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<TestResult>()
        .toList();
  }

  Future<void> saveResult(TestResult result) async {
    final total = totalGames + 1;
    await _prefs.setInt(_keyTotalGames, total);

    if (result.finalScore > bestFinalScore) {
      await _prefs.setDouble(_keyBestFinalScore, result.finalScore);
    }
    if (result.snapIQ > bestSnapIQ) {
      await _prefs.setInt(_keyBestSnapIQ, result.snapIQ);
    }
    // Lower cognitive age is "better"
    final prevAge = bestCognitiveAge;
    if (prevAge == 0 || result.cognitiveAge < prevAge) {
      await _prefs.setInt(_keyBestCognitiveAge, result.cognitiveAge);
    }

    final scores = lastScores;
    scores.insert(0, result);
    final trimmed = scores.take(5).map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_keyLastScores, trimmed);

    // Update SnapIQ history (last 20)
    final iqHistory = _prefs.getStringList(_keySnapIQHistory) ?? [];
    iqHistory.insert(0, result.snapIQ.toString());
    await _prefs.setStringList(
        _keySnapIQHistory, iqHistory.take(20).toList());

    // Game history (last 20 entries)
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final entry = jsonEncode({
      'snapiq': result.snapIQ,
      'cogAge': result.cognitiveAge,
      'date': dateStr,
      'finalScore': result.finalScore,
    });
    final hist = _prefs.getStringList(_keyGameHistory) ?? [];
    hist.insert(0, entry);
    await _prefs.setStringList(_keyGameHistory, hist.take(20).toList());
  }

  Future<void> saveXP(int amount) async {
    await _prefs.setInt(_keyXp, xp + amount);
  }

  Future<void> saveLevel(int lvl) async {
    await _prefs.setInt(_keyLevel, lvl);
  }

  Future<void> saveTheme(String theme) async {
    await _prefs.setString(_keySelectedTheme, theme);
    final themes = unlockedThemes;
    if (!themes.contains(theme)) {
      themes.add(theme);
      await _prefs.setStringList(_keyUnlockedThemes, themes);
    }
  }

  Future<void> saveAchievement(String id) async {
    final list = unlockedAchievements;
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList(_keyUnlockedAchievements, list);
    }
  }

  int arcadeBestScore(String gameId) =>
      _prefs.getInt('arcade_best_$gameId') ?? 0;

  Future<void> saveArcadeBestScore(String gameId, int score) async {
    if (score > arcadeBestScore(gameId)) {
      await _prefs.setInt('arcade_best_$gameId', score);
    }
  }

  // Laser Gate: best time in ms (lower = better, 0 = never completed)
  int get bestLaserGateMs => _prefs.getInt('laser_gate_best_ms') ?? 0;

  Future<void> saveBestLaserGateMs(int ms) async {
    final prev = bestLaserGateMs;
    if (prev == 0 || ms < prev) {
      await _prefs.setInt('laser_gate_best_ms', ms);
    }
  }

  Future<void> saveSoundEnabled(bool value) async {
    await _prefs.setBool(_keySoundEnabled, value);
  }

  Future<void> saveVibrationEnabled(bool value) async {
    await _prefs.setBool(_keyVibrationEnabled, value);
  }

  Future<void> saveReduceAnimations(bool value) async {
    await _prefs.setBool(_keyReduceAnimations, value);
  }

  Future<void> saveDailyChallengeDate(String date) async {
    await _prefs.setString(_keyDailyChallengLastDate, date);
  }

  Future<void> saveDailyChallengeBestScore(int score) async {
    if (score > dailyChallengeBestScore) {
      await _prefs.setInt(_keyDailyChallengeBestScore, score);
    }
  }

  Future<void> saveSpinWheelDate(String date) async {
    await _prefs.setString(_keySpinWheelLastDate, date);
  }

  Future<void> saveBestReactionMs(int ms) async {
    if (bestReactionMs == 0 || ms < bestReactionMs) {
      await _prefs.setInt(_keyBestReactionMs, ms);
    }
  }

  Future<void> addTotalTimeSecs(int secs) async {
    await _prefs.setInt(_keyTotalTestTimeSecs, totalTestTimeSecs + secs);
  }

  Future<void> unlockTheme(String theme) async {
    final themes = unlockedThemes;
    if (!themes.contains(theme)) {
      themes.add(theme);
      await _prefs.setStringList(_keyUnlockedThemes, themes);
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
