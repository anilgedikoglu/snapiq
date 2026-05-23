import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/game_session.dart';
import '../models/test_result.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/cin_host.dart';
import 'reaction_test_screen.dart';
import 'vs_friend_result_screen.dart';

/// Hosts a two-player vs session. Player 1 plays, then hands off to Player 2.
class VsFriendScreen extends StatefulWidget {
  const VsFriendScreen({super.key});

  @override
  State<VsFriendScreen> createState() => _VsFriendScreenState();
}

enum _VsPhase { intro, player1Playing, handoff, player2Playing }

class _VsFriendScreenState extends State<VsFriendScreen> {
  _VsPhase _phase = _VsPhase.intro;
  TestResult? _p1Result;

  void _startPlayer1() {
    setState(() => _phase = _VsPhase.player1Playing);
    final session = GameSession();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReactionTestScreen(session: session),
      ),
    ).then((result) {
      if (result is TestResult) {
        setState(() {
          _p1Result = result;
          _phase = _VsPhase.handoff;
        });
      } else {
        // If result not passed (normal flow ends at ResultScreen), pop to intro
        setState(() => _phase = _VsPhase.intro);
      }
    });
  }

  void _startPlayer2() {
    setState(() => _phase = _VsPhase.player2Playing);
    final session = GameSession();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReactionTestScreen(session: session),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result is TestResult && _p1Result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VsFriendResultScreen(
              p1Result: _p1Result!,
              p2Result: result,
            ),
          ),
        );
      } else {
        setState(() => _phase = _VsPhase.intro);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _VsPhase.intro:
        return _buildIntro();
      case _VsPhase.player1Playing:
        return _buildWaiting(S.playerN(1) + '...');
      case _VsPhase.handoff:
        return _buildHandoff();
      case _VsPhase.player2Playing:
        return _buildWaiting(S.playerN(2) + '...');
    }
  }

  Widget _buildIntro() {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CinHost(size: 100),
                const SizedBox(height: 20),
                Text(
                  S.vsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                          color: Color(0xFFBB86FC), blurRadius: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  S.vsSubtitle,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                NeonButton(
                  text: S.vsP1Play,
                  onPressed: _startPlayer1,
                  color: const Color(0xFFBB86FC),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.person,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  text: S.back,
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white38,
                  width: double.infinity,
                  icon: Icons.arrow_back_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandoff() {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CinHost(size: 100),
                const SizedBox(height: 24),
                Text(
                  S.vsGive,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  S.vsCanBeat,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  S.yourSnapIQ(_p1Result?.reflexIQ ?? 0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFBB86FC), fontSize: 14),
                ),
                const SizedBox(height: 40),
                NeonButton(
                  text: S.vsP2Play,
                  onPressed: _startPlayer2,
                  color: const Color(0xFF00B4FF),
                  width: double.infinity,
                  height: 60,
                  icon: Icons.play_arrow_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting(String msg) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: Text(msg,
              style: const TextStyle(color: Colors.white54, fontSize: 18)),
        ),
      ),
    );
  }
}
