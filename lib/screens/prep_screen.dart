import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';
import 'reaction_test_screen.dart';

class PrepScreen extends StatelessWidget {
  const PrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = GameSession();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cin as host presenting the tests
                const CinHost(size: 120),
                const SizedBox(height: 16),
                const Text(
                  '29 kısa test seni bekliyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hazır olduğunda başla.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                _TestListItem(n: 1, name: 'Reaksiyon Hızı', icon: Icons.bolt),
                _TestListItem(n: 2, name: 'Stroop Renk', icon: Icons.color_lens),
                _TestListItem(n: 3, name: 'Hafıza Kutuları', icon: Icons.grid_view),
                _TestListItem(n: 4, name: 'Sayı Sıralama', icon: Icons.sort),
                _TestListItem(n: 5, name: 'İmpuls Kontrolü', icon: Icons.touch_app),
                _TestListItem(n: 6, name: 'Pattern IQ', icon: Icons.pattern),
                _TestListItem(n: 7, name: 'Çember Refleks', icon: Icons.radio_button_unchecked),
                _TestListItem(n: 8, name: 'Laser Gate', icon: Icons.track_changes),
                _TestListItem(n: 9,  name: 'Timing Stack', icon: Icons.stacked_bar_chart),
                _TestListItem(n: 10, name: 'Pulse Stop',   icon: Icons.radio_button_checked),
                _TestListItem(n: 11, name: 'Balance Bar',  icon: Icons.horizontal_rule),
                _TestListItem(n: 12, name: 'Dart Focus',   icon: Icons.adjust),
                _TestListItem(n: 13, name: 'Sky Shot',      icon: Icons.rocket_launch),
                _TestListItem(n: 14, name: 'Target Lock',   icon: Icons.radar),
                _TestListItem(n: 15, name: 'Swipe Dodge',   icon: Icons.swipe),
                _TestListItem(n: 16, name: 'Color Panic',      icon: Icons.palette),
                _TestListItem(n: 17, name: "Don't Tap Red",   icon: Icons.do_not_touch),
                _TestListItem(n: 18, name: 'Tap Target',       icon: Icons.my_location),
                _TestListItem(n: 19, name: 'Shape Strike',     icon: Icons.category),
                _TestListItem(n: 20, name: 'Memory Flash',    icon: Icons.grid_view),
                _TestListItem(n: 21, name: 'Mirror Brain',    icon: Icons.compare_arrows),
                _TestListItem(n: 22, name: 'Sequence Rush',   icon: Icons.format_list_numbered),
                _TestListItem(n: 23, name: 'Reaction Wall',   icon: Icons.view_column),
                _TestListItem(n: 24, name: 'Focus Hunter',    icon: Icons.search),
                _TestListItem(n: 25, name: 'Impulse Ctrl',    icon: Icons.stop_circle_outlined),
                _TestListItem(n: 26, name: 'Tap Rain',        icon: Icons.grain),
                _TestListItem(n: 27, name: 'Speed Math',      icon: Icons.calculate),
                _TestListItem(n: 28, name: 'Number Hunter',   icon: Icons.tag),
                _TestListItem(n: 29, name: 'Pattern Master',  icon: Icons.pattern),
                const SizedBox(height: 36),
                NeonButton(
                  text: 'Başla!',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReactionTestScreen(session: session),
                    ),
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

class _TestListItem extends StatelessWidget {
  final int n;
  final String name;
  final IconData icon;

  const _TestListItem({required this.n, required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                '$n',
                style: const TextStyle(
                    color: Color(0xFF00B4FF), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(name,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
