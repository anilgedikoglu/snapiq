import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';
import 'reaction_test_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  StorageService? _storage;
  bool _alreadyPlayed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) {
      setState(() {
        _storage = s;
        _alreadyPlayed = s.dailyChallengeLastDate == _todayStr;
      });
    }
  }

  Future<void> _startChallenge() async {
    if (_storage == null) return;
    await _storage!.saveDailyChallengeDate(_todayStr);
    await AchievementService.unlockDailyDone(_storage!);
    if (!mounted) return;
    final session = GameSession();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReactionTestScreen(session: session),
      ),
    ).then((_) => _load());
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
                    Text(S.dailyTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CinHost(size: 100),
                      const SizedBox(height: 20),
                      Text(
                        S.dailyTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (_alreadyPlayed) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03DAC6)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF03DAC6)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                S.dailyPlayed,
                                style: const TextStyle(
                                    color: Color(0xFF03DAC6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              if (_storage != null &&
                                  _storage!.dailyChallengeBestScore > 0)
                                Text(
                                  S.dailyBest(_storage!.dailyChallengeBestScore),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          S.dailyTomorrow,
                          style:
                              const TextStyle(color: Colors.white38, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          S.dailyCTA,
                          style:
                              const TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        NeonButton(
                          text: S.dailyStartBtn,
                          onPressed: _startChallenge,
                          color: const Color(0xFF03DAC6),
                          width: double.infinity,
                          height: 60,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ],
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
