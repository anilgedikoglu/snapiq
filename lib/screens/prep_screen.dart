import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';
import 'reaction_test_screen.dart';

class PrepScreen extends StatefulWidget {
  const PrepScreen({super.key});

  @override
  State<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends State<PrepScreen>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _chevronCtrl;
  late final Animation<double> _chevronTurn;

  static const _tests = [
    (1,  'Reaksiyon Hızı',  Icons.bolt),
    (2,  'Stroop Renk',     Icons.color_lens),
    (3,  'Hafıza Kutuları', Icons.grid_view),
    (4,  'Sayı Sıralama',   Icons.sort),
    (5,  'İmpuls Kontrolü', Icons.touch_app),
    (6,  'Pattern IQ',      Icons.pattern),
    (7,  'Çember Refleks',  Icons.radio_button_unchecked),
    (8,  'Laser Gate',      Icons.track_changes),
    (9,  'Timing Stack',    Icons.stacked_bar_chart),
    (10, 'Pulse Stop',      Icons.radio_button_checked),
    (11, 'Balance Bar',     Icons.horizontal_rule),
    (12, 'Dart Focus',      Icons.adjust),
    (13, 'Sky Shot',        Icons.rocket_launch),
    (14, 'Target Lock',     Icons.radar),
    (15, 'Swipe Dodge',     Icons.swipe),
    (16, 'Color Panic',     Icons.palette),
    (17, "Don't Tap Red",   Icons.do_not_touch),
    (18, 'Tap Target',      Icons.my_location),
    (19, 'Shape Strike',    Icons.category),
    (20, 'Memory Flash',    Icons.grid_view),
    (21, 'Mirror Brain',    Icons.compare_arrows),
    (22, 'Sequence Rush',   Icons.format_list_numbered),
    (23, 'Reaction Wall',   Icons.view_column),
    (24, 'Focus Hunter',    Icons.search),
    (25, 'Impulse Ctrl',    Icons.stop_circle_outlined),
    (26, 'Tap Rain',        Icons.grain),
    (27, 'Speed Math',      Icons.calculate),
    (28, 'Number Hunter',   Icons.tag),
    (29, 'Pattern Master',  Icons.pattern),
  ];

  static const _visibleCount = 3;

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _chevronTurn =
        Tween<double>(begin: 0, end: 0.5).animate(_chevronCtrl);
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _chevronCtrl.forward() : _chevronCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final session = GameSession();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Scrollable content ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(height: 8),
                      const Text(
                        'Hazır olduğunda başla.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Test list ──────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF00B4FF)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            // Always-visible first 3
                            ...List.generate(_visibleCount, (i) {
                              final t = _tests[i];
                              return _TestListItem(
                                  n: t.$1, name: t.$2, icon: t.$3,
                                  isLast: !_expanded && i == _visibleCount - 1);
                            }),

                            // Expandable remainder
                            AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                              child: _expanded
                                  ? Column(
                                      children: List.generate(
                                          _tests.length - _visibleCount,
                                          (i) {
                                        final t = _tests[_visibleCount + i];
                                        return _TestListItem(
                                            n: t.$1, name: t.$2, icon: t.$3,
                                            isLast: i ==
                                                _tests.length -
                                                    _visibleCount -
                                                    1);
                                      }),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Expand / collapse arrow
                            GestureDetector(
                              onTap: _toggle,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4FF)
                                      .withValues(alpha: 0.06),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(14)),
                                ),
                                child: Center(
                                  child: RotationTransition(
                                    turns: _chevronTurn,
                                    child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFF00B4FF),
                                        size: 26),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Fixed Başla band ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF050A14),
                  border: Border(
                    top: BorderSide(
                        color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                        width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
                child: NeonButton(
                  text: 'Başla!',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReactionTestScreen(session: session),
                    ),
                  ),
                  color: const Color(0xFF00B4FF),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Test list row ─────────────────────────────────────────────────────────────
class _TestListItem extends StatelessWidget {
  final int n;
  final String name;
  final IconData icon;
  final bool isLast;

  const _TestListItem(
      {required this.n,
      required this.name,
      required this.icon,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: const Color(0xFF00B4FF).withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                '$n',
                style: const TextStyle(
                    color: Color(0xFF00B4FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Text(name,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
