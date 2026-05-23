import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';
import '../models/game_session.dart';
import '../widgets/animated_background.dart';
import '../widgets/cin_host.dart';
import 'memory_test_screen.dart';
import 'stroop_test_screen.dart';
import 'impulse_test_screen.dart';
import 'sequence_test_screen.dart';

class BrainTrainingScreen extends StatefulWidget {
  const BrainTrainingScreen({super.key});

  @override
  State<BrainTrainingScreen> createState() => _BrainTrainingScreenState();
}

class _BrainTrainingScreenState extends State<BrainTrainingScreen> {
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
                    Text(S.brainTrainTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const CinHost(size: 80),
              const SizedBox(height: 8),
              Text(
                S.brainTrainPrompt,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _ModeCard(
                      emoji: '🧠',
                      title: 'Memory Blitz',
                      description: S.brainTrainMemDesc,
                      color: const Color(0xFFBB86FC),
                      bestScore: _storage == null
                          ? null
                          : _storage!.lastScores.isEmpty
                              ? null
                              : _storage!.lastScores.first.memoryScore,
                      onTap: () {
                        final session = GameSession();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemoryTestScreen(
                              session: session,
                              reactionScore: 0,
                              stroopScore: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ModeCard(
                      emoji: '🎨',
                      title: 'Speed Tap',
                      description: S.brainTrainStroopDesc,
                      color: const Color(0xFF1E88E5),
                      bestScore: _storage == null
                          ? null
                          : _storage!.lastScores.isEmpty
                              ? null
                              : _storage!.lastScores.first.stroopScore,
                      onTap: () {
                        final session = GameSession();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StroopTestScreen(
                              session: session,
                              reactionScore: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ModeCard(
                      emoji: '🎯',
                      title: 'Focus Hunter',
                      description:
                          S.brainTrainImpulseDesc,
                      color: const Color(0xFFFF7043),
                      bestScore: _storage == null
                          ? null
                          : _storage!.lastScores.isEmpty
                              ? null
                              : _storage!.lastScores.first.impulseScore,
                      onTap: () {
                        final session = GameSession();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImpulseTestScreen(
                              session: session,
                              reactionScore: 0,
                              stroopScore: 0,
                              memoryScore: 0,
                              sequenceScore: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ModeCard(
                      emoji: '🔢',
                      title: 'Number Rush',
                      description:
                          S.brainTrainSeqDesc,
                      color: const Color(0xFFFDD835),
                      bestScore: _storage == null
                          ? null
                          : _storage!.lastScores.isEmpty
                              ? null
                              : _storage!.lastScores.first.sequenceScore,
                      onTap: () {
                        final session = GameSession();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SequenceTestScreen(
                              session: session,
                              reactionScore: 0,
                              stroopScore: 0,
                              memoryScore: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final int? bestScore;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  if (bestScore != null) ...[
                    const SizedBox(height: 4),
                    Text(S.brainTrainBest(bestScore!),
                        style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 11)),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.6), size: 16),
          ],
        ),
      ),
    );
  }
}
