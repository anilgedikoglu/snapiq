class TestResult {
  final int reactionScore;
  final int stroopScore;
  final int memoryScore;
  final int sequenceScore;
  final int impulseScore;
  final int patternScore;
  final int circleScore;
  final int laserScore;
  final int timingScore;
  final int pulseScore;
  final int balanceScore;
  final int dartScore;
  final int skyScore;
  final int targetLockScore;
  final int swipeDodgeScore;
  final int colorPanicScore;
  final int dontTapRedScore;
  final int tapTargetScore;
  final int shapeStrikeScore;
  final int memoryFlashScore;
  final int mirrorBrainScore;
  final int sequenceRushScore;
  final int reactionWallScore;
  final int focusHunterScore;
  final int impulseControlScore;
  final int tapRainScore;
  final int speedMathScore;
  final int numberHunterScore;
  final int patternMasterScore;

  const TestResult({
    required this.reactionScore,
    required this.stroopScore,
    required this.memoryScore,
    required this.sequenceScore,
    required this.impulseScore,
    required this.patternScore,
    this.circleScore        = 0,
    this.laserScore         = 0,
    this.timingScore        = 0,
    this.pulseScore         = 0,
    this.balanceScore       = 0,
    this.dartScore          = 0,
    this.skyScore           = 0,
    this.targetLockScore    = 0,
    this.swipeDodgeScore    = 0,
    this.colorPanicScore    = 0,
    this.dontTapRedScore    = 0,
    this.tapTargetScore     = 0,
    this.shapeStrikeScore   = 0,
    this.memoryFlashScore   = 0,
    this.mirrorBrainScore   = 0,
    this.sequenceRushScore  = 0,
    this.reactionWallScore  = 0,
    this.focusHunterScore   = 0,
    this.impulseControlScore = 0,
    this.tapRainScore       = 0,
    this.speedMathScore     = 0,
    this.numberHunterScore  = 0,
    this.patternMasterScore = 0,
  });

  // 29 tests — weights sum to 1.00
  double get finalScore {
    return reactionScore      * 0.07 +
           stroopScore        * 0.04 +
           memoryScore        * 0.05 +
           sequenceScore      * 0.04 +
           impulseScore       * 0.04 +
           patternScore       * 0.04 +
           circleScore        * 0.04 +
           laserScore         * 0.04 +
           timingScore        * 0.03 +
           pulseScore         * 0.03 +
           balanceScore       * 0.03 +
           dartScore          * 0.03 +
           skyScore           * 0.03 +
           targetLockScore    * 0.03 +
           swipeDodgeScore    * 0.02 +
           colorPanicScore    * 0.03 +
           dontTapRedScore    * 0.03 +
           tapTargetScore     * 0.03 +
           shapeStrikeScore   * 0.03 +
           memoryFlashScore   * 0.04 +
           mirrorBrainScore   * 0.03 +
           sequenceRushScore  * 0.04 +
           reactionWallScore  * 0.03 +
           focusHunterScore   * 0.03 +
           impulseControlScore * 0.03 +
           tapRainScore       * 0.02 +
           speedMathScore     * 0.03 +
           numberHunterScore  * 0.03 +
           patternMasterScore * 0.04;
  }

  int get reflexIQ {
    return (58 + finalScore * 0.75).round().clamp(58, 133);
  }

  int get cognitiveAge {
    double base = 45 - ((finalScore - 50) * 0.35);
    if (reactionScore >= 90) base -= 3;
    if (reactionScore < 30)  base += 3;
    if (memoryScore < 30)    base += 4;
    if (memoryScore >= 90)   base -= 2;
    return base.round().clamp(18, 65);
  }

  String get label {
    final s = finalScore;
    if (s >= 88) return 'Efsane Odak';
    if (s >= 76) return 'Çok Hızlı Zihin';
    if (s >= 63) return 'Güçlü Refleks';
    if (s >= 50) return 'Ortalama Üstü';
    if (s >= 35) return 'Geliştirilebilir';
    return 'Bugünlük Kafa Yorgun';
  }

  Map<String, dynamic> toJson() => {
        'reactionScore':  reactionScore,
        'stroopScore':    stroopScore,
        'memoryScore':    memoryScore,
        'sequenceScore':  sequenceScore,
        'impulseScore':   impulseScore,
        'patternScore':   patternScore,
        'circleScore':    circleScore,
        'laserScore':     laserScore,
        'timingScore':    timingScore,
        'pulseScore':     pulseScore,
        'balanceScore':   balanceScore,
        'dartScore':      dartScore,
        'skyScore':       skyScore,
        'targetLockScore':  targetLockScore,
        'swipeDodgeScore':  swipeDodgeScore,
        'colorPanicScore':  colorPanicScore,
        'dontTapRedScore':  dontTapRedScore,
        'tapTargetScore':   tapTargetScore,
        'shapeStrikeScore':   shapeStrikeScore,
        'memoryFlashScore':   memoryFlashScore,
        'mirrorBrainScore':   mirrorBrainScore,
        'sequenceRushScore':  sequenceRushScore,
        'reactionWallScore':  reactionWallScore,
        'focusHunterScore':   focusHunterScore,
        'impulseControlScore': impulseControlScore,
        'tapRainScore':       tapRainScore,
        'speedMathScore':     speedMathScore,
        'numberHunterScore':  numberHunterScore,
        'patternMasterScore': patternMasterScore,
        'finalScore':         finalScore,
        'reflexIQ':       reflexIQ,
        'cognitiveAge':   cognitiveAge,
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        reactionScore:  json['reactionScore']  as int,
        stroopScore:    json['stroopScore']     as int,
        memoryScore:    json['memoryScore']     as int,
        sequenceScore:  json['sequenceScore']   as int,
        impulseScore:   json['impulseScore']    as int,
        patternScore:   json['patternScore']    as int,
        circleScore:    (json['circleScore']    as int?) ?? 0,
        laserScore:     (json['laserScore']     as int?) ?? 0,
        timingScore:    (json['timingScore']    as int?) ?? 0,
        pulseScore:     (json['pulseScore']     as int?) ?? 0,
        balanceScore:   (json['balanceScore']   as int?) ?? 0,
        dartScore:      (json['dartScore']      as int?) ?? 0,
        skyScore:          (json['skyScore']          as int?) ?? 0,
        targetLockScore:   (json['targetLockScore']   as int?) ?? 0,
        swipeDodgeScore:   (json['swipeDodgeScore']   as int?) ?? 0,
        colorPanicScore:   (json['colorPanicScore']   as int?) ?? 0,
        dontTapRedScore:   (json['dontTapRedScore']   as int?) ?? 0,
        tapTargetScore:    (json['tapTargetScore']    as int?) ?? 0,
        shapeStrikeScore:    (json['shapeStrikeScore']    as int?) ?? 0,
        memoryFlashScore:    (json['memoryFlashScore']    as int?) ?? 0,
        mirrorBrainScore:    (json['mirrorBrainScore']    as int?) ?? 0,
        sequenceRushScore:   (json['sequenceRushScore']   as int?) ?? 0,
        reactionWallScore:   (json['reactionWallScore']   as int?) ?? 0,
        focusHunterScore:    (json['focusHunterScore']    as int?) ?? 0,
        impulseControlScore: (json['impulseControlScore'] as int?) ?? 0,
        tapRainScore:        (json['tapRainScore']        as int?) ?? 0,
        speedMathScore:      (json['speedMathScore']      as int?) ?? 0,
        numberHunterScore:   (json['numberHunterScore']   as int?) ?? 0,
        patternMasterScore:  (json['patternMasterScore']  as int?) ?? 0,
      );
}
