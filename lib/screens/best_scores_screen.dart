import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';

class BestScoresScreen extends StatefulWidget {
  const BestScoresScreen({super.key});

  @override
  State<BestScoresScreen> createState() => _BestScoresScreenState();
}

class _BestScoresScreenState extends State<BestScoresScreen> {
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) {
      if (mounted) setState(() => _storage = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
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
                    const Text(
                      'En İyi Skorlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Top stats
          Row(
            children: [
              _BigStat(
                label: 'En İyi SnapIQ',
                value: s.bestReflexIQ == 0 ? '--' : '${s.bestReflexIQ}',
                color: const Color(0xFF00B4FF),
              ),
              const SizedBox(width: 12),
              _BigStat(
                label: 'En İyi Bilişsel Yaş',
                value: s.bestCognitiveAge == 0
                    ? '--'
                    : '${s.bestCognitiveAge}',
                color: const Color(0xFF03DAC6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BigStat(
            label: 'Toplam Test',
            value: '${s.totalGames}',
            color: const Color(0xFFBB86FC),
            fullWidth: true,
          ),
          const SizedBox(height: 24),
          // Last 5 scores
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Son 5 Oyun',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          if (s.lastScores.isEmpty)
            const Text(
              'Henüz oyun oynanmadı.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            )
          else
            ...s.lastScores.asMap().entries.map((e) {
              final idx = e.key;
              final r = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00B4FF).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                              color: Color(0xFF00B4FF),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SnapIQ: ${r.reflexIQ}  •  Yaş: ${r.cognitiveAge}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            r.label,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${r.finalScore.round()}',
                      style: const TextStyle(
                          color: Color(0xFF00B4FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _BigStat({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = fullWidth ? double.infinity : null;
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
