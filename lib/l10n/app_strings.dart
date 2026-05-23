import '../services/locale_service.dart';

/// All UI strings for the app, available in Turkish (default) and English.
/// Usage:  S.start   →  'Başla!' / 'Start!'
class S {
  static bool get _e => LocaleService.instance.isEnglish;

  // ═══════════════════════════════════════════════════════════
  // COMMON
  // ═══════════════════════════════════════════════════════════
  static String get start        => _e ? 'Start!'      : 'Başla!';
  static String get startBtn     => _e ? 'START'       : 'BAŞLA';
  static String get back         => _e ? 'Back'        : 'Geri';
  static String get menu         => _e ? 'Main Menu'   : 'Ana Menü';
  static String get tryAgain     => _e ? 'Try Again'   : 'Tekrar Dene';
  static String get exit         => _e ? 'Exit'        : 'Çıkış';
  static String get again        => _e ? 'Again'       : 'Tekrar';
  static String get confirm      => _e ? 'Confirm'     : 'Onayla';
  static String get total        => _e ? 'Total'       : 'Toplam';
  static String get level        => _e ? 'Level'       : 'Seviye';
  static String get score        => _e ? 'Score'       : 'Puan';
  static String get ready        => _e ? 'Ready...'    : 'Hazırlan...';
  static String get tapScreen    => _e ? 'Tap screen'  : 'Ekrana dokun';
  static String get best         => _e ? 'Best'        : 'En İyi';
  static String get target       => _e ? 'TARGET'      : 'HEDEF';
  static String get done         => _e ? 'Done!'       : 'Tamamlandı!';
  static String get early        => _e ? 'Early'       : 'Erken';
  static String get late         => _e ? 'Late'        : 'Geç';
  static String get hit          => _e ? 'Hit!'        : 'Çarptı!';
  static String get excellent    => _e ? 'Excellent!'  : 'Mükemmel!';
  static String get great        => _e ? 'Great!'      : 'Harika!';
  static String get good         => _e ? 'Good!'       : 'İyi!';
  static String get okay         => _e ? 'Okay'        : 'Tamam';
  static String get missed       => _e ? 'Missed!'     : 'Kaçırdın!';
  static String get slightlyOff  => _e ? 'Close!'      : 'Az farkla!';
  static String get weak         => _e ? 'Weak!'       : 'Zayıf!';
  static String levelLabel(int n)  => _e ? 'Level $n'    : 'Seviye $n';
  static String bestScore(int s)   => _e ? 'Best: $s'    : 'En İyi: $s';

  // ═══════════════════════════════════════════════════════════
  // GAME DATA – COLORS & SHAPES
  // ═══════════════════════════════════════════════════════════

  /// 4 option labels for Stroop test (capitalized, same order as color indices)
  /// Index: 0=Red 1=Blue 2=Green 3=Yellow
  static List<String> get stroopOptions => _e
      ? ['Red', 'Blue', 'Green', 'Yellow']
      : ['Kırmızı', 'Mavi', 'Yeşil', 'Sarı'];

  /// 6 uppercase word labels for Color Panic (index matches Colors list in screen)
  /// Index: 0=Red 1=Blue 2=Green 3=Yellow 4=Purple 5=Orange
  static List<String> get colorPanicWords => _e
      ? ['RED', 'BLUE', 'GREEN', 'YELLOW', 'PURPLE', 'ORANGE']
      : ['KIRMIZI', 'MAVİ', 'YEŞİL', 'SARI', 'MOR', 'TURUNCU'];

  /// Display name for impulse-test internal shape keys (always Turkish internally)
  static String shapeDisplay(String key) {
    if (!_e) return key.toUpperCase();
    switch (key) {
      case 'daire':  return 'CIRCLE';
      case 'kare':   return 'SQUARE';
      case 'üçgen':  return 'TRIANGLE';
      case 'yıldız': return 'STAR';
      default:       return key.toUpperCase();
    }
  }

  /// Shape Strike shape names map (index → uppercase display label)
  static Map<int, String> get shapeStrikeNames => _e
      ? {0: 'CIRCLE', 1: 'TRIANGLE', 2: 'SQUARE', 3: 'STAR'}
      : {0: 'DAİRE',  1: 'ÜÇGEN',    2: 'KARE',   3: 'YILDIZ'};

  // ═══════════════════════════════════════════════════════════
  // LANGUAGE SELECT SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get langSelectTitle => _e ? 'Select Language' : 'Dil Seç';

  // ═══════════════════════════════════════════════════════════
  // HOME SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get homeFullTest     => _e ? '29 tests • ~20 min'          : '29 test • ~20 dakika';
  static String get homeQuickPlay    => _e ? 'Quick Play'                  : 'Hızlı Oyun';
  static String get homeDailyDone    => _e ? "Today's Challenge Completed!": 'Bugünkü Görev Tamamlandı!';
  static String get homeDailyStart   => _e ? "Start Today's Challenge"     : 'Bugünün Göreviyle Başla';
  static String get homeDailyTomorrow=> _e ? 'Come back tomorrow'          : 'Yarın tekrar gel';
  static String get homeDailyChallenge=>_e ? 'Daily Challenge'             : 'Günlük meydan okuma';
  static String get homeMore         => _e ? 'More'                        : 'Daha Fazla';

