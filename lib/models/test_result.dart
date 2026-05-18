class TestResult {
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;

  const TestResult({
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
    required this.patternScore,
  });

  double get finalScore {
    return reactionScore * 0.25 +
        stroopScore * 0.20 +
        memoryScore * 0.20 +
        sequenceScore * 0.15 +
        impulseScore * 0.10 +
        patternScore * 0.10;
  }

  int get reflexIQ {
    return (60 + finalScore * 0.9).round().clamp(60, 150);
  }

  int get cognitiveAge {
    double base = 45 - ((finalScore - 50) * 0.35);
    if (reactionScore >= 90) base -= 3;
    if (reactionScore < 30) base += 3;
    if (memoryScore < 30) base += 4;
    if (memoryScore >= 90) base -= 2;
    return base.round().clamp(18, 65);
  }

  String get label {
    final s = finalScore;
    if (s >= 90) return 'Efsane Odak';
    if (s >= 80) return 'Çok Hızlı Zihin';
    if (s >= 70) return 'Güçlü Refleks';
    if (s >= 60) return 'Ortalama Üstü';
    if (s >= 45) return 'Geliştirilebilir';
    return 'Bugünlük Kafa Yorgun';
  }

  Map<String, dynamic> toJson() => {
        'reactionScore': reactionScore,
        'stroopScore': stroopScore,
        'memoryScore': memoryScore,
        'sequenceScore': sequenceScore,
        'impulseScore': impulseScore,
        'patternScore': patternScore,
        'finalScore': finalScore,
        'reflexIQ': reflexIQ,
        'cognitiveAge': cognitiveAge,
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        reactionScore: json['reactionScore'] as int,
        stroopScore: json['stroopScore'] as int,
        memoryScore: json['memoryScore'] as int,
        sequenceScore: json['sequenceScore'] as int,
        impulseScore: json['impulseScore'] as int,
        patternScore: json['patternScore'] as int,
      );
}
