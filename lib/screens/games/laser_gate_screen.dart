import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/storage_service.dart';
import '../../services/xp_service.dart';
import '../../services/achievement_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/animated_background.dart';
import '../../l10n/app_strings.dart';
import '../../painters/laser_gate_painter.dart';

class LaserGateScreen extends StatefulWidget {
  const LaserGateScreen({super.key});

  @override
  State<LaserGateScreen> createState() => _LaserGateScreenState();
}

class _LaserGateScreenState extends State<LaserGateScreen>
    with TickerProviderStateMixin {
  static const _gameId = 'laser_gate';
  static const _xpReward = 40;
  static const _gameName = 'Laser Gate';

  // Ring speeds in rad/sec
  List<double> _ringSpeed = [0.96, -1.44, 2.0];
  late List<AnimationController> _ringCtrl;
  late AnimationController _impactCtrl;
  int _impactRing = -1;
  Ticker? _uiTicker;

  int _ballRing = 0;
  bool _canTap = true;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  bool _gameEnded = false;
  bool _completed = false;

  final Stopwatch _stopwatch = Stopwatch();
  int _displayMs = 0;

  static const double _tolerance = 25 * pi / 180;

  // Score: ≤3s→100, ≥25s→0, linear
  static int _timeScore(int ms) =>
      ((25000 - ms) / 22000.0 * 100).round().clamp(0, 100);

  @override
  void initState() {
    super.initState();
    _impactCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _initControllers();
    _stopwatch.start();
    _uiTicker = createTicker((_) {
      if (mounted && !_completed) {
        setState(() => _displayMs = _stopwatch.elapsedMilliseconds);
      }
    })..start();
  }

  void _initControllers() {
    _ringCtrl = List.generate(3, (i) {
      final speed = _ringSpeed[i].abs();
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (2000 / speed).round()),
      );
      ctrl.repeat();
      return ctrl;
    });
  }

  double _ringAngle(int i) {
    final value = _ringCtrl[i].value;
    return _ringSpeed[i] >= 0 ? value * 2 * pi : (1 - value) * 2 * pi;
  }

  bool _isGapAtTop(int ringIndex) {
    final angle = _ringAngle(ringIndex) % (2 * pi);
    return angle.abs() < _tolerance || (angle - 2 * pi).abs() < _tolerance;
  }

  void _onTap() {
    if (!_canTap || _gameEnded || _ballRing >= 3) return;
    _canTap = false;

    final targetRing = _ballRing;
    if (_isGapAtTop(targetRing)) {
      setState(() {
        _ballRing++;
        _feedback = S.laserPassed(_ballRing - 1);
        _feedbackColor = const Color(0xFF00C853);
        _showFeedback = true;
      });

      if (_ballRing >= 3) {
        _stopwatch.stop();
        _completed = true;
        final ms = _stopwatch.elapsedMilliseconds;
        setState(() => _displayMs = ms);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _gameOver(ms, _timeScore(ms));
        });
      } else {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() { _showFeedback = false; _canTap = true; });
        });
      }
    } else {
      // Hit barrier — show impact on the ring, reset to center
      _impactRing = targetRing;
      _impactCtrl.forward(from: 0);
      setState(() {
        _ballRing = 0;
        _feedback = S.laserHitMsg;
        _feedbackColor = const Color(0xFFFF7043);
        _showFeedback = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _showFeedback = false; _canTap = true; });
      });
    }
  }

  Future<void> _gameOver(int ms, int score) async {
    setState(() => _gameEnded = true);
    final s = await StorageService.getInstance();
    final prevBestMs = s.bestLaserGateMs;
    final isNewBest = prevBestMs == 0 || ms < prevBestMs;
    await s.saveBestLaserGateMs(ms);
    await s.saveArcadeBestScore(_gameId, score); // for achievements
    await s.saveXP(_xpReward);
    final newLevel = XpService.levelForXp(s.xp);
    await s.saveLevel(newLevel);
    await AchievementService.checkArcadeAchievements(_gameId, score, s);
    await AdService().incrementGameCountAndMaybeShow();
    if (!mounted) return;
    _showTimeDialog(ms, isNewBest, prevBestMs);
  }

  void _showTimeDialog(int ms, bool isNewBest, int prevBestMs) {
    final timeStr = (ms / 1000).toStringAsFixed(2);
    final bestStr = prevBestMs > 0
        ? (prevBestMs / 1000).toStringAsFixed(2)
        : timeStr;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_gameName,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              if (isNewBest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDD835).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(S.newRecord,
                      style: const TextStyle(
                          color: Color(0xFFFDD835),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              const SizedBox(height: 12),
              // Big time display
              Text('${timeStr}s',
                  style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 52,
                      fontWeight: FontWeight.bold)),
              Text('${S.best}: ${bestStr}s',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+$_xpReward XP',
                    style: const TextStyle(
                        color: Color(0xFFBB86FC),
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(S.exit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(context); _restart(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(S.again),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restart() {
    for (final c in _ringCtrl) { c.dispose(); }
    _ringSpeed = [0.96, -1.44, 2.0];
    _initControllers();
    _impactCtrl.stop();
    _impactRing = -1;
    _stopwatch..reset()..start();
    setState(() {
      _ballRing = 0;
      _canTap = true;
      _feedback = '';
      _showFeedback = false;
      _gameEnded = false;
      _completed = false;
      _displayMs = 0;
    });
  }

  @override
  void dispose() {
    _uiTicker?.dispose();
    _impactCtrl.dispose();
    for (final c in _ringCtrl) { c.dispose(); }
    super.dispose();
  }

  String get _timeDisplay {
    final s = _displayMs ~/ 1000;
    final cs = (_displayMs % 1000) ~/ 10; // centiseconds
    return '${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _completed
        ? const Color(0xFF00C853)
        : const Color(0xFF00E5FF);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                _buildHeader(),
                // Big running timer
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _timeDisplay,
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: timerColor, blurRadius: 18)],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([..._ringCtrl, _impactCtrl]),
                        builder: (ctx, _) => CustomPaint(
                          painter: LaserGatePainter(
                            angles: List.generate(3, _ringAngle),
                            ballRing: _ballRing,
                            lives: 3,
                            score: 0,
                            impactRing: _impactRing,
                            impactGlow: 1.0 - _impactCtrl.value,
                          ),
                          size: const Size(400, 400),
                        ),
                      ),
                      if (_showFeedback)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _feedback,
                              style: TextStyle(
                                color: _feedbackColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: _feedbackColor, blurRadius: 20)
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    S.laserGateHint,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Laser Gate',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
