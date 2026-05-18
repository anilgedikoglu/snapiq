import 'package:flutter/material.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const CountdownOverlay({super.key, required this.onDone});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  int _count = 3;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 1.5, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _tick();
  }

  void _tick() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _count = i);
      _ctrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 900));
    }
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Text(
            '$_count',
            style: const TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00B4FF),
              shadows: [
                Shadow(color: Color(0xFF00B4FF), blurRadius: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
