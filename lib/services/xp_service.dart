class XpService {
  static const List<int> _thresholds = [
    0,    // level 1
    200,  // level 2
    500,  // level 3
    900,  // level 4
    1400, // level 5
    2100, // level 6
    3000, // level 7
    4200, // level 8
    5800, // level 9
    8000, // level 10
  ];

  static const List<String> _titles = [
    'Başlangıç',
    'Çaylak',
    'Odaklı',
    'Hız Avcısı',
    'Beyin Ninja',
    'Sinaps Ustası',
    'Zihin Efendisi',
    'Efsane',
    'Tanrısal',
    'Sonsuz',
  ];

  static int levelForXp(int xp) {
    int level = 1;
    for (int i = _thresholds.length - 1; i >= 0; i--) {
      if (xp >= _thresholds[i]) {
        level = i + 1;
        break;
      }
    }
    return level.clamp(1, 10);
  }

  static String titleForLevel(int level) {
    final idx = (level - 1).clamp(0, _titles.length - 1);
    return _titles[idx];
  }

  static int xpForNextLevel(int xp) {
    final currentLevel = levelForXp(xp);
    if (currentLevel >= 10) return 0;
    return _thresholds[currentLevel] - xp;
  }

  static int xpAtLevelStart(int level) {
    final idx = (level - 1).clamp(0, _thresholds.length - 1);
    return _thresholds[idx];
  }

  static int xpForLevelUp(int level) {
    if (level >= 10) return 1;
    return _thresholds[level] - _thresholds[level - 1];
  }
}
