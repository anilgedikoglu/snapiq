import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';
import '../widgets/neon_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/cin_host.dart';
import 'prep_screen.dart';
import 'best_scores_screen.dart';
import 'how_to_play_screen.dart';
import 'quick_play_screen.dart';
import 'daily_challenge_screen.dart';
import 'vs_friend_screen.dart';
import 'endless_reflex_screen.dart';
import 'ultra_hard_screen.dart';
import 'brain_training_screen.dart';
import 'spin_wheel_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import 'arcade_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) setState(() => _storage = s);
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool get _dailyPlayed =>
      _storage != null && _storage!.dailyChallengeLastDate == _todayStr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const CinHost(size: 100),
                    const SizedBox(height: 4),
                    const Text(
                      'SnapIQ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                              color: Color(0xFF00B4FF), blurRadius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '60 saniyede refleksini, hafızanı\nve dikkatini ölç.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_storage != null) _buildLevelBar(),
                    const SizedBox(height: 10),
                    if (_storage != null) _buildStats(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Primary action
                    NeonButton(
                      text: 'Teste Başla',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrepScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFF00B4FF),
                      width: double.infinity,
                      height: 60,
                      icon: Icons.play_arrow_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Hızlı Oyun',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QuickPlayScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFF03DAC6),
                      width: double.infinity,
                      icon: Icons.flash_on_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: _dailyPlayed
                          ? 'Günün Meydan Okuması ✓'
                          : 'Günün Meydan Okuması',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const DailyChallengeScreen()),
                      ).then((_) => _load()),
                      color: _dailyPlayed
                          ? const Color(0xFF03DAC6)
                          : const Color(0xFFFDD835),
                      width: double.infinity,
                      icon: Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Arkadaşını Geç',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VsFriendScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFFBB86FC),
                      width: double.infinity,
                      icon: Icons.people_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Sonsuz Refleks',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const EndlessReflexScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFF00C853),
                      width: double.infinity,
                      icon: Icons.all_inclusive_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Manyak Mod',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UltraHardScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFFFF7043),
                      width: double.infinity,
                      icon: Icons.local_fire_department_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Beyin Antrenmanı',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const BrainTrainingScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFF7B2FBE),
                      width: double.infinity,
                      icon: Icons.psychology_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Reflex Arcade',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ArcadeHubScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFFE91E63),
                      width: double.infinity,
                      icon: Icons.sports_esports_rounded,
                    ),
                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 14),
                    NeonButton(
                      text: 'Çark Çevir',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SpinWheelScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFFE91E63),
                      width: double.infinity,
                      icon: Icons.casino_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Profil',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFF9C27B0),
                      width: double.infinity,
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'İstatistikler',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StatsScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFF1E88E5),
                      width: double.infinity,
                      icon: Icons.bar_chart_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Başarımlar',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AchievementsScreen()),
                      ).then((_) => _load()),
                      color: const Color(0xFFFDD835),
                      width: double.infinity,
                      icon: Icons.emoji_events_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'En İyi Skorlar',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BestScoresScreen()),
                      ),
                      color: const Color(0xFFBB86FC),
                      width: double.infinity,
                      icon: Icons.leaderboard_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Ayarlar',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ).then((_) => _load()),
                      color: Colors.white38,
                      width: double.infinity,
                      icon: Icons.settings_rounded,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      text: 'Nasıl Oynanır',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HowToPlayScreen()),
                      ),
                      color: Colors.white38,
                      width: double.infinity,
                      icon: Icons.help_outline_rounded,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBar() {
    final s = _storage!;
    final level = s.level;
    final title = XpService.titleForLevel(level);
    final xpAtStart = XpService.xpAtLevelStart(level);
    final xpForLevel = XpService.xpForLevelUp(level);
    final xpInLevel = (s.xp - xpAtStart).clamp(0, xpForLevel);
    final progress =
        xpForLevel > 0 ? (xpInLevel / xpForLevel).clamp(0.0, 1.0) : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFBB86FC).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFBB86FC).withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Seviye $level – $title',
                    style: const TextStyle(
                        color: Color(0xFFBB86FC), fontSize: 12)),
                Text('${s.xp} XP',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    const Color(0xFFBB86FC).withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFFBB86FC)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final s = _storage!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatTile(
            label: 'En İyi Yaş',
            value:
                s.bestCognitiveAge == 0 ? '--' : '${s.bestCognitiveAge}',
            color: const Color(0xFF03DAC6),
          ),
          _StatTile(
            label: 'SnapIQ',
            value: s.bestReflexIQ == 0 ? '--' : '${s.bestReflexIQ}',
            color: const Color(0xFF00B4FF),
          ),
          _StatTile(
            label: 'Deneme',
            value: '${s.totalGames}',
            color: const Color(0xFFBB86FC),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.12), height: 1)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
