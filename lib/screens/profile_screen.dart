import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/player_profile.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/cin_host.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PlayerProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) {
      setState(() => _profile = PlayerProfile.fromStorage(s));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 20),
                    ),
                    const Text('Profil',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_profile == null)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00B4FF))))
              else
                Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final level = p.level;
    final title = XpService.titleForLevel(level);
    final xpAtStart = XpService.xpAtLevelStart(level);
    final xpForLevel = XpService.xpForLevelUp(level);
    final xpInLevel = (p.xp - xpAtStart).clamp(0, xpForLevel);
    final xpProgress =
        xpForLevel > 0 ? (xpInLevel / xpForLevel).clamp(0.0, 1.0) : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const CinHost(size: 100),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFBB86FC),
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Seviye $level',
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 12),
          _buildXpBar(p.xp, xpProgress, xpForLevel, xpInLevel),
          const SizedBox(height: 20),
          _buildStatsGrid(p),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Başarımlar',
                style: TextStyle(
                    color: Color(0xFF00B4FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const SizedBox(height: 12),
          _buildAchievements(p),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildXpBar(
      int xp, double progress, int xpForLevel, int xpInLevel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFBB86FC).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFBB86FC).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$xp XP toplam',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('$xpInLevel / $xpForLevel XP',
                  style: const TextStyle(
                      color: Color(0xFFBB86FC), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  const Color(0xFFBB86FC).withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFBB86FC)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(PlayerProfile p) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _statCard('Toplam Oyun', '${p.totalGames}',
            const Color(0xFF00B4FF)),
        _statCard('Ortalama SnapIQ',
            p.avgSnapIQ > 0 ? p.avgSnapIQ.toStringAsFixed(1) : '--',
            const Color(0xFF03DAC6)),
        _statCard('En İyi SnapIQ',
            p.bestSnapIQ > 0 ? '${p.bestSnapIQ}' : '--',
            const Color(0xFFBB86FC)),
        _statCard(
            'En İyi Reaksiyon',
            p.bestReactionMs > 0 ? '${p.bestReactionMs} ms' : '--',
            const Color(0xFF00C853)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAchievements(PlayerProfile p) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: Achievement.all.length,
      itemBuilder: (_, i) {
        final ach = Achievement.all[i];
        final unlocked = p.unlockedAchievements.contains(ach.id);
        return Tooltip(
          message: '${ach.title}\n${ach.description}',
          child: Container(
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFF00B4FF).withValues(alpha: 0.12)
                  : const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: unlocked
                    ? const Color(0xFF00B4FF).withValues(alpha: 0.5)
                    : Colors.white12,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00B4FF).withValues(alpha: 0.2),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ach.icon,
                  style: TextStyle(
                      fontSize: 22,
                      color: unlocked ? null : const Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(
                  ach.title,
                  style: TextStyle(
                    color: unlocked
                        ? Colors.white
                        : Colors.white24,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