  // IQ descriptors
  static String get iqGenius    => _e ? 'Genius'         : 'Dahi';
  static String get iqSuperior  => _e ? 'Superior IQ'    : 'Üstün Zeka';
  static String get iqVeryHigh  => _e ? 'Very Smart'     : 'Çok Zeki';
  static String get iqAboveAvg  => _e ? 'Above Average'  : 'Ortalama Üstü';
  static String get iqAverage   => _e ? 'Average'        : 'Ortalama';
  static String get iqBelowAvg  => _e ? 'Below Average'  : 'Ortalama Altı';
  static String get iqBorderline=> _e ? 'Borderline'     : 'Sınırda Zeka';
  static String get iqLow       => _e ? 'Low IQ'         : 'Düşük Zeka';
  static String get iqPending   => _e ? 'Score Pending'  : 'Skor Bekleniyor';
  static String get iqFirstTest => _e ? 'Complete first test!' : 'İlk testi tamamla!';

  // Arcade game subtitles (home card descriptions)
  static String get subCircle       => _e ? 'Tap when target arrives'  : 'Top hedefe gelince dokun';
  static String get subSwipe        => _e ? 'Pass through the gap'     : 'Boşluktan geç';
  static String get subBalance      => _e ? 'Align the block'          : 'Bloğu hizala';
  static String get subPulse        => _e ? 'Stop at the right time'   : 'Tam zamanında dur';
  static String get subReaction     => _e ? 'Catch the target'         : 'Hedefi yakala';
  static String get subDart         => _e ? "Aim at the bullseye"      : "Bullseye'a nişan al";
  static String get subSky          => _e ? 'Shoot the flying target'  : 'Uçan hedefe ateş et';
  static String get subTargetLock   => _e ? 'Lock the radar'           : 'Radarı kilitle';
  static String get subColorPanic   => _e ? 'Quick decision'           : 'Anlık karar ver';
  static String get subDodge        => _e ? 'Dodge obstacles'          : 'Engellerden kaç';
  static String get subColorMatch   => _e ? 'Match the color'          : 'Renk eşleştir';
  static String get subDontTapRed   => _e ? "Don't tap red!"           : 'Kırmızıya dokunma!';
  static String get subTapTarget    => _e ? 'Hit the targets'          : 'Hedefleri vur';
  static String get subShapeStrike  => _e ? 'Tap the right shape'      : 'Doğru şekle dokun';
  static String get subMemoryFlash  => _e ? 'Memorize the pattern'     : 'Deseni ezberle';
  static String get subNumberHunter => _e ? 'Find the number fast'     : 'Sayıyı hızlı bul';
  static String get subPatternMaster=> _e ? 'Complete the pattern'     : 'Örüntüyü tamamla';
  static String get subMirrorBrain  => _e ? 'Choose the opposite'      : 'Tersini seç';
  static String get subSpeedMath    => _e ? 'Fast math'                : 'Hızlı matematik';

  // Duration chips
  static String get chip10rounds  => _e ? '10 rounds' : '10 tur';
  static String get chip3lives    => _e ? '3 lives'   : '3 can';
  static String get chip15rounds  => _e ? '15 rounds' : '15 tur';
  static String get chip5shots    => _e ? '5 shots'   : '5 atış';
  static String get chip5targets  => _e ? '5 targets' : '5 hedef';
  static String get chip10targets => _e ? '10 targets': '10 hedef';
  static String get chip30s       => _e ? '30 sec'    : '30 sn';
  static String get chip10q       => _e ? '10 questions': '10 soru';

  // More-grid labels
  static String get gridEndless   => _e ? 'Endless\nReflex'    : 'Sonsuz\nRefleks';
  static String get gridUltraHard => _e ? 'Ultra\nHard'        : 'Manyak\nMod';
  static String get gridVsFriend  => _e ? 'VS\nFriend'         : 'VS\nArkadaş';
  static String get gridSpinWheel => _e ? 'Spin\nWheel'        : 'Çark\nÇevir';
  static String get gridProfile   => _e ? 'Profile'            : 'Profil';
  static String get gridAchiev    => _e ? 'Achievements'       : 'Başarımlar';
  static String get gridStats     => _e ? 'Statistics'         : 'İstatistik';
  static String get gridBestScores=> _e ? 'Best\nScores'       : 'En İyi\nSkorlar';
  static String get gridSettings  => _e ? 'Settings'           : 'Ayarlar';
  static String get gridHowToPlay => _e ? 'How to\nPlay'       : 'Nasıl\nOynanır';

  // ═══════════════════════════════════════════════════════════
  // PREP SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get prepTitle    => _e ? '29 quick tests await you.' : '29 kısa test seni bekliyor.';
  static String get prepSubtitle => _e ? "Start when you're ready."  : 'Hazır olduğunda başla.';

