import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LaserRibbonOverlay extends StatefulWidget {
  const LaserRibbonOverlay({super.key});

  @override
  State<LaserRibbonOverlay> createState() => _LaserRibbonOverlayState();
}

class _LaserRibbonOverlayState extends State<LaserRibbonOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Node> _pts = <_Node>[];
  Offset _mouse = Offset.zero;
  bool _active = false;
  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0.0, 0.033);
    _lastTime = t;

    // spawn a point toward mouse when active for smoothness
    if (_active) {
      final prev = _pts.isEmpty ? _mouse : _pts.last.p;
      final next = Offset.lerp(prev, _mouse, 0.4)!;
      _pts.add(_Node(next));
    }

    // age and trim
    for (final n in _pts) {
      n.age += dt;
    }
    while (_pts.length > 160) {
      _pts.removeAt(0);
    }
    _pts.removeWhere((n) => n.age > 1.2); // ~1.2s trail

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent, // lets clicks pass through
      onPointerHover: (e) {
        _active = true;
        _mouse = e.localPosition;
      },
      onPointerMove: (e) {
        _active = true;
        _mouse = e.localPosition;
      },
      onPointerDown: (e) {
        _active = true;
        _mouse = e.localPosition;
      },
      onPointerUp: (_) {
        _active = false;
      },
      onPointerCancel: (_) {
        _active = false;
      },
      child: CustomPaint(painter: _RibbonPainter(_pts)),
    );
  }
}

class _Node {
  Offset p;
  double age = 0;
  _Node(this.p);
}

class _RibbonPainter extends CustomPainter {
  final List<_Node> pts;
  _RibbonPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;

    // Draw into a plus-blend layer for additive glow
    final rec = Offset.zero & size;
    canvas.saveLayer(rec, Paint());

    for (int i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final t = i / (pts.length - 1);
      final hue = (200 + 140 * t) % 360; // cyan->magenta
      final col = HSLColor.fromAHSL(1, hue, .85, .55).toColor();
      final life = (1.0 - b.age / 1.2).clamp(0.0, 1.0);
      final thickness = 10.0 * (1 - t) + 2.0; // taper

      // glow halo
      final glow = Paint()
        ..color = col.withOpacity(.08 * life)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
        ..strokeWidth = thickness * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a.p, b.p, glow);

      // core stroke
      final core = Paint()
        ..color = col.withOpacity(.9 * life)
        ..blendMode = BlendMode.plus
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a.p, b.p, core);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) => true;
}
