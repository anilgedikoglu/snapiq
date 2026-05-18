import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/cin_host.dart';
import 'arcade/color_panic_screen.dart';
import 'arcade/tap_target_screen.dart';
import 'arcade/dont_tap_red_screen.dart';
import 'arcade/number_hunter_screen.dart';
import 'arcade/memory_flash_screen.dart';
import 'arcade/shape_strike_screen.dart';
import 'arcade/speed_math_screen.dart';
import 'arcade/mirror_brain_screen.dart';
import 'arcade/sequence_rush_screen.dart';
import 'arcade/reaction_wall_screen.dart';
import 'arcade/focus_hunter_screen.dart';
import 'arcade/impulse_control_screen.dart';
import 'arcade/tap_rain_screen.dart';
import 'arcade/brain_duel_screen.dart';
import 'arcade/pattern_master_screen.dart';

class _GameInfo {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final Color color;
  final Widget Function() screenBuilder;

  const _GameInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.color,
    required this.screenBuilder,
  });
}

class ArcadeHubScreen extends StatefulWidget {
  const ArcadeHubScreen({super.key});

  @override
  State<ArcadeHubScreen> createState() => _ArcadeHubScreenState();
}

class _ArcadeHubScreenState extends State<ArcadeHubScreen> {
  StorageService? _storage;

  static final _games = <_GameInfo>[
    _GameInfo(
        id: 'color_panic',
        name: 'Color Panic',
        emoji: '🎨',
        category: 'Reflex',
        color: const Color(0xFFFF7043),
        screenBuilder: () => const ColorPanicScreen()),
    _GameInfo(
        id: 'tap_target',
        name: 'Tap Target',
        emoji: '🎯',
        category: 'Reflex',
        color: const Color(0xFFFF7043),
        screenBuilder: () => const TapTargetScreen()),
    _GameInfo(
        id: 'dont_tap_red',
        name: "Don't Tap Red",
        emoji: '🚫',
        category: 'Reflex',
        color: const Color(0xFFFF7043),
        screenBuilder: () => const DontTapRedScreen()),
    _GameInfo(
        id: 'reaction_wall',
        name: 'Reaction Wall',
        emoji: '🧱',
        category: 'Reflex',
        color: const Color(0xFFFF7043),
        screenBuilder: () => const ReactionWallScreen()),
    _GameInfo(
        id: 'memory_flash',
        name: 'Memory Flash',
        emoji: '🧠',
        category: 'Memory',
        color: const Color(0xFFBB86FC),
        screenBuilder: () => const MemoryFlashScreen()),
    _GameInfo(
        id: 'sequence_rush',
        name: 'Sequence Rush',
        emoji: '🔗',
        category: 'Memory',
        color: const Color(0xFFBB86FC),
        screenBuilder: () => const SequenceRushScreen()),
    _GameInfo(
        id: 'number_hunter',
        name: 'Number Hunter',
        emoji: '🔢',
        category: 'Focus',
        color: const Color(0xFF1E88E5),
        screenBuilder: () => const NumberHunterScreen()),
    _GameInfo(
        id: 'focus_hunter',
        name: 'Focus Hunter',
        emoji: '🔍',
        category: 'Focus',
        color: const Color(0xFF1E88E5),
        screenBuilder: () => const FocusHunterScreen()),
    _GameInfo(
        id: 'impulse_control',
        name: 'Impulse Control',
        emoji: '⚡',
        category: 'Impulse',
        color: const Color(0xFF03DAC6),
        screenBuilder: () => const ImpulseControlScreen()),
    _GameInfo(
        id: 'shape_strike',
        name: 'Shape Strike',
        emoji: '🔷',
        category: 'Impulse',
        color: const Color(0xFF03DAC6),
        screenBuilder: () => const ShapeStrikeScreen()),
    _GameInfo(
        id: 'tap_rain',
        name: 'Tap Rain',
        emoji: '🌧️',
        category: 'Impulse',
        color: const Color(0xFF03DAC6),
        screenBuilder: () => const TapRainScreen()),
    _GameInfo(
        id: 'speed_math',
        name: 'Speed Math',
        emoji: '➕',
        category: 'Logic',
        color: const Color(0xFFFDD835),
        screenBuilder: () => const SpeedMathScreen()),
    _GameInfo(
        id: 'mirror_brain',
        name: 'Mirror Brain',
        emoji: '🪞',
        category: 'Logic',
        color: const Color(0xFFFDD835),
        screenBuilder: () => const MirrorBrainScreen()),
    _GameInfo(
        id: 'pattern_master',
        name: 'Pattern Master',
        emoji: '👑',
        category: 'Logic',
        color: const Color(0xFFFDD835),
        screenBuilder: () => const PatternMasterScreen()),
    _GameInfo(
        id: 'brain_duel',
        name: 'Brain Duel',
        emoji: '⚔️',
        category: 'Special',
        color: const Color(0xFFE91E63),
        screenBuilder: () => const BrainDuelScreen()),
  ];

  static const _categoryOrder = [
    'Reflex',
    'Memory',
    'Focus',
    'Impulse',
    'Logic',
    'Special',
  ];

  static const _categoryColors = {
    'Reflex': Color(0xFFFF7043),
    'Memory': Color(0xFFBB86FC),
    'Focus': Color(0xFF1E88E5),
    'Impulse': Color(0xFF03DAC6),
    'Logic': Color(0xFFFDD835),
    'Special': Color(0xFFE91E63),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) setState(() => _storage = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const CinHost(size: 70),
              const SizedBox(height: 4),
              const Text('15 mini oyun • 6 kategori',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  children: _categoryOrder
                      .map((cat) => _buildCategory(cat))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(String category) {
    final catColor = _categoryColors[category]!;
    final games = _games.where((g) => g.category == category).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: catColor.withValues(alpha: 0.4)),
          ),
          child: Text(category,
              style: TextStyle(
                  color: catColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (ctx, i) => _buildGameCard(games[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(_GameInfo game) {
    final best = _storage?.arcadeBestScore(game.id) ?? 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => game.screenBuilder()),
        ).then((_) => _load());
      },
      child: Container(
        width: 170,
        height: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: game.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
                color: game.color.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 1)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 6),
              Text(game.name,
                  style: TextStyle(
                      color: game.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text('En İyi: $best',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Reflex Arcade',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