  static List<String> get testNames => _e ? [
    'Reaction Speed', 'Stroop Color', 'Memory Boxes', 'Number Sort',
    'Impulse Control', 'Pattern IQ', 'Circle Reflex', 'Laser Gate',
    'Timing Stack', 'Pulse Stop', 'Balance Bar', 'Dart Focus',
    'Sky Shot', 'Target Lock', 'Swipe Dodge', 'Color Panic',
    "Don't Tap Red", 'Tap Target', 'Shape Strike', 'Memory Flash',
    'Mirror Brain', 'Sequence Rush', 'Reaction Wall', 'Focus Hunter',
    'Impulse Ctrl', 'Tap Rain', 'Speed Math', 'Number Hunter',
    'Pattern Master',
  ] : [
    'Reaksiyon Hızı', 'Stroop Renk', 'Hafıza Kutuları', 'Sayı Sıralama',
    'İmpuls Kontrolü', 'Pattern IQ', 'Çember Refleks', 'Laser Gate',
    'Timing Stack', 'Pulse Stop', 'Balance Bar', 'Dart Focus',
    'Sky Shot', 'Target Lock', 'Swipe Dodge', 'Color Panic',
    "Don't Tap Red", 'Tap Target', 'Shape Strike', 'Memory Flash',
    'Mirror Brain', 'Sequence Rush', 'Reaction Wall', 'Focus Hunter',
    'Impulse Ctrl', 'Tap Rain', 'Speed Math', 'Number Hunter',
    'Pattern Master',
  ];

  // ═══════════════════════════════════════════════════════════
  // RESULT SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get resultFun0 => _e ? 'Your synapses are on fire! 🔥'       : 'Sinapsların alev almış! 🔥';
  static String get resultFun1 => _e ? "You're striking fear into rivals! 💀" : 'Rakiplerine korku salıyorsun! 💀';
  static String get resultFun2 => _e ? 'Your brain had espresso today. ☕'    : 'Bugün beynin espresso içmiş. ☕';
  static String get resultFun3 => _e ? "Not bad, but there's more! 💪"        : 'Fena değil, ama daha var! 💪';
  static String get resultFun4 => _e ? "Looks like you're a bit sleepy... 😴"  : 'Biraz uykulusun galiba... 😴';
  static String get resultFun5 => _e ? 'Brain is on vacation today. 🏖️'       : 'Bugün beyin tatilde gibi. 🏖️';

  static String get resultPerfect  => _e ? 'Excellent!'     : 'Mükemmel!';
  static String get resultGood     => _e ? 'Good'           : 'İyi';
  static String get resultOk       => _e ? 'Can improve'    : 'Geliştirebilirsin';
  static String get resultWeak     => _e ? 'Needs work'     : 'Çalışman lazım';

  static String cognitiveAge(int age) => _e ? 'Your Cognitive Age: $age' : 'Bilişsel Yaşın: $age';
  static String snapIqScore(int iq)   => _e ? 'Your SnapIQ Score: $iq'   : 'SnapIQ Skorun: $iq';
  static String get resultDisclaimer  => _e
      ? '* This result is for entertainment only.'
      : '* Bu sonuç eğlence amaçlıdır, bilimsel tanı koymaz.';
  static String xpGained(int xp)     => _e ? '+$xp XP earned!'  : '+$xp XP kazandın!';
  static String get resultShare      => _e ? 'Share with Friend' : 'Arkadaşına Ver';
  static String get resultStartTest  => _e ? 'Start Test'        : 'Teste Başla';
  static String get newAchievements  => _e ? 'New Achievements!' : 'Yeni Başarımlar!';
  static String get achievEarned     => _e ? '🎉 Achievement Earned!' : '🎉 Başarım Kazandın!';
  static String get awesome          => _e ? 'Awesome!'          : 'Harika!';
  static String get giveToFriend     => _e ? 'Hand phone to your friend.' : 'Telefonu arkadaşına ver.';
  static String get canBeatYou       => _e ? 'Can they beat you?'          : 'Bakalım seni geçebilecek mi?';
  static String yourSnapIQ(int iq)   => _e ? 'Your SnapIQ: $iq'   : 'Senin SnapIQ: $iq';

  // Score card titles (result screen)
  static String get cardReaction => _e ? 'Reaction'  : 'Reaksiyon';
  static String get cardStroop   => _e ? 'Attention' : 'Dikkat';
  static String get cardMemory   => _e ? 'Memory'    : 'Hafıza';
  static String get cardSequence => _e ? 'Sorting'   : 'Sıralama';
  static String get cardImpulse  => _e ? 'Impulse'   : 'İmpuls';
  static String get cardPattern  => _e ? 'Pattern'   : 'Örüntü';

  // TestResult label getter values
  static String get labelLegend   => _e ? 'Legendary Focus'  : 'Efsane Odak';
  static String get labelVeryFast => _e ? 'Very Fast Mind'   : 'Çok Hızlı Zihin';
  static String get labelStrong   => _e ? 'Strong Reflexes'  : 'Güçlü Refleks';
  static String get labelAboveAvg => _e ? 'Above Average'    : 'Ortalama Üstü';
  static String get labelImprove  => _e ? 'Improvable'       : 'Geliştirilebilir';
  static String get labelTired    => _e ? 'Brain Tired Today': 'Bugünlük Kafa Yorgun';

