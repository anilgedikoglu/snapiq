import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../widgets/animated_background.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 20),
                    ),
                    Text(
                      S.howTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7043).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFFF7043)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          S.howDisclaimer,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        icon: Icons.bolt,
                        color: const Color(0xFF00C853),
                        title: S.how1Title,
                        body: S.how1Body,
                      ),
                      _Section(
                        icon: Icons.color_lens,
                        color: const Color(0xFF1E88E5),
                        title: S.how2Title,
                        body: S.how2Body,
                      ),
                      _Section(
                        icon: Icons.grid_view,
                        color: const Color(0xFFBB86FC),
                        title: S.how3Title,
                        body: S.how3Body,
                      ),
                      _Section(
                        icon: Icons.sort,
                        color: const Color(0xFFFDD835),
                        title: S.how4Title,
                        body: S.how4Body,
                      ),
                      _Section(
                        icon: Icons.touch_app,
                        color: const Color(0xFFFF7043),
                        title: S.how5Title,
                        body: S.how5Body,
                      ),
                      _Section(
                        icon: Icons.pattern,
                        color: const Color(0xFF03DAC6),
                        title: S.how6Title,
                        body: S.how6Body,
                      ),
                      const SizedBox(height: 24),
                      const _ScoreInfo(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreInfo extends StatelessWidget {
  const _ScoreInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00B4FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00B4FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.howScoreTitle,
              style: const TextStyle(
                  color: Color(0xFF00B4FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            S.howScoreBody,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
