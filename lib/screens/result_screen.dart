import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../models/test_result.dart';
import '../services/achievement_service.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/score_card.dart';
import '../widgets/cin_host.dart';
import 'home_screen.dart';
import 'prep_screen.dart';

class ResultScreen extends StatefulWidget {
  final TestResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _friendMode = false;
  List<Achievement> _newAchievements = [];
  final int _xpGained = 50;
  bool _achievementOverlayShown = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _postSave();
  }

  Future<void> _postSave() async {
    final s = await StorageService.getInstance();
    await s.saveXP(_xpGained);
    final newLevel = XpService.levelForXp(s.xp);
    await s.saveLevel(newLevel);

    final newAchs = await AchievementService.checkAndUnlock(widget.result, s);
    if (mounted && newAchs.isNotEmpty) {
      setState(() => _newAchievements = newAchs);
      _showAchievementOverlay();
    }
  }

  void _showAchievementOverlay() {
    if (_achievementOverlayShown) return;
    _achievementOverlayShown = true;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _newAchievements.isEmpty) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _AchievementPopup(achievements: _newAchievements),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String funTitle(double score) {
    if (score >= 90) return S.resultFun0;
    if (score >= 80) return S.resultFun1;
    if (score >= 70) return S.resultFun2;
    if (score >= 60) return S.resultFun3;
    if (score >= 45) return S.resultFun4;
    return S.resultFun5;
  }

  String _scoreComment(int score) {
    if (score >= 80) return S.resultPerfect;
    if (score >= 60) return S.resultGood;
    if (score >= 40) return S.resultOk;
    return S.resultWeak;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    if (_friendMode) {
      return _buildFriendHandover(context);
    }

    return Scaffold(
      body: AnimatedBackground(
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const CinHost(size: 90),
                  const SizedBox(height: 8),
                  // Fun title
                  Text(
                    funTitle(r.finalScore),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Label chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00B4FF)
                              .withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      r.label,
                      style: const TextStyle(
                          color: Color(0xFF00B4FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cognitive age
                  Text(
                    S.cognitiveAge(r.cognitiveAge),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            color: Color(0xFF00B4FF), blurRadius: 15)
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.snapIqScore(r.reflexIQ),
                    style: const TextStyle(
                        color: Color(0xFFBB86FC),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.resultDisclaimer,
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // XP gained
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      S.xpGained(_xpGained),
                      style: const TextStyle(
                          color: Color(0xFFBB86FC),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Score cards grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      ScoreCard(
                        title: S.cardReaction,
                        score: r.reactionScore,
                        comment: _scoreComment(r.reactionScore),
                        color: const Color(0xFF00C853),
                      ),
                      ScoreCard(
                        title: S.cardStroop,
                        score: r.stroopScore,
                        comment: _scoreComment(r.stroopScore),
                        color: const Color(0xFF1E88E5),
                      ),
                      ScoreCard(
                        title: S.cardMemory,
                        score: r.memoryScore,
                        comment: _scoreComment(r.memoryScore),
                        color: const Color(0xFFBB86FC),
                      ),
                      ScoreCard(
                        title: S.cardSequence,
                        score: r.sequenceScore,
                        comment: _scoreComment(r.sequenceScore),
                        color: const Color(0xFFFDD835),
                      ),
                      ScoreCard(
                        title: S.cardImpulse,
                        score: r.impulseScore,
                        comment: _scoreComment(r.impulseScore),
                        color: const Color(0xFFFF7043),
                      ),
                      ScoreCard(
                        title: S.cardPattern,
                        score: r.patternScore,
                        comment: _scoreComment(r.patternScore),
                        color: const Color(0xFF03DAC6),
                      ),
                      ScoreCard(
                        title: 'Refleks',
                        score: r.circleScore,
                        comment: _scoreComment(r.circleScore),
                        color: const Color(0xFF00E5FF),
                      ),
                      ScoreCard(
                        title: 'Laser Gate',
                        score: r.laserScore,
                        comment: _scoreComment(r.laserScore),
                        color: const Color(0xFFFF7043),
                      ),
                      ScoreCard(
                        title: 'Timing',
                        score: r.timingScore,
                        comment: _scoreComment(r.timingScore),
                        color: const Color(0xFF03DAC6),
                      ),
                      ScoreCard(
                        title: 'Pulse Stop',
                        score: r.pulseScore,
                        comment: _scoreComment(r.pulseScore),
                        color: const Color(0xFFFDD835),
                      ),
                      ScoreCard(
                        title: 'Balance Bar',
                        score: r.balanceScore,
                        comment: _scoreComment(r.balanceScore),
                        color: const Color(0xFF00C853),
                      ),
                      ScoreCard(
                        title: 'Dart Focus',
                        score: r.dartScore,
                        comment: _scoreComment(r.dartScore),
                        color: const Color(0xFFFF7043),
                      ),
                      ScoreCard(
                        title: 'Sky Shot',
                        score: r.skyScore,
                        comment: _scoreComment(r.skyScore),
                        color: const Color(0xFF00B4FF),
                      ),
                      ScoreCard(
                        title: 'Target Lock',
                        score: r.targetLockScore,
                        comment: _scoreComment(r.targetLockScore),
                        color: const Color(0xFF00C853),
                      ),
                      ScoreCard(
                        title: 'Swipe Dodge',
                        score: r.swipeDodgeScore,
                        comment: _scoreComment(r.swipeDodgeScore),
                        color: const Color(0xFFE91E63),
                      ),
                      ScoreCard(
                        title: 'Color Panic',
                        score: r.colorPanicScore,
                        comment: _scoreComment(r.colorPanicScore),
                        color: Colors.purple,
                      ),
                      ScoreCard(
                        title: "Don't Tap Red",
                        score: r.dontTapRedScore,
                        comment: _scoreComment(r.dontTapRedScore),
                        color: Colors.red,
                      ),
                      ScoreCard(
                        title: 'Tap Target',
                        score: r.tapTargetScore,
                        comment: _scoreComment(r.tapTargetScore),
                        color: const Color(0xFF00C853),
                      ),
                      ScoreCard(
                        title: 'Shape Strike',
                        score: r.shapeStrikeScore,
                        comment: _scoreComment(r.shapeStrikeScore),
                        color: const Color(0xFFFDD835),
                      ),
                      ScoreCard(title: 'Memory Flash', score: r.memoryFlashScore, comment: _scoreComment(r.memoryFlashScore), color: const Color(0xFFBB86FC)),
                      ScoreCard(title: 'Mirror Brain', score: r.mirrorBrainScore, comment: _scoreComment(r.mirrorBrainScore), color: const Color(0xFFFDD835)),
                      ScoreCard(title: 'Sequence Rush', score: r.sequenceRushScore, comment: _scoreComment(r.sequenceRushScore), color: const Color(0xFFE53935)),
                      ScoreCard(title: 'Reaction Wall', score: r.reactionWallScore, comment: _scoreComment(r.reactionWallScore), color: const Color(0xFFFF7043)),
                      ScoreCard(title: 'Focus Hunter', score: r.focusHunterScore, comment: _scoreComment(r.focusHunterScore), color: const Color(0xFF00C853)),
                      ScoreCard(title: 'Impulse Ctrl', score: r.impulseControlScore, comment: _scoreComment(r.impulseControlScore), color: const Color(0xFF1E88E5)),
                      ScoreCard(title: 'Tap Rain', score: r.tapRainScore, comment: _scoreComment(r.tapRainScore), color: const Color(0xFF00B4FF)),
                      ScoreCard(title: 'Speed Math', score: r.speedMathScore, comment: _scoreComment(r.speedMathScore), color: const Color(0xFF03DAC6)),
                      ScoreCard(title: 'Num Hunter', score: r.numberHunterScore, comment: _scoreComment(r.numberHunterScore), color: const Color(0xFFBB86FC)),
                      ScoreCard(title: 'Pattern Mstr', score: r.patternMasterScore, comment: _scoreComment(r.patternMasterScore), color: const Color(0xFF00C853)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_newAchievements.isNotEmpty) _buildNewAchievements(),
                  const SizedBox(height: 12),
                  // Buttons
                  NeonButton(
                    text: S.tryAgain,
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrepScreen()),
                    ),
                    color: const Color(0xFF00B4FF),
                    width: double.infinity,
                    height: 52,
                    icon: Icons.refresh_rounded,
                  ),
                  const SizedBox(height: 10),
                  NeonButton(
                    text: S.resultShare,
                    onPressed: () => setState(() => _friendMode = true),
                    color: const Color(0xFFBB86FC),
                    width: double.infinity,
                    height: 52,
                    icon: Icons.people_rounded,
                  ),
                  const SizedBox(height: 10),
                  NeonButton(
                    text: S.menu,
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                      (_) => false,
                    ),
                    color: const Color(0xFF03DAC6),
                    width: double.infinity,
                    height: 52,
                    icon: Icons.home_rounded,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewAchievements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFBB86FC).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.newAchievements,
              style: const TextStyle(
                  color: Color(0xFFBB86FC),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 8),
          ..._newAchievements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(a.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          Text(a.description,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text('+${a.xpReward} XP',
                        style: const TextStyle(
                            color: Color(0xFFBB86FC), fontSize: 11)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFriendHandover(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CinHost(size: 100),
                const SizedBox(height: 24),
                Text(
                  S.giveToFriend,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  S.canBeatYou,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${S.yourSnapIQ(widget.result.reflexIQ)}  •  Yaş: ${widget.result.cognitiveAge}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFBB86FC), fontSize: 14),
                ),
                const SizedBox(height: 40),
                NeonButton(
                  text: S.resultStartTest,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrepScreen()),
                  ),
                  color: const Color(0xFF00B4FF),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.play_arrow_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementPopup extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementPopup({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.achievEarned,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...achievements.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(a.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: const TextStyle(
                                    color: Color(0xFFBB86FC),
                                    fontWeight: FontWeight.bold)),
                            Text(a.description,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('+${a.xpReward} XP',
                          style: const TextStyle(
                              color: Color(0xFFBB86FC), fontSize: 12)),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.awesome,
                  style: const TextStyle(color: Color(0xFF00B4FF))),
            ),
          ],
        ),
      ),
    );
  }
}
