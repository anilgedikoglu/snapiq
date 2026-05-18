import 'package:flutter/material.dart';

/// Cin karakterini belirli ekranlarda "sunucu" olarak gösteren widget.
/// frame_0001.png ... frame_0039.png sırasıyla oynatılır.
class CinHost extends StatefulWidget {
  final double size;

  const CinHost({super.key, this.size = 100});

  @override
  State<CinHost> createState() => _CinHostState();
}

class _CinHostState extends State<CinHost> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _frame = 1;
  static const int _totalFrames = 39;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalFrames * (1000 ~/ 3))),
    )..addListener(() {
        final f =
            (_ctrl.value * _totalFrames).floor().clamp(0, _totalFrames - 1) + 1;
        if (f != _frame) setState(() => _frame = f);
      })
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _framePath {
    final n = _frame.toString().padLeft(4, '0');
    return 'assets/cin_frames/frame_$n.png';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image.asset(
        _framePath,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}