  // ═══════════════════════════════════════════════════════════
  // REACTION TEST  (Test 1)
  // ═══════════════════════════════════════════════════════════
  static String get reactionGetReady  => _e ? 'Get ready...'           : 'Hazırlan...';
  static String get reactionTap       => _e ? 'TAP!'                   : 'DOKUN!';
  static String get reactionWhenGreen => _e ? 'Tap when it turns green!': 'Yeşil olunca dokun!';
  static String get reactionEarlyNote => _e ? '(Early tap!)'           : '(Erken dokunma!)';
  static String reactionScore(int s)  => _e ? 'Score: $s / 100'        : 'Skor: $s / 100';
  static String get reactionTooEarly  => _e ? 'Tapped Too Early!'       : 'Erken Dokundun!';
  static String get reactionZero      => _e ? 'This test scores 0.'     : 'Bu test 0 puan.';
  static String get reactionTestLabel => _e ? 'Reaction Speed'          : 'Reaksiyon Hızı';

  // ═══════════════════════════════════════════════════════════
  // STROOP TEST  (Test 2)
  // ═══════════════════════════════════════════════════════════
  static String get stroopInstruction => _e ? 'Select the COLOR of the text' : 'Yazının RENGİNİ seç';
  static String get stroopTestLabel   => _e ? 'Stroop Color'                 : 'Stroop Renk';

  // ═══════════════════════════════════════════════════════════
  // MEMORY TEST  (Test 3)
  // ═══════════════════════════════════════════════════════════
  static String get memWhichBoxes   => _e ? 'Which boxes lit up?'   : 'Hangi kutular yandı?';
  static String get memSelectBoxes  => _e ? 'Select the lit boxes'  : 'Yanan kutuları seç';
  static String get memChecking     => _e ? 'Checking...'           : 'Kontrol ediliyor...';
  static String memBoxCount(int n)  => _e ? '$n boxes'              : '$n kutu';
  static String get memTestLabel    => _e ? 'Memory Boxes'          : 'Hafıza Kutuları';

  // ═══════════════════════════════════════════════════════════
  // SEQUENCE TEST  (Test 4)
  // ═══════════════════════════════════════════════════════════
  static String get seqInstruction  => _e ? 'Tap smallest to largest' : 'Küçükten büyüğe dokun';
  static String seqNext(int n)      => _e ? 'Next: $n'                : 'Sıradaki: $n';
  static String get seqTestLabel    => _e ? 'Number Sort'             : 'Sayı Sıralama';

  // ═══════════════════════════════════════════════════════════
  // IMPULSE TEST  (Test 5)
  // ═══════════════════════════════════════════════════════════
  static String get impulseInstruction => _e ? 'Tap only when CIRCLE appears!' : 'Sadece DAİRE çıkınca dokun!';
  static String impulseScore(int s)    => _e ? 'Score: $s'                      : 'Puan: $s';
  static String get impulseTestLabel   => _e ? 'Impulse Control'                : 'İmpuls Kontrolü';

  // ═══════════════════════════════════════════════════════════
  // PATTERN TEST  (Test 6)
  // ═══════════════════════════════════════════════════════════
  static String get patternInstruction => _e ? 'Complete the pattern.' : 'Örüntüyü tamamla.';
  static String get patternHint1 => _e ? 'Pattern repeats'      : 'Desen tekrar ediyor';
  static String get patternHint2 => _e ? '+2 increasing'        : '+2 artıyor';
  static String get patternHint3 => _e ? 'Alternating colors'   : 'Renk dönüşümlü';
  static String get patternHint4 => _e ? 'Fibonacci sequence'   : 'Fibonacci dizisi';
  static String get patternHint5 => _e ? 'Alternating shapes'   : 'Şekil dönüşümlü';

