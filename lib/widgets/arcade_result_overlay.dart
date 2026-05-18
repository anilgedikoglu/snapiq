import 'package:flutter/material.dart';

/// Shown as a Dialog when an arcade game ends.
class ArcadeResultOverlay extends StatelessWidget {
  final String gameName;
  final int score;
  final int bestScore;
  final int xpGained;
  final bool isNewBest;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  const ArcadeResultOverlay({
    super.key,
    required this.gameName,
    required this.score,
    required this.bestScore,
    required this.xpGained,
    required this.isNewBest,
    required this.onReplay,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(gameName,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            if (isNewBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD835).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏆 Yeni Rekor!',
                    style: TextStyle(
                        color: Color(0xFFFDD835),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Text('$score',
                style: const TextStyle(
                    color: Color(0xFF00B4FF),
                    fontSize: 56,
                    fontWeight: FontWeight.bold)),
            Text('En İyi: $bestScore',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+$xpGained XP',
                  style: const TextStyle(
                      color: Color(0xFFBB86FC),
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Çıkış'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReplay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tekrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
