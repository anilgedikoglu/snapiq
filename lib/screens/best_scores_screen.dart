import 'dart:math';
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
  int _totalPlayers = 0;
  int _myRank       = 0;

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) {
      if (!mounted) return;
      final rand = Random();
      // Total "players": base 21 000, varies ±3 000 every open
      final total = 18000 + rand.nextInt(6001); // 18 000–24 000
      final rank  = _fakeRank(s.bestReflexIQ, total, rand);
      setState(() {
        _storage      = s;
        _totalPlayers = total;
        _myRank       = rank;
      });
    });
  }

  /// Maps a SnapIQ score (58–133) to a believable fake rank.
  /// Uses a sigmoid so mid-range scores cluster in the middle,
  /// and exceptional scores land near the top.
  static int _fakeRank(int iq, int total, Random rand) {
    if (iq <= 0) return total; // no test played yet
    // Fraction of players who scored BETTER than me
    // sigmoid centred at IQ 85: when iq=85 → 50 %, iq=133 → ~1 %
    final betterFraction = 1.0 / (1.0 + exp((iq - 85) * 0.10));
    final base = (betterFraction * total).round().clamp(1, total - 1);
    // ± 9 % jitter (min ±40) so the number looks organic
    final jitter = max(40, (base * 0.09).round());
    return (base + rand.nextInt(jitter * 2 + 1) - jitter).clamp(1, total - 1);
  }

  /// Turkish thousand-separator (dot): 22341 → "22.341"
  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
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

          const SizedBox(height: 28),

          // ── Global ranking section ──────────────────────────────
          _buildGlobalRanking(s.bestReflexIQ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGlobalRanking(int bestIQ) {
    final hasScore = bestIQ > 0;
    // percentage of the ranking list ABOVE the player
    final topPercent = hasScore
        ? ((_myRank / _totalPlayers) * 100).round().clamp(1, 99)
        : null;
    // filled fraction for the progress bar (higher = better rank)
    final barValue =
        hasScore ? (1.0 - _myRank / _totalPlayers).clamp(0.02, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFBB86FC).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.public_rounded,
                  color: Color(0xFFBB86FC), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Tüm Oyuncular',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Toplam: ${_fmt(_totalPlayers)} kişi',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!hasScore) ...[
            const Text(
              'İlk testini tamamla ve sıralamanı gör!',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ] else ...[
            // Bar showing relative position
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: barValue,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFBB86FC)),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('En İyi',
                    style: TextStyle(color: Colors.white24, fontSize: 10)),
                const Text('En Kötü',
                    style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),

            const SizedBox(height: 14),

            // Rank + badge row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sen',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    Text(
                      '#${_fmt(_myRank)}',
                      style: const TextStyle(
                        color: Color(0xFFBB86FC),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              color: Color(0xFFBB86FC), blurRadius: 10)
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _TopBadge(topPercent: topPercent!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Top-% badge ──────────────────────────────────────────────────────────────
class _TopBadge extends StatelessWidget {
  final int topPercent;
  const _TopBadge({required this.topPercent});

  @override
  Widget build(BuildContext context) {
    final Color col;
    final String label;
    if (topPercent <= 5) {
      col = const Color(0xFFFDD835);
      label = 'İlk %$topPercent 🏆';
    } else if (topPercent <= 15) {
      col = const Color(0xFF00C853);
      label = 'İlk %$topPercent 🥇';
    } else if (topPercent <= 35) {
      col = const Color(0xFF00B4FF);
      label = 'İlk %$topPercent';
    } else {
      col = Colors.white38;
      label = 'İlk %$topPercent';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: col.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: col, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── BigStat card ─────────────────────────────────────────────────────────────
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
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
