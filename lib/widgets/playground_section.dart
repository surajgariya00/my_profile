import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../widgets/section_title.dart';

class PlaygroundSection extends StatefulWidget {
  const PlaygroundSection({super.key});

  @override
  State<PlaygroundSection> createState() => _PlaygroundSectionState();
}

class _PlaygroundSectionState extends State<PlaygroundSection>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final rnd = Random();
  final orbs = <_Orb>[];
  final confetti = <_Confetti>[];
  Size size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _spawn() {
    orbs.add(_Orb.random(size, rnd));
  }

  void _tick(Duration elapsed) {
    const dt = 1 / 60.0;
    for (final o in orbs) {
      o.vy += 10 * dt; // gravity
      o.x += o.vx * dt;
      o.y += o.vy * dt;
      // walls
      if (o.x - o.r < 0) {
        o.x = o.r;
        o.vx = o.vx.abs() * .9;
      }
      if (o.x + o.r > size.width) {
        o.x = size.width - o.r;
        o.vx = -o.vx.abs() * .9;
      }
      if (o.y - o.r < 0) {
        o.y = o.r;
        o.vy = o.vy.abs() * .9;
      }
      if (o.y + o.r > size.height) {
        o.y = size.height - o.r;
        o.vy = -o.vy.abs() * .9;
      }
      o.vx *= 0.995;
      o.vy *= 0.995; // drag
    }
    for (final c in confetti) {
      c.vy += 30 * dt;
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.life -= dt;
    }
    confetti.removeWhere((c) => c.life <= 0);
    if (orbs.length < 12 && rnd.nextDouble() < .04) _spawn();
    setState(() {});
  }

  void _popAt(Offset pos) {
    orbs.removeWhere((o) {
      final d = (Offset(o.x, o.y) - pos).distance;
      if (d < o.r + 8) {
        for (int i = 0; i < 24; i++) {
          final a = rnd.nextDouble() * pi * 2;
          final s = rnd.nextDouble() * 280 + 80;
          confetti.add(
            _Confetti(
              x: o.x,
              y: o.y,
              vx: cos(a) * s,
              vy: sin(a) * s,
              color: o.color,
              size: rnd.nextDouble() * 6 + 3,
              life: rnd.nextDouble() * .8 + .6,
            ),
          );
        }
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        size = Size(c.maxWidth, 360);
        if (orbs.isEmpty) {
          for (int i = 0; i < 8; i++) _spawn();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(icon: Icons.toys, title: "Playground"),
            const SizedBox(height: 12),
            GestureDetector(
              onTapDown: (d) => _popAt(d.localPosition),
              onPanUpdate: (d) => _popAt(d.localPosition),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  size: Size(double.infinity, 360),
                  painter: _OrbPainter(orbs, confetti),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text("Tip: Click or drag to pop the orbs ✨"),
          ],
        );
      },
    );
  }
}

class _Orb {
  double x, y, vx, vy, r;
  final Color color;
  _Orb(this.x, this.y, this.vx, this.vy, this.r, this.color);
  factory _Orb.random(Size size, Random rnd) {
    final r = rnd.nextDouble() * 26 + 16;
    final x = rnd.nextDouble() * (size.width - r * 2) + r;
    final y = rnd.nextDouble() * (size.height - r * 2) + r;
    final vx = (rnd.nextDouble() - .5) * 200;
    final vy = (rnd.nextDouble() - .5) * 60;
    final hue = rnd.nextDouble() * 360;
    final c = HSLColor.fromAHSL(1, hue, .75, .60).toColor();
    return _Orb(x, y, vx, vy, r, c);
  }
}

class _Confetti {
  double x, y, vx, vy, size, life;
  final Color color;
  _Confetti({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });
}

class _OrbPainter extends CustomPainter {
  final List<_Orb> orbs;
  final List<_Confetti> confetti;
  _OrbPainter(this.orbs, this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    // background panel
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0b1020).withOpacity(.8),
          const Color(0xFF1a1d2b).withOpacity(.8),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      bg,
    );

    // orbs glow
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    for (final o in orbs) {
      glow.color = o.color.withOpacity(.28);
      canvas.drawCircle(Offset(o.x, o.y), o.r * 1.8, glow);
    }

    // orbs solid
    final solid = Paint();
    for (final o in orbs) {
      final grad =
          RadialGradient(
            colors: [Colors.white.withOpacity(.9), o.color],
            stops: const [.0, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(o.x - o.r * .35, o.y - o.r * .35),
              radius: o.r * 1.6,
            ),
          );
      solid.shader = grad;
      canvas.drawCircle(Offset(o.x, o.y), o.r, solid);
    }

    // confetti squares
    final p = Paint();
    for (final c in confetti) {
      p.color = c.color.withOpacity(c.life.clamp(0.0, 1.0));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(c.x, c.y),
          width: c.size,
          height: c.size,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => true;
}
