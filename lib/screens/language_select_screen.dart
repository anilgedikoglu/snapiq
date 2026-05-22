import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../widgets/animated_background.dart';
import 'home_screen.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  Future<void> _pick(BuildContext context, bool isEnglish) async {
    await LocaleService.instance.setEnglish(isEnglish);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / title
                  const Text(
                    'SnapIQ',
                    style: TextStyle(
                      color: Color(0xFF00B4FF),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [Shadow(color: Color(0xFF00B4FF), blurRadius: 24)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select language  •  Dil seç',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 56),

                  // ── Language buttons ──────────────────────────
                  Row(
                    children: [
                      Expanded(child: _LangButton(
                        flag: '🇹🇷',
                        label: 'Türkçe',
                        onTap: () => _pick(context, false),
                      )),
                      const SizedBox(width: 20),
                      Expanded(child: _LangButton(
                        flag: '🇬🇧',
                        label: 'English',
                        onTap: () => _pick(context, true),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatefulWidget {
  final String flag;
  final String label;
  final VoidCallback onTap;
  const _LangButton({required this.flag, required this.label, required this.onTap});

  @override
  State<_LangButton> createState() => _LangButtonState();
}

class _LangButtonState extends State<_LangButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF00B4FF).withValues(alpha: 0.18)
              : const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? const Color(0xFF00B4FF).withValues(alpha: 0.9)
                : const Color(0xFF00B4FF).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? [BoxShadow(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.25),
                  blurRadius: 20)]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.flag, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
