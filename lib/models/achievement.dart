class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
  });

  static const List<Achievement> all = [
    Achievement(
        id: 'first_game',
        title: 'İlk Adım',
        description: 'İlk testi tamamla',
        icon: '🎯',
        xpReward: 100),
    Achievement(
        id: 'games_10',
        title: '10 Oyun',
        description: '10 test tamamla',
        icon: '🔟',
        xpReward: 150),
    Achievement(
        id: 'games_50',
        title: '50 Oyun',
        description: '50 test tamamla',
        icon: '⚡',
        xpReward: 300),
    Achievement(
        id: 'games_100',
        title: 'Yüzlük',
        description: '100 test tamamla',
        icon: '💯',
        xpReward: 500),
    Achievement(
        id: 'reaction_200',
        title: 'Şimşek',
        description: '200ms altı reaksiyon',
        icon: '⚡',
        xpReward: 200),
    Achievement(
        id: 'stroop_perfect',
        title: 'Renk Ustası',
        description: 'Stroop testini tam doğru bitir',
        icon: '🌈',
        xpReward: 200),
    Achievement(
        id: 'memory_perfect',
        title: 'Hafıza Dehası',
        description: 'Hafıza testini tam doğru bitir',
        icon: '🧠',
        xpReward: 200),
    Achievement(
        id: 'beat_friend',
        title: 'Arkadaş Katili',
        description: 'VS modda arkadaşını yen',
        icon: '🏆',
        xpReward: 150),
    Achievement(
        id: 'daily_done',
        title: 'Günlük Görev',
        description: 'Günlük challenge tamamla',
        icon: '📅',
        xpReward: 100),
    Achievement(
        id: 'endless_60',
        title: 'Sonsuz Güç',
        description: 'Endless modda 60 saniye dayan',
        icon: '♾️',
        xpReward: 300),
    Achievement(
        id: 'snapiq_100',
        title: 'Seçkinler Kulübü',
        description: 'SnapIQ 100 üzeri al',
        icon: '💎',
        xpReward: 250),
    Achievement(
        id: 'snapiq_130',
        title: 'Zihin Efendisi',
        description: 'SnapIQ 130 üzeri al',
        icon: '🧬',
        xpReward: 500),
    Achievement(
        id: 'tap_master',
        title: 'Tap Master',
        description: 'Tap Target\'da 20 hedef vur',
        icon: '👆',
        xpReward: 150),
    Achievement(
        id: 'focus_beast',
        title: 'Focus Beast',
        description: 'Focus Hunter\'da 10 tur kazan',
        icon: '🎯',
        xpReward: 150),
    Achievement(
        id: 'math_demon',
        title: 'Math Demon',
        description: 'Speed Math\'ta 10/10 al',
        icon: '🔢',
        xpReward: 200),
    Achievement(
        id: 'reflex_monster',
        title: 'Reflex Monster',
        description: 'Color Panic\'te 20 puan al',
        icon: '💥',
        xpReward: 200),
    Achievement(
        id: 'pattern_king',
        title: 'Pattern King',
        description: 'Pattern Master\'da tam puan',
        icon: '👑',
        xpReward: 300),
  ];
}