  // ═══════════════════════════════════════════════════════════
  // GAME TEST SCREEN INSTRUCTIONS  (Tests 7-29)
  // ═══════════════════════════════════════════════════════════
  static String get circleInstr        => _e ? 'Circle Reflex — Tap when target arrives'      : 'Çember Refleks — Top hedef alana gelince dokun';
  static String get laserInstr         => _e ? 'Laser Gate — Go to the outermost!'             : 'Laser Gate — En dışa geç!';
  static String get timingInstr        => _e ? 'Timing Stack — Align the bar!'                 : 'Timing Stack — Barı hizala!';
  static String get pulseInstr         => _e ? 'Pulse Stop — Stop the ring in the yellow zone!': 'Pulse Stop — Halkayı sarı bölgede durdur!';
  static String get balanceInstr       => _e ? 'Balance Bar — Enter green zone and tap!'       : 'Balance Bar — Yeşil bölgeye gir ve dokun!';
  static String get dartInstr          => _e ? 'Dart Focus — Aim crosshair at center and shoot!': 'Dart Focus — Nişangahı merkeze getir ve at!';
  static String get skyInstr           => _e ? 'Sky Shot — Tap when directly above target!'    : 'Sky Shot — Hedef tam üstündeyken dokun!';
  static String get targetLockInstr    => _e ? 'Target Lock — Tap when scan passes!'           : 'Target Lock — Tarama geçerken dokun!';
  static String get swipeInstr         => _e ? 'Swipe Dodge — Pass through the gap!'           : 'Swipe Dodge — Boşluktan geç!';
  static String get colorPanicInstr    => _e ? 'Color Panic — Do the colors match?'            : 'Color Panic — Renk eşleşiyor mu?';
  static String get dontTapRedInstr    => _e ? "Don't Tap Red — Don't tap the red!"            : "Don't Tap Red — Kırmızıya dokunma!";
  static String get tapTargetInstr     => _e ? 'Tap Target — Tap green, avoid red!'            : 'Tap Target — Yeşile dokun, kırmızıdan kaç!';
  static String get shapeStrikeInstr   => _e ? 'Shape Strike — Tap the correct shape!'         : 'Shape Strike — Doğru şekle dokun!';
  static String get memFlashInstr      => _e ? 'Memory Flash — Which squares?'                 : 'Memory Flash — Hangi kareler?';
  static String get mirrorBrainInstr   => _e ? 'Mirror Brain — Tap the opposite!'              : 'Mirror Brain — Tersine dokun!';
  static String get mirrorBrainTap    => _e ? 'TAP OPPOSITE!'     : 'TERSİNE DOKUN!';
  static String get seqRushInstr       => _e ? 'Sequence Rush — Repeat the sequence!'          : 'Sequence Rush — Sırayı tekrarla!';
  static String get reactionWallInstr  => _e ? 'Reaction Wall — Stop in the right lane!'       : 'Reaction Wall — Doğru şeritte dur!';
  static String get focusHunterInstr   => _e ? 'Focus Hunter — Find the odd one out!'          : 'Focus Hunter — Farklı olanı bul!';
  static String get impulseCtrlInstr   => _e ? 'Impulse Control — GO or WAIT?'                 : 'Impulse Control — GO mu BEKLE mi?';
  static String get tapRainInstr       => _e ? 'Tap Rain — Tap the right emoji!'               : 'Tap Rain — Doğru emojiye dokun!';
  static String get speedMathInstr     => _e ? 'Speed Math — True or False?'                   : 'Speed Math — Doğru mu yanlış mı?';
  static String get numHunterInstr     => _e ? 'Number Hunter — Find the number!'              : 'Number Hunter — Sayıyı bul!';
  static String get patternMasterInstr => _e ? 'Pattern Master — What comes next?'             : 'Pattern Master — Sıradaki ne?';

  // ═══════════════════════════════════════════════════════════
  // GAME HUD STRINGS
  // ═══════════════════════════════════════════════════════════
  static String circleScore(int s)        => _e ? 'Score: $s'       : 'Skor: $s';
  static String pulseTotal(int s)         => _e ? 'Total: $s'       : 'Toplam: $s';
  static String balanceTotal(int s)       => _e ? 'Total: $s'       : 'Toplam: $s';
  static String dartShots(int n)          => _e ? '$n shots left'   : '$n atış kaldı';
  static String dartScore(int s)          => _e ? 'Score: $s'       : 'Puan: $s';
  static String skyShots(int n)           => _e ? '$n shots left'   : '$n atış kaldı';
  static String skyScore(int s)           => _e ? 'Score: $s'       : 'Puan: $s';
  static String targetLocked(int a, int b)=> _e ? '$a/$b locked'    : '$a/$b kilitli';
  static String targetScore(int s)        => _e ? 'Score: $s'       : 'Puan: $s';
  static String timeLeftSec(int s)        => '${s}s';
  static String colorPanicCorrect(int n)  => _e ? '$n correct'      : '$n doğru';
  static String dontTapRedCorrect(int n)  => _e ? '$n correct'      : '$n doğru';
  static String memFlashCorrect(int n)    => _e ? '$n correct'      : '$n doğru';

  static String get mirrorTapLabel  => _e ? 'TAP OPPOSITE!' : 'TERSİNE DOKUN!';
  static String seqRushLevel(int n) => _e ? 'Level $n'      : 'Seviye $n';
  static String get seqRushWatch    => _e ? 'WATCH!'        : 'İZLE!';
  static String get seqRushRepeat   => _e ? 'REPEAT!'       : 'TEKRARLA!';

  static String focusRound(int r, int t) => _e ? 'Round: $r/$t' : 'Tur: $r/$t';
  static String focusScore(int s)        => _e ? '$s pts'        : '$s puan';
  static String get focusHunterFindOdd   => _e ? 'Find the odd one out!' : 'Farklı olanı bul!';

  static String get impulseCtrlWait  => _e ? 'WAIT'    : 'BEKLE';   // GO same in both
  static String get impulseCtrlMissed=> _e ? 'Missed!' : 'Kaçırdın!';

