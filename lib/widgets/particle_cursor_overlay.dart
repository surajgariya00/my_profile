import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ParticleCursorOverlay extends StatefulWidget {
  const ParticleCursorOverlay({super.key, this.count = 240});
  final int count;

  @override
  State<ParticleCursorOverlay> createState() => _ParticleCursorOverlayState();
}

class _ParticleCursorOverlayState extends State<ParticleCursorOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final rnd = Random();
  late List<_P> ps;
  Offset mouse = Offset.zero;
  bool mouseActive = false;
  double lastTime = 0;

  @override
  void initState() {
    super.initState();
    ps = List.generate(widget.count, (i) => _P(rnd));
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (lastTime == 0) ? 0.016 : (t - lastTime).clamp(0.0, 0.033);
    lastTime = t;

    final size = context.size ?? Size.zero;
    final w = size.width, h = size.height;

    for (final p in ps) {
      final toMouse = mouse - p.pos;
      final d2 = toMouse.distanceSquared + 1;
      final near = d2 < 3500 ? -900 / d2 : 0; // mild repel when very close
      final attract = mouseActive ? 800 / d2 : 0; // soft attraction

      final ax =
          toMouse.dx * (attract + near) +
          (rnd.nextDouble() - .5) * 2.0; // jitter
      final ay = toMouse.dy * (attract + near) + (rnd.nextDouble() - .5) * 2.0;

      p.vx = (p.vx + ax * dt) * 0.94;
      p.vy = (p.vy + ay * dt) * 0.94;
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // wrap around edges for infinite space vibe
      if (p.x < -50) p.x = w + 50;
      if (p.x > w + 50) p.x = -50;
      if (p.y < -50) p.y = h + 50;
      if (p.y > h + 50) p.y = -50;
    }
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
      behavior: HitTestBehavior.translucent, // let clicks through
      onPointerHover: (e) {
        mouseActive = true;
        mouse = e.localPosition;
      },
      onPointerDown: (e) {
        mouseActive = true;
        mouse = e.localPosition;
      },
      onPointerMove: (e) {
        mouse = e.localPosition;
      },
      onPointerUp: (_) {
        mouseActive = false;
      },
      onPointerCancel: (_) {
        mouseActive = false;
      },
      child: CustomPaint(painter: _ParticlePainter(ps, mouse, mouseActive)),
    );
  }
}

class _P {
  late double x, y, vx, vy, r;
  _P(Random rnd) {
    x = rnd.nextDouble() * 1600 - 100;
    y = rnd.nextDouble() * 1200 - 100;
    vx = (rnd.nextDouble() - .5) * 40;
    vy = (rnd.nextDouble() - .5) * 40;
    r = rnd.nextDouble() * 1.8 + 0.8;
  }
  Offset get pos => Offset(x, y);
}

class _ParticlePainter extends CustomPainter {
  final List<_P> ps;
  final Offset mouse;
  final bool active;
  _ParticlePainter(this.ps, this.mouse, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    // glow layer
    canvas.saveLayer(Offset.zero & size, Paint());
    final pGlow = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final pDot = Paint()..color = Colors.white.withOpacity(0.5);

    for (final p in ps) {
      final o = Offset(p.x, p.y);
      canvas.drawCircle(o, 10 * p.r, pGlow);
    }
    canvas.restore();

    // crisp dots
    for (final p in ps) {
      final o = Offset(p.x, p.y);
      canvas.drawCircle(o, p.r, pDot);
    }

    // spotlight follows mouse
    if (active) {
      final rect = Offset.zero & size;
      final spot = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(.18), Colors.transparent],
        ).createShader(Rect.fromCircle(center: mouse, radius: 160));
      canvas.drawRect(rect, spot);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.ps != ps || old.mouse != mouse || old.active != active;
}
