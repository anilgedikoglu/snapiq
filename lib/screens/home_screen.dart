import 'package:flutter/material.dart';
import '../models/mini_game.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_card.dart';
import '../widgets/horizontal_game_list.dart';
import '../widgets/premium_header.dart';
import '../widgets/section_header.dart';

// Existing screens
import 'prep_screen.dart';
import 'quick_play_screen.dart';
import 'daily_challenge_screen.dart';
import 'endless_reflex_screen.dart';
import 'ultra_hard_screen.dart';
import 'vs_friend_screen.dart';
import 'spin_wheel_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';
import 'best_scores_screen.dart';
import 'settings_screen.dart';
import 'how_to_play_screen.dart';

// Existing arcade games
import 'arcade/color_panic_screen.dart';
import 'arcade/dont_tap_red_screen.dart';
import 'arcade/tap_target_screen.dart';
import 'arcade/shape_strike_screen.dart';
import 'arcade/memory_flash_screen.dart';
import 'arcade/number_hunter_screen.dart';
import 'arcade/pattern_master_screen.dart';
import 'arcade/mirror_brain_screen.dart';
import 'arcade/speed_math_screen.dart';

// New game screens
import 'games/orbit_sync_screen.dart';
import 'games/laser_gate_screen.dart';
import 'games/timing_stack_screen.dart';
import 'games/pulse_stop_screen.dart';
import 'games/balance_bar_screen.dart';
import 'games/dart_focus_screen.dart';
import 'games/sky_shot_screen.dart';
import 'games/target_lock_screen.dart';
import 'games/split_second_screen.dart';
import 'games/swipe_dodge_screen.dart';

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

  List<MiniGameInfo> get _timingGames => [
        MiniGameInfo(
          id: 'orbit_sync',
          title: 'Orbit Sync',
          subtitle: 'Halkaları hizala',
          category: GameCategory.timing,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFBB86FC),
          icon: Icons.radio_button_unchecked,
          duration: '10 tur',
          builder: () => const OrbitSyncScreen(),
        ),
        MiniGameInfo(
          id: 'laser_gate',
          title: 'Laser Gate',
          subtitle: 'Boşluktan geç',
          category: GameCategory.timing,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFF00B4FF),
          icon: Icons.bolt,
          duration: '3 can',
          builder: () => const LaserGateScreen(),
        ),
        MiniGameInfo(
          id: 'timing_stack',
          title: 'Timing Stack',
          subtitle: 'Bloğu hizala',
          category: GameCategory.timing,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFF03DAC6),
          icon: Icons.stacked_line_chart,
          duration: '∞',
          builder: () => const TimingStackScreen(),
        ),
        MiniGameInfo(
          id: 'pulse_stop',
          title: 'Pulse Stop',
          subtitle: 'Tam zamanında dur',
          category: GameCategory.timing,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFFFDD835),
          icon: Icons.radio_button_checked,
          duration: '15 tur',
          builder: () => const PulseStopScreen(),
        ),
        MiniGameInfo(
          id: 'balance_bar',
          title: 'Balance Bar',
          subtitle: 'Hedefi yakala',
          category: GameCategory.timing,
          difficulty: GameDifficulty.easy,
          color: const Color(0xFF00C853),
          icon: Icons.equalizer,
          duration: '15 tur',
          builder: () => const BalanceBarScreen(),
        ),
      ];

  List<MiniGameInfo> get _aimGames => [
        MiniGameInfo(
          id: 'dart_focus',
          title: 'Dart Focus',
          subtitle: "Bullseye'a nişan al",
          category: GameCategory.aimShoot,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFFF7043),
          icon: Icons.gps_fixed,
          duration: '5 atış',
          builder: () => const DartFocusScreen(),
        ),
        MiniGameInfo(
          id: 'sky_shot',
          title: 'Sky Shot',
          subtitle: 'Uçan hedefe ateş et',
          category: GameCategory.aimShoot,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFF00B4FF),
          icon: Icons.flight_takeoff,
          duration: '5 hedef',
          builder: () => const SkyShotScreen(),
        ),
        MiniGameInfo(
          id: 'target_lock',
          title: 'Target Lock',
          subtitle: 'Radarı kilitle',
          category: GameCategory.aimShoot,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFBB86FC),
          icon: Icons.radar,
          duration: '10 hedef',
          builder: () => const TargetLockScreen(),
        ),
      ];

  List<MiniGameInfo> get _reflexGames => [
        MiniGameInfo(
          id: 'split_second',
          title: 'Split Second',
          subtitle: 'Anlık karar ver',
          category: GameCategory.reflexArcade,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFFF7043),
          icon: Icons.speed,
          duration: '30 sin',
          builder: () => const SplitSecondScreen(),
        ),
        MiniGameInfo(
          id: 'swipe_dodge',
          title: 'Swipe Dodge',
          subtitle: 'Engellerden kaç',
          category: GameCategory.reflexArcade,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFF00C853),
          icon: Icons.swap_horiz,
          duration: '3 can',
          builder: () => const SwipeDodgeScreen(),
        ),
        MiniGameInfo(
          id: 'color_panic',
          title: 'Color Panic',
          subtitle: 'Renk eşleştir',
          category: GameCategory.reflexArcade,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFFF7043),
          icon: Icons.palette,
          duration: '3 can',
          builder: () => const ColorPanicScreen(),
        ),
        MiniGameInfo(
          id: 'dont_tap_red',
          title: "Don't Tap Red",
          subtitle: 'Kırmızıya dokunma!',
          category: GameCategory.reflexArcade,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFFE91E63),
          icon: Icons.do_not_disturb_on,
          duration: '3 can',
          builder: () => const DontTapRedScreen(),
        ),
        MiniGameInfo(
          id: 'tap_target',
          title: 'Tap Target',
          subtitle: 'Hedefleri vur',
          category: GameCategory.reflexArcade,
          difficulty: GameDifficulty.easy,
          color: const Color(0xFF03DAC6),
          icon: Icons.adjust,
          duration: '30 sn',
          builder: () => const TapTargetScreen(),
        ),
        MiniGameInfo(
          id: 'shape_strike',
          title: 'Shape Strike',
          subtitle: 'Doğru şekle dokun',
          category: GameCategory.reflexArcade,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFFFDD835),
          icon: Icons.category,
          duration: '3 can',
          builder: () => const ShapeStrikeScreen(),
        ),
      ];

  List<MiniGameInfo> get _brainGames => [
        MiniGameInfo(
          id: 'memory_flash',
          title: 'Memory Flash',
          subtitle: 'Deseni ezberle',
          category: GameCategory.brainFocus,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFFBB86FC),
          icon: Icons.grid_view,
          duration: '3 can',
          builder: () => const MemoryFlashScreen(),
        ),
        MiniGameInfo(
          id: 'number_hunter',
          title: 'Number Hunter',
          subtitle: 'Sayıyı hızlı bul',
          category: GameCategory.brainFocus,
          difficulty: GameDifficulty.easy,
          color: const Color(0xFF1E88E5),
          icon: Icons.search,
          duration: '10 tur',
          builder: () => const NumberHunterScreen(),
        ),
        MiniGameInfo(
          id: 'pattern_master',
          title: 'Pattern Master',
          subtitle: 'Örüntüyü tamamla',
          category: GameCategory.brainFocus,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFFDD835),
          icon: Icons.schema,
          duration: '10 soru',
          builder: () => const PatternMasterScreen(),
        ),
        MiniGameInfo(
          id: 'mirror_brain',
          title: 'Mirror Brain',
          subtitle: 'Tersini seç',
          category: GameCategory.brainFocus,
          difficulty: GameDifficulty.hard,
          color: const Color(0xFFBB86FC),
          icon: Icons.flip,
          duration: '15 tur',
          builder: () => const MirrorBrainScreen(),
        ),
        MiniGameInfo(
          id: 'speed_math',
          title: 'Speed Math',
          subtitle: 'Hızlı matematik',
          category: GameCategory.brainFocus,
          difficulty: GameDifficulty.medium,
          color: const Color(0xFF03DAC6),
          icon: Icons.calculate,
          duration: '10 soru',
          builder: () => const SpeedMathScreen(),
        ),
      ];

  void _navigate(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 1. Premium header
              SliverToBoxAdapter(
                child: PremiumHeader(storage: _storage),
              ),

              // 2. Daily Challenge hero card
              SliverToBoxAdapter(
                child: _buildDailyChallenge(),
              ),

              // 3. Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // 4. Timing Games
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Timing Games',
                  color: const Color(0xFFBB86FC),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalGameList(
                  games: _timingGames,
                  storage: _storage,
                ),
              ),

              // 5. Aim & Shoot
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Aim & Shoot',
                  color: const Color(0xFFFF7043),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalGameList(
                  games: _aimGames,
                  storage: _storage,
                ),
              ),

              // 6. Reflex Arcade (2-column grid)
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Reflex Arcade',
                  color: const Color(0xFF00C853),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildReflexGrid(),
              ),

              // 7. Brain Focus
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Brain Focus',
                  color: const Color(0xFF03DAC6),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalGameList(
                  games: _brainGames,
                  storage: _storage,
                ),
              ),

              // 8. Daha Fazla
              SliverToBoxAdapter(
                child: _buildMoreSection(),
              ),

              // 9. Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChallenge() {
    final played = _dailyPlayed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _navigate(const DailyChallengeScreen()),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: played
                  ? [
                      const Color(0xFF03DAC6).withValues(alpha: 0.25),
                      const Color(0xFF00B4FF).withValues(alpha: 0.15),
                    ]
                  : [
                      const Color(0xFFFDD835).withValues(alpha: 0.25),
                      const Color(0xFFFF7043).withValues(alpha: 0.15),
                    ],
            ),
            border: Border.all(
              color: played
                  ? const Color(0xFF03DAC6).withValues(alpha: 0.5)
                  : const Color(0xFFFDD835).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  played ? Icons.check_circle : Icons.calendar_today_rounded,
                  color: played
                      ? const Color(0xFF03DAC6)
                      : const Color(0xFFFDD835),
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        played
                            ? 'Bugünkü Görev Tamamlandı!'
                            : 'Bugünün Göreviyle Başla',
                        style: TextStyle(
                          color: played
                              ? const Color(0xFF03DAC6)
                              : const Color(0xFFFDD835),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        played ? 'Yarın tekrar gel' : 'Günlük meydan okuma',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _QuickCard(
              title: 'Full Test',
              subtitle: '6 test • 3 dk',
              color: const Color(0xFF00B4FF),
              icon: Icons.play_arrow,
              onTap: () => _navigate(const PrepScreen()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickCard(
              title: 'Hızlı Oyun',
              subtitle: '2 test • 45 sn',
              color: const Color(0xFF03DAC6),
              icon: Icons.flash_on,
              onTap: () => _navigate(const QuickPlayScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflexGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 160 / 200,
        ),
        itemCount: _reflexGames.length,
        itemBuilder: (ctx, i) {
          final game = _reflexGames[i];
          final best = _storage?.arcadeBestScore(game.id) ?? 0;
          return GameCard(
            game: game,
            bestScore: best,
            onTap: () => _navigate(game.builder()),
          );
        },
      ),
    );
  }

  Widget _buildMoreSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Daha Fazla',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 0.5),
            ),
          ),
          _buildMoreRow([
            _MoreBtn(
                label: 'Sonsuz\nRefleks',
                icon: Icons.all_inclusive_rounded,
                color: const Color(0xFF00C853),
                onTap: () => _navigate(const EndlessReflexScreen())),
            _MoreBtn(
                label: 'Manyak\nMod',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF7043),
                onTap: () => _navigate(const UltraHardScreen())),
            _MoreBtn(
                label: 'VS\nArkadaş',
                icon: Icons.people_rounded,
                color: const Color(0xFFBB86FC),
                onTap: () => _navigate(const VsFriendScreen())),
            _MoreBtn(
                label: 'Çark\nÇevir',
                icon: Icons.casino_rounded,
                color: const Color(0xFFE91E63),
                onTap: () => _navigate(const SpinWheelScreen())),
          ]),
          const SizedBox(height: 10),
          _buildMoreRow([
            _MoreBtn(
                label: 'Profil',
                icon: Icons.person_rounded,
                color: const Color(0xFF9C27B0),
                onTap: () => _navigate(const ProfileScreen())),
            _MoreBtn(
                label: 'Başarımlar',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFFDD835),
                onTap: () => _navigate(const AchievementsScreen())),
            _MoreBtn(
                label: 'İstatistik',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF1E88E5),
                onTap: () => _navigate(const StatsScreen())),
            _MoreBtn(
                label: 'En İyi\nSkorlar',
                icon: Icons.leaderboard_rounded,
                color: const Color(0xFFBB86FC),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BestScoresScreen()))),
          ]),
          const SizedBox(height: 10),
          _buildMoreRow([
            _MoreBtn(
                label: 'Ayarlar',
                icon: Icons.settings_rounded,
                color: Colors.white38,
                onTap: () => _navigate(const SettingsScreen())),
            _MoreBtn(
                label: 'Nasıl\nOynanır',
                icon: Icons.help_outline_rounded,
                color: Colors.white38,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HowToPlayScreen()))),
          ]),
        ],
      ),
    );
  }

  Widget _buildMoreRow(List<_MoreBtn> buttons) {
    return Row(
      children: buttons
          .map((b) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: b.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: b.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: b.color.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(b.icon, color: b.color, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            b.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: b.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.15), blurRadius: 12)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreBtn {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MoreBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
}