  static String speedMathQ(int i, int t)  => _e ? 'Q: $i/$t'    : 'Soru: $i/$t';
  static String get speedMathTrue         => _e ? '✓ TRUE'       : '✓ DOĞRU';
  static String get speedMathFalse        => _e ? '✗ FALSE'      : '✗ YANLIŞ';

  static String numberFound(int n)  => _e ? '$n found'    : '$n bulundu';
  static String numberTarget(int n) => _e ? 'Find: $n'   : 'Bulunacak: $n';

  static String patternQ(int i, int t)      => _e ? 'Q: $i/$t'       : 'Soru: $i/$t';
  static String patternPoints(int s, int p) => _e ? '${s*p} pts'      : '${s*p} puan';

  static String shapeStrikeOnly(String shape) => _e ? 'Only $shape  tap!' : 'Sadece $shape  dokun!';

  static String get memFlashMemorize  => _e ? 'Memorize!' : 'Ezberle!';
  static String get memFlashWhich     => _e ? 'Which ones?' : 'Hangileri?';

  static String get colorMatch => _e ? '✓ MATCH'     : '✓ EŞLEŞME';
  static String get colorDiff  => _e ? '✗ DIFFERENT' : '✗ FARKLI';

  static String get dontTapRedLabel => _e ? "DON'T TAP RED!" : 'KIRMIZIYA DOKUNMA!';

  // Arcade HUD (level|score combined label)
  static String arcadeLevelScore(int lv, int sc)  => _e ? 'Level $lv | $sc pts' : 'Seviye $lv | $sc puan';
  static String seqLevelScore(int lv, int sc)      => _e ? 'Level $lv | $sc pts' : 'Seviye $lv | $sc puan';

  // Dot-progress label: "5 correct" etc.
  static String nCorrect(int n) => _e ? '$n correct' : '$n doğru';
  static String nFound(int n)   => _e ? '$n found'   : '$n bulundu';

  // ═══════════════════════════════════════════════════════════
  // ARCADE RESULT OVERLAY
  // ═══════════════════════════════════════════════════════════
  static String get overlayNewRecord  => _e ? '🏆 New Record!' : '🏆 Yeni Rekor!';
  static String overlayBest(int s)    => _e ? 'Best: $s'       : 'En İyi: $s';

  // ═══════════════════════════════════════════════════════════
  // BEST SCORES SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get bestScoresTitle   => _e ? 'Best Scores'      : 'En İyi Skorlar';
  static String get bestSnapIQ        => _e ? 'Best SnapIQ'      : 'En İyi SnapIQ';
  static String get bestCogAge        => _e ? 'Best Cognitive Age': 'En İyi Bilişsel Yaş';
  static String get totalTestsLabel   => _e ? 'Total Tests'      : 'Toplam Test';
  static String get last5Games        => _e ? 'Last 5 Games'     : 'Son 5 Oyun';
  static String get noGamesYet        => _e ? 'No games played yet.' : 'Henüz oyun oynanmadı.';
  static String get allPlayers        => _e ? 'All Players'      : 'Tüm Oyuncular';
  static String totalPlayers(String n)=> _e ? 'Total: $n players': 'Toplam: $n kişi';
  static String get noRankYet         => _e ? 'Complete your first test to see your rank!' : 'İlk testini tamamla ve sıralamanı gör!';
  static String get rankBest          => _e ? 'Best'             : 'En İyi';
  static String get rankWorst         => _e ? 'Worst'            : 'En Kötü';
  static String get rankYou           => _e ? 'You'              : 'Sen';
  static String topPctGold(int p)     => _e ? 'Top $p% 🏆'       : 'İlk %$p 🏆';
  static String topPctGreen(int p)    => _e ? 'Top $p% 🥇'       : 'İlk %$p 🥇';
  static String topPct(int p)         => _e ? 'Top $p%'          : 'İlk %$p';
  static String scoreRowLabel(int iq, int age) => _e ? 'SnapIQ: $iq  •  Age: $age' : 'SnapIQ: $iq  •  Yaş: $age';

  // ═══════════════════════════════════════════════════════════
  // DAILY CHALLENGE SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get dailyTitle       => _e ? "Today's Challenge"              : 'Günün Meydan Okuması';
  static String get dailyPlayed      => _e ? 'Already played today!'          : 'Bugün zaten oynadın!';
  static String get dailyTomorrow    => _e ? 'New challenge awaits tomorrow.' : 'Yeni meydan okuma yarın seni bekliyor.';
  static String get dailyCTA         => _e ? 'A new SnapIQ test every day...' : 'Her gün yeni bir SnapIQ testi...';
  static String get dailyStartBtn    => _e ? 'Start Challenge'                : 'Meydan Okumayı Başlat';
  static String dailyBest(int s)     => _e ? 'Best: $s'                       : 'En İyi: $s';

