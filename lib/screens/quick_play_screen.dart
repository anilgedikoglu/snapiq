import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';
import 'reaction_test_screen.dart';

class QuickPlayScreen extends StatelessWidget {
  const QuickPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CinHost(size: 100),
                const SizedBox(height: 16),
                const Text(
                  'Hızlı Oyun',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Color(0xFF00B4FF), blurRadius: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '~20 saniyede hızlı bir beyin testi.',
                  style: TextStyle(color: Colors.white54, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF00B4FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt,
                          color: Color(0xFF00B4FF), size: 16),
                      SizedBox(width: 6),
                      Text('Reaksiyon Hızı',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      SizedBox(width: 16),
                      Icon(Icons.touch_app,
                          color: Color(0xFFBB86FC), size: 16),
                      SizedBox(width: 6),
                      Text('İmpuls Kontrolü',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                NeonButton(
                  text: 'Başla!',
                  onPressed: () {
                    final session = GameSession();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReactionTestScreen(session: session),
                      ),
                    );
                  },
                  color: const Color(0xFF00B4FF),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.play_arrow_rounded,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  text: 'Geri',
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white38,
                  width: double.infinity,
                  icon: Icons.arrow_back_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
