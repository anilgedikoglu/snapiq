import 'package:flutter/material.dart';
import '../models/test_result.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import 'home_screen.dart';

class VsFriendResultScreen extends StatefulWidget {
  final TestResult p1Result;
  final TestResult p2Result;

  const VsFriendResultScreen({
    super.key,
    required this.p1Result,
    required this.p2Result,
  });

  @override
  State<VsFriendResultScreen> createState() => _VsFriendResultScreenState();
}

class _VsFriendResultScreenState extends State<VsFriendResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkAchievements();
  }

  Future<void> _checkAchievements() async {
    final p1Wins = widget.p1Result.reflexIQ > widget.p2Result.reflexIQ;
    if (p1Wins) {
      final s = await StorageService.getInstance();
      await AchievementService.unlockBeatFriend(s);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _p1Wins =>
      widget.p1Result.reflexIQ >= widget.p2Result.reflexIQ;

  String get _celebrationText {
    final diff = (widget.p1Result.reflexIQ - widget.p2Result.reflexIQ).abs();
    if (_p1Wins) {
      if (diff >= 20) return 'Oyuncu 1 ezdi geçti! 💀';
      if (diff >= 10) return 'Oyuncu 1 çok daha hızlı! ⚡';
      return 'Oyuncu 1 kazandı! 🏆';
    } else {
      if (diff >= 20) return 'Oyuncu 2 ezdi geçti! 💀';
      if (diff >= 10) return 'Oyuncu 2 çok daha hızlı! ⚡';
      return 'Oyuncu 2 kazandı! 🏆';
    }
  }

  String get _speedComparison {
    final iq1 = widget.p1Result.reflexIQ;
    final iq2 = widget.p2Result.reflexIQ;
    if (iq1 == iq2) return 'Beraberlik!';
    final winner = _p1Wins ? iq1 : iq2;
    final loser = _p1Wins ? iq2 : iq1;
    if (loser == 0) return '';
    final pct = ((winner - loser) / loser * 100).round();
    return '%$pct daha hızlı zihin!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(
                    _celebrationText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _speedComparison,
                    style: const TextStyle(
                        color: Color(0xFF00B4FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _PlayerCard(
                              label: 'Oyuncu 1',
                              result: widget.p1Result,
                              isWinner: _p1Wins)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _PlayerCard(
                              label: 'Oyuncu 2',
                              result: widget.p2Result,
                              isWinner: !_p1Wins)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildComparison(),
                  const SizedBox(height: 24),
                  NeonButton(
                    text: 'Ana Menü',
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    ),
                    color: const Color(0xFF00B4FF),
                    width: double.infinity,
                    height: 52,
                    icon: Icons.home_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparison() {
    final r1 = widget.p1Result;
    final r2 = widget.p2Result;
    final categories = [
      ('Reaksiyon', r1.reactionScore, r2.reactionScore),
      ('Dikkat', r1.stroopScore, r2.stroopScore),
      ('Hafıza', r1.memoryScore, r2.memoryScore),
      ('Sıralama', r1.sequenceScore, r2.sequenceScore),
      ('İmpuls', r1.impulseScore, r2.impulseScore),
      ('Örüntü', r1.patternScore, r2.patternScore),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00B4FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: categories.map((c) {
          final name = c.$1;
          final s1 = c.$2;
          final s2 = c.$3;
          final total = s1 + s2;
          final w1 = total > 0 ? s1 / total : 0.5;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // P1 bar
                      Expanded(
                        flex: (w1 * 100).round(),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: s1 >= s2
                                ? const Color(0xFFBB86FC)
                                : const Color(0xFF333333),
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(4)),
                          ),
                        ),
                      ),
                      // P2 bar
                      Expanded(
                        flex: ((1 - w1) * 100).round(),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: s2 > s1
                                ? const Color(0xFF00B4FF)
                                : const Color(0xFF333333),
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String label;
  final TestResult result;
  final bool isWinner;

  const _PlayerCard({
    required this.label,
    required this.result,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isWinner ? const Color(0xFFBB86FC) : const Color(0xFF555555);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          if (isWinner)
            const Text('👑',
                style: TextStyle(fontSize: 20)),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 6),
          Text('${result.reflexIQ}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const Text('SnapIQ',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Text('Yaş: ${result.cognitiveAge}',
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