  // ═══════════════════════════════════════════════════════════
  // ENDLESS REFLEX SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get endlessTitle     => _e ? 'Endless Reflex'                 : 'Sonsuz Refleks';
  static String endlessRound(int r)  => _e ? 'Round $r'                       : 'Tur $r';
  static String get endlessCircle    => _e ? 'Tap when green circle appears!' : 'Yeşil daire çıkınca dokun!';
  static String get endlessShape     => _e ? 'Tap only the CIRCLE!'           : 'Sadece DAİRE ye dokun!';
  static String get endlessSeq       => _e ? 'Which number is next?'          : 'Sıradaki sayı hangisi?';

  // ═══════════════════════════════════════════════════════════
  // ULTRA HARD SCREEN
  // ═══════════════════════════════════════════════════════════
  static String get ultraTitle => _e ? 'ULTRA HARD' : 'MANYAK MOD';
  static String ultraSubtest(int n, String name) => _e ? 'ULTRA $n/6 – $name' : 'MANYAK $n/6 – $name';

  // ═══════════════════════════════════════════════════════════
  // VS FRIEND  /  BRAIN DUEL
  // ═══════════════════════════════════════════════════════════
  static String get vsTitle        => _e ? 'Beat Your Friend'   : 'Arkadaşını Geç';
  static String get vsSubtitle     => _e
      ? 'You play, your friend plays.\nWhose mind is stronger?'
      : 'Siz oynayın, arkadaşınız oynasın.\nKimin zihni daha güçlü?';
  static String get vsP1Play       => _e ? 'Player 1 Go'        : 'Oyuncu 1 Oynasın';
  static String get vsP2Play       => _e ? 'Player 2 Go'        : 'Oyuncu 2 Oynasın';
  static String get vsGive         => _e ? 'Hand phone to your friend.' : 'Telefonu arkadaşına ver.';
  static String get vsCanBeat      => _e ? 'Can they beat you?' : 'Bakalım seni geçebilecek mi?';
  static String get vsTie          => _e ? 'Tie! 🤝'            : 'Beraberlik! 🤝';
  static String fasterMind(int p)  => _e ? '$p% faster mind!'   : '%$p daha hızlı zihin!';

  static String playerN(int n)         => _e ? 'Player $n'               : '$n. Oyuncu';
  static String giveToPlayerN(int n)   => _e ? 'Hand to Player $n'       : 'Telefonu $n. oyuncuya ver';
  static String get duelReady          => _e ? 'READY'                   : 'HAZIR';
  static String get duelP1Wins         => _e ? 'Player 1 Wins! 🏆'       : '1. Oyuncu Kazandı! 🏆';
  static String get duelP2Wins         => _e ? 'Player 2 Wins! 🏆'       : '2. Oyuncu Kazandı! 🏆';
  static String get duelTie            => _e ? 'Tie! 🤝'                 : 'Berabere! 🤝';

  // ═══════════════════════════════════════════════════════════
  // SPIN WHEEL
  // ═══════════════════════════════════════════════════════════
  static String get spinTitle          => _e ? 'Spin Wheel'            : 'Çark Çevir';
  static String get spinTheme          => _e ? 'Theme'                 : 'Tema';
  static String get spinBadge          => _e ? 'Badge 🏅'              : 'Rozet 🏅';
  static String get spinBonus          => _e ? 'Bonus 🎁'              : 'Bonus 🎁';
  static String get spinAlreadyDone    => _e ? 'Already spun today!\nCome back tomorrow.' : 'Bugün zaten çevirdin!\nYarın tekrar gel.';
  static String get spinBtn            => _e ? 'SPIN!'                 : 'ÇEVİR!';
  static String spinWon(String r)      => _e ? 'Won: $r'               : 'Kazandın: $r';
  static String spinXP(int xp)         => _e ? '+$xp XP added'         : '+$xp XP hesabına eklendi';
  static String get spinThemeUnlocked  => _e ? 'New theme unlocked!'   : 'Yeni tema kilidi açıldı!';

  // ═══════════════════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════════════════
  static String get profileTitle        => _e ? 'Profile'          : 'Profil';
  static String get profileTotalGames   => _e ? 'Total Games'      : 'Toplam Oyun';
  static String get profileAvgIQ        => _e ? 'Average SnapIQ'   : 'Ortalama SnapIQ';
  static String get profileBestIQ       => _e ? 'Best SnapIQ'      : 'En İyi SnapIQ';
  static String get profileBestReaction => _e ? 'Best Reaction'    : 'En İyi Reaksiyon';
  static String profileXP(int xp)       => _e ? '$xp XP total'     : '$xp XP toplam';

