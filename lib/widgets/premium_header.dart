import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';

class PremiumHeader extends StatelessWidget {
  final StorageService? storage;

  const PremiumHeader({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SnapIQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Color(0xFF00B4FF), blurRadius: 20),
                      Shadow(color: Color(0xFF00B4FF), blurRadius: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Refleksini, zamanlamanı ve odağını test et.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: level card
          if (storage != null) _buildLevelCard(storage!),
        ],
      ),
    );
  }

  Widget _buildLevelCard(StorageService s) {
    final level = s.level;
    final xpAtStart = XpService.xpAtLevelStart(level);
    final xpForLevel = XpService.xpForLevelUp(level);
    final xpInLevel = (s.xp - xpAtStart).clamp(0, xpForLevel);
    final progress = xpForLevel > 0 ? (xpInLevel / xpForLevel).clamp(0.0, 1.0) : 1.0;

    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBB86FC).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Seviye $level',
            style: const TextStyle(
              color: Color(0xFFBB86FC),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFBB86FC).withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFBB86FC)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${s.xp} XP',
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
