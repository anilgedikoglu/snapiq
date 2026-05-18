import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) setState(() => _storage = s);
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
                    const Text('İstatistikler',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_storage == null)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00B4FF))))
              else
                Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final s = _storage!;
    final history = s.gameHistory;
    final snapIQs = history
        .map((h) => (h['snapiq'] as num?)?.toDouble() ?? 0)
        .take(10)
        .toList()
        .reversed
        .toList();

    double? best, worst, avg;
    if (snapIQs.isNotEmpty) {
      best = snapIQs.reduce(max);
      worst = snapIQs.reduce(min);
      avg = snapIQs.reduce((a, b) => a + b) / snapIQs.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Son 10 Oyun – SnapIQ',
              style: TextStyle(
                  color: Color(0xFF00B4FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          if (snapIQs.isEmpty)
            const Text('Henüz oyun kaydı yok.',
                style: TextStyle(color: Colors.white38, fontSize: 14))
          else ...[
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _BarChartPainter(snapIQs),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _statChip('En İyi', best!.round().toString(),
                    const Color(0xFF00C853)),
                const SizedBox(width: 10),
                _statChip('Ortalama', avg!.toStringAsFixed(1),
                    const Color(0xFF00B4FF)),
                const SizedBox(width: 10),
                _statChip('En Düşük', worst!.round().toString(),
                    const Color(0xFFFF7043)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text('Genel',
              style: TextStyle(
                  color: Color(0xFF00B4FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          _infoRow('Toplam Oyun', '${s.totalGames}'),
          _infoRow('En İyi SnapIQ',
              s.bestReflexIQ > 0 ? '${s.bestReflexIQ}' : '--'),
          _infoRow('En İyi Bilişsel Yaş',
              s.bestCognitiveAge > 0 ? '${s.bestCognitiveAge}' : '--'),
          _infoRow('En İyi Reaksiyon',
              s.bestReactionMs > 0 ? '${s.bestReactionMs} ms' : '--'),
          _infoRow('Toplam Süre', '${s.totalTestTimeSecs} sn'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;

  _BarChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(max).clamp(1.0, double.infinity);
    final minVal = max(0.0, values.reduce(min) - 10);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final n = values.length;
    final barWidth = (size.width - 16) / n - 6;
    final paint = Paint()..style = PaintingStyle.fill;

    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < n; i++) {
      final barH = ((values[i] - minVal) / range * (size.height - 30))
          .clamp(4.0, size.height - 30);
      final x = i * ((size.width - 16) / n) + 8;
      final top = size.height - 20 - barH;

      paint.color = const Color(0xFF00B4FF).withValues(alpha: 0.7);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, barH),
          const Radius.circular(4),
        ),
        paint,
      );

      // Value label
      textPaint.text = TextSpan(
        text: values[i].round().toString(),
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      );
      textPaint.layout();
      textPaint.paint(
          canvas,
          Offset(x + barWidth / 2 - textPaint.width / 2,
              top - textPaint.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