  // ═══════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════
  static String get statsTitle          => _e ? 'Statistics'           : 'İstatistikler';
  static String get statsChart          => _e ? 'Last 10 Games – SnapIQ': 'Son 10 Oyun – SnapIQ';
  static String get statsNoGames        => _e ? 'No game records yet.'  : 'Henüz oyun kaydı yok.';
  static String get statsChipBest       => _e ? 'Best'                  : 'En İyi';
  static String get statsChipAvg        => _e ? 'Average'               : 'Ortalama';
  static String get statsChipWorst      => _e ? 'Lowest'                : 'En Düşük';
  static String get statsTotalGames     => _e ? 'Total Games'           : 'Toplam Oyun';
  static String get statsBestIQ         => _e ? 'Best SnapIQ'           : 'En İyi SnapIQ';
  static String get statsBestCogAge     => _e ? 'Best Cognitive Age'    : 'En İyi Bilişsel Yaş';
  static String get statsBestReaction   => _e ? 'Best Reaction'         : 'En İyi Reaksiyon';
  static String get statsTotalTime      => _e ? 'Total Time'            : 'Toplam Süre';

  // ═══════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════
  static String get settingsTitle       => _e ? 'Settings'            : 'Ayarlar';
  static String get settingsSound       => _e ? 'Sound & Vibration'   : 'Ses & Titreşim';
  static String get settingsVisual      => _e ? 'Visual'              : 'Görsel';
  static String get settingsData        => _e ? 'Data'                : 'Veri';
  static String get settingsSoundFX     => _e ? 'Sound Effects'       : 'Ses Efektleri';
  static String get settingsVibration   => _e ? 'Vibration'           : 'Titreşim';
  static String get settingsReduceAnim  => _e ? 'Reduce Animations'   : 'Animasyonları Azalt';
  static String get settingsResetData   => _e ? 'Reset Data'          : 'Verileri Sıfırla';
  static String get settingsDataReset   => _e ? 'Data reset.'         : 'Veriler sıfırlandı.';
  static String get settingsLanguage    => _e ? 'Language'            : 'Dil';
  static String get settingsChangeLang  => _e ? 'Change Language'     : 'Dili Değiştir';

  // ═══════════════════════════════════════════════════════════
  // HOW TO PLAY
  // ═══════════════════════════════════════════════════════════
  static String get howTitle => _e ? 'How to Play' : 'Nasıl Oynanır';

  // ═══════════════════════════════════════════════════════════
  // QUICK PLAY
  // ═══════════════════════════════════════════════════════════
  static String get quickTitle    => _e ? 'Quick Play'                    : 'Hızlı Oyun';
  static String get quickSubtitle => _e ? '~20 second quick brain test.'  : '~20 saniyede hızlı bir beyin testi.';

  // ═══════════════════════════════════════════════════════════
  // BRAIN TRAINING
  // ═══════════════════════════════════════════════════════════
  static String get brainTrainTitle       => _e ? 'Brain Training'                              : 'Beyin Antrenmanı';
  static String get brainTrainPrompt      => _e ? 'Which skill do you want to train?'           : 'Hangi becerini çalışmak istiyorsun?';
  static String get brainTrainMemDesc     => _e ? 'Which boxes lit up? Memorize and select.'    : 'Hangi kutular yandı? Ezberle ve seç.';
  static String get brainTrainStroopDesc  => _e ? 'Stroop color test. Choose the color quickly!': 'Stroop renk testi. Rengi hızlıca seç!';
  static String get brainTrainImpulseDesc => _e ? 'Tap only the correct shape. Stay focused.'   : 'Sadece doğru şekle dokun. Dikkatini koru.';
  static String get brainTrainSeqDesc     => _e ? 'Sort numbers smallest to largest. Beat the clock!': 'Sayıları küçükten büyüğe sırala. Süre dolmadan!';
  static String brainTrainBest(int s)     => _e ? 'Last: $s pts'                                : 'Son: $s puan';

  // ═══════════════════════════════════════════════════════════
  // ARCADE HUB
  // ═══════════════════════════════════════════════════════════
  static String get arcadeSubtitle => _e ? '25 mini games • 8 categories' : '25 mini oyun • 8 kategori';
  static String arcadeBest(int s)  => _e ? 'Best: $s'                     : 'En İyi: $s';

  // ═══════════════════════════════════════════════════════════
  // ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════
  static String get achievementsTitle => _e ? 'Achievements' : 'Başarımlar';

  // ═══════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════
  static String get seeAll         => _e ? 'All'    : 'Tümü';
  static String get widgetSubtitle => _e ? 'Test your reflexes, timing and focus.' : 'Refleksini, zamanlamanı ve odağını test et.';
  static String get diffEasy       => _e ? 'Easy'   : 'Kolay';
  static String get diffMedium     => _e ? 'Medium' : 'Orta';
  static String get diffHard       => _e ? 'Hard'   : 'Zor';

  // ═══════════════════════════════════════════════════════════
  // XP / LEVEL TITLES
  // ═══════════════════════════════════════════════════════════
  static List<String> get levelTitles => _e ? [
    'Beginner', 'Rookie', 'Focused', 'Speed Hunter', 'Brain Ninja',
    'Synapse Master', 'Mind Lord', 'Legend', 'Godlike', 'Infinite',
  ] : [
    'Başlangıç', 'Çaylak', 'Odaklı', 'Hız Avcısı', 'Beyin Ninja',
    'Sinaps Ustası', 'Zihin Efendisi', 'Efsane', 'Tanrısal', 'Sonsuz',
  ];
}
