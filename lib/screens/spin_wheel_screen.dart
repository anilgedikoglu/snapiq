import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _Segment {
  final String label;
  final Color color;
  final int xpReward;
  final String? themeUnlock;

  const _Segment({
    required this.label,
    required this.color,
    required this.xpReward,
    this.themeUnlock,
  });
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;
  StorageService? _storage;
  bool _alreadySpun = false;
  bool _spinning = false;
  int? _resultIndex;
  double _finalAngle = 0;

  static const List<_Segment> _segments = [
    _Segment(label: '+50 XP', color: Color(0xFF00B4FF), xpReward: 50),
    _Segment(label: '+100 XP', color: Color(0xFF00C853), xpReward: 100),
    _Segment(label: '+200 XP', color: Color(0xFFBB86FC), xpReward: 200),
    _Segment(label: '+30 XP', color: Color(0xFF03DAC6), xpReward: 30),
    _Segment(
        label: 'Tema',
        color: Color(0xFFFF7043),
        xpReward: 0,
        themeUnlock: 'sunset'),
    _Segment(label: 'Rozet 🏅', color: Color(0xFFFDD835), xpReward: 75),
    _Segment(label: '+75 XP', color: Color(0xFF7B2FBE), xpReward: 75),
    _Segment(label: 'Bonus 🎁', color: Color(0xFFE91E63), xpReward: 150),
  ];

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) {
      setState(() {
        _storage = s;
        _alreadySpun = s.spinWheelLastDate == _todayStr;
      });
    }
  }

  Future<void> _spin() async {
    if (_spinning || _alreadySpun || _storage == null) return;
    setState(() => _spinning = true);

    final rand = Random();
    final targetIndex = rand.nextInt(_segments.length);
    final segmentAngle = 2 * pi / _segments.length;

    // Land on target segment center
    final targetAngle = 4 * 2 * pi +
        (2 * pi - (targetIndex * segmentAngle + segmentAngle / 2));

    setState(() => _finalAngle = _finalAngle + targetAngle);

    _ctrl.duration = const Duration(milliseconds: 3500);
    _animation = Tween<double>(
      begin: _finalAngle - targetAngle,
      end: _finalAngle,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.decelerate));

    await _ctrl.forward(from: 0);

    // Apply reward
    final seg = _segments[targetIndex];
    if (seg.xpReward > 0) {
      await _storage!.saveXP(seg.xpReward);
    }
    if (seg.themeUnlock != null) {
      await _storage!.unlockTheme(seg.themeUnlock!);
    }
    await _storage!.saveSpinWheelDate(_todayStr);

    if (mounted) {
      setState(() {
        _spinning = false;
        _alreadySpun = true;
        _resultIndex = targetIndex;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
                    const Text('Çark Çevir',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const CinHost(size: 80),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWheel(),
                      const SizedBox(height: 24),
                      if (_resultIndex != null && _alreadySpun)
                        _buildResult(),
                      if (_alreadySpun && _resultIndex == null)
                        const Text(
                          'Bugün zaten çevirdin!\nYarın tekrar gel.',
                          style: TextStyle(
                              color: Color(0xFF03DAC6), fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),
                      if (!_alreadySpun || _resultIndex == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: NeonButton(
                            text: _alreadySpun
                                ? 'Yarın Tekrar Gel'
                                : 'ÇEVİR!',
                            onPressed: _alreadySpun ? () {} : _spin,
                            color: _alreadySpun
                                ? Colors.white38
                                : const Color(0xFFBB86FC),
                            width: double.infinity,
                            height: 56,
                            icon: Icons.casino_rounded,
                          ),
                        ),
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

  Widget _buildWheel() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final angle = _ctrl.isAnimating ? _animation.value : _finalAngle;
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _WheelPainter(_segments),
              ),
            ),
            // Pointer triangle
            const Positioned(
              top: 0,
              child: Icon(Icons.arrow_drop_down,
                  color: Colors.white, size: 36),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResult() {
    final seg = _segments[_resultIndex!];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: seg.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: seg.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Kazandın: ${seg.label}',
            style: TextStyle(
                color: seg.color,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          if (seg.xpReward > 0)
            Text('+${seg.xpReward} XP hesabına eklendi',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13)),
          if (seg.themeUnlock != null)
            const Text('Yeni tema kilidi açıldı!',
                style: TextStyle(
                    color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;

  _WheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final n = segments.length;
    final segAngle = 2 * pi / n;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black38
      ..strokeWidth = 1;

    for (int i = 0; i < n; i++) {
      final startAngle = i * segAngle - pi / 2;
      paint.color = segments[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        segAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        segAngle,
        true,
        borderPaint,
      );

      // Label
      final midAngle = startAngle + segAngle / 2;
      final textR = r * 0.65;
      final tx = cx + textR * cos(midAngle);
      final ty = cy + textR * sin(midAngle);

      final tp = TextPainter(
        text: TextSpan(
          text: segments[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(midAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    final centerPaint = Paint()
      ..color = const Color(0xFF0D1B2A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 20, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
