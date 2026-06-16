import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Set<String> _unlocked = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) {
      setState(() => _unlocked = s.unlockedAchievements.toSet());
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
                    Text(S.achievementsTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      '${_unlocked.length}/${Achievement.all.length}',
                      style: const TextStyle(
                          color: Color(0xFF00B4FF), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: Achievement.all.length,
                  itemBuilder: (_, i) {
                    final ach = Achievement.all[i];
                    final unlocked = _unlocked.contains(ach.id);
                    return _AchievementCard(
                        ach: ach, unlocked: unlocked);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement ach;
  final bool unlocked;

  const _AchievementCard({required this.ach, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color =
        unlocked ? const Color(0xFF00B4FF) : Colors.white24;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFF00B4FF).withValues(alpha: 0.10)
            : const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? const Color(0xFF00B4FF).withValues(alpha: 0.5)
              : Colors.white12,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
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
                fontSize: 28,
                color: unlocked ? null : const Color(0xFF2A2A2A)),
          ),
          const SizedBox(height: 6),
          Text(
            S.achTitle(ach.id),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            S.achDesc(ach.id),
            style: TextStyle(
              color: unlocked ? Colors.white60 : Colors.white24,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (unlocked) ...[
            const SizedBox(height: 4),
            Text('+${ach.xpReward} XP',
                style: const TextStyle(
                    color: Color(0xFFBB86FC), fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
