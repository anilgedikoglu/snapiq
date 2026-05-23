import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class PremiumHeader extends StatelessWidget {
  const PremiumHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SnapIQ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Color(0xFF00B4FF), blurRadius: 20),
                Shadow(color: Color(0xFF00B4FF), blurRadius: 40),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            S.widgetSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
