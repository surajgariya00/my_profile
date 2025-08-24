import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CursorTrailOverlay extends StatefulWidget {
  const CursorTrailOverlay({super.key, this.maxPoints = 110});
  final int maxPoints;

  @override
  State<CursorTrailOverlay> createState() => _CursorTrailOverlayState();
}

class _CursorTrailOverlayState extends State<CursorTrailOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _pts = <_TrailPoint>[];
  Offset _mouse = Offset.zero;
  bool _active = false;
  double _tLast = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (_tLast == 0) ? 0.016 : (t - _tLast).clamp(0.0, 0.033);
    _tLast = t;

    // Add a point if active
    if (_active) {
      _pts.add(_TrailPoint(_mouse, 1));
      if (_pts.length > widget.maxPoints) _pts.removeAt(0);
    }

    // Fade
    for (final p in _pts) {
      p.life -= dt * 0.9; // 1.1s full life roughly
    }
    _pts.removeWhere((p) => p.life <= 0);

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
      behavior: HitTestBehavior.translucent,
      onPointerHover: (e) {
        _active = true;
        _mouse = e.localPosition;
      },
      onPointerDown: (e) {
        _active = true;
        _mouse = e.localPosition;
      },
      onPointerMove: (e) {
        _mouse = e.localPosition;
      },
      onPointerUp: (_) {
        _active = false;
      },
      onPointerCancel: (_) {
        _active = false;
      },
      child: CustomPaint(painter: _TrailPainter(_pts)),
    );
  }
}

class _TrailPoint {
  _TrailPoint(this.pos, this.life);
  Offset pos;
  double life;
}

class _TrailPainter extends CustomPainter {
  final List<_TrailPoint> pts;
  _TrailPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;

    // Glow pass
    canvas.saveLayer(Offset.zero & size, Paint());
    final glow = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.08)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    final path = Path();
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      if (i == 0) path.moveTo(a.pos.dx, a.pos.dy);
      path.lineTo(b.pos.dx, b.pos.dy);
    }
    canvas.drawPath(path, glow);
    canvas.restore();

    // Core pass with per‑segment alpha + width
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final w = 6.0 * (a.life.clamp(0.0, 1.0)) + 1.5; // taper
      final p = Paint()
        ..color = Colors.white.withOpacity(0.65 * a.life.clamp(0.0, 1.0))
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(a.pos, b.pos, p);
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) => true;
}
