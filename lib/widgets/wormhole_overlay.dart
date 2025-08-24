// lib/widgets/wormhole_overlay.dart
//
// Ultra "black-hole" warp: snapshot collapses with RGB split + shake,
// stars and debris spiral inward, then a chromatic portal expands to reveal
// the target section. Pure Flutter, web-friendly.
//
// Use:
//   body: WormholeOverlay(child: Stack(children: [...]))
//   WormholeOverlay.of(context).jump(() => _scrollTo(projectsKey));
//   // Optional: origin = center of the tapped widget (global coords)

import 'dart:math' as math;
import 'dart:ui' as ui show Image, ImageFilter, lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WormholeOverlay extends StatefulWidget {
  const WormholeOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.starCount = 360,
    this.debrisCount = 70,
    this.portalA = const Color(0xFF60A5FA),
    this.portalB = const Color(0xFFA78BFA),
    this.useSnapshot =
        true, // turn off if you just want FX without sucking the UI
  });

  final Widget child;
  final Duration duration;
  final int starCount;
  final int debrisCount;
  final Color portalA;
  final Color portalB;
  final bool useSnapshot;

  static _WormholeOverlayState of(BuildContext context) {
    final s = context.findAncestorStateOfType<_WormholeOverlayState>();
    assert(
      s != null,
      'WormholeOverlay.of(context) requires an ancestor WormholeOverlay.',
    );
    return s!;
  }

  @override
  State<WormholeOverlay> createState() => _WormholeOverlayState();
}

class _WormholeOverlayState extends State<WormholeOverlay>
    with SingleTickerProviderStateMixin {
  final GlobalKey _contentKey = GlobalKey();
  late final AnimationController _c;

  bool _active = false;
  bool _firedMid = false;
  VoidCallback? _onMid;
  Offset? _originGlobal;
  ui.Image? _snap;

  // Pre-generated debris seeds per jump
  late List<_Debris> _debris;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        if (!_firedMid && _c.value >= .5) {
          _firedMid = true;
          _onMid?.call();
        }
        if (_c.isCompleted) {
          setState(() {
            _active = false;
            _originGlobal = null;
            _snap?.dispose();
            _snap = null;
          });
        }
      });
  }

  Future<void> jump(VoidCallback onMid, {Offset? origin}) async {
    _onMid = onMid;
    _originGlobal = origin;
    _firedMid = false;

    // New debris batch for each jump
    _debris = _genDebris(widget.debrisCount);

    if (widget.useSnapshot) {
      await _captureSnapshot();
    } else {
      _snap = null;
    }

    setState(() => _active = true);
    await _c.forward(from: 0);
  }

  Future<void> _captureSnapshot() async {
    try {
      final boundary =
          _contentKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final pr = View.of(context).devicePixelRatio;
      final img = await boundary.toImage(pixelRatio: pr.clamp(1.0, 2.0));
      _snap?.dispose();
      _snap = img;
    } catch (_) {
      _snap = null;
    }
  }

  Offset _toLocalOrigin(Size size) {
    if (_originGlobal != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        try {
          return box.globalToLocal(_originGlobal!);
        } catch (_) {}
      }
    }
    return Offset(size.width / 2, size.height / 2);
  }

  @override
  void dispose() {
    _c.dispose();
    _snap?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(key: _contentKey, child: widget.child),
        if (_active)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final p = Curves.easeInOut.transform(_c.value);
                return CustomPaint(
                  painter: _BlackHolePainter(
                    progress: p,
                    starCount: widget.starCount,
                    portalA: widget.portalA,
                    portalB: widget.portalB,
                    originResolver: _toLocalOrigin,
                    snapshot: _snap,
                    debris: _debris,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Debris seeded around edges, flying toward center with a swirl
  List<_Debris> _genDebris(int n) {
    final rnd = math.Random();
    return List.generate(n, (i) {
      // spawn around a donut near screen border
      final a = rnd.nextDouble() * math.pi * 2;
      final r = 0.85 + rnd.nextDouble() * 0.25;
      final hue = rnd.nextDouble() * 360;
      final color = HSLColor.fromAHSL(1, hue, .85, .6).toColor();
      return _Debris(
        angle0: a,
        radius0: r, // relative to shortestSide
        size: rnd.nextDouble() * 9 + 4, // px
        spin: (rnd.nextDouble() - .5) * 6, // radians over life
        tBias: rnd.nextDouble() * .25, // some start later
        color: color,
      );
    });
  }
}

class _Debris {
  final double angle0; // initial angle (0..2pi)
  final double radius0; // initial radius factor (r * shortestSide)
  final double size;
  final double spin;
  final double tBias; // delays/offsets progression per particle
  final Color color;
  const _Debris({
    required this.angle0,
    required this.radius0,
    required this.size,
    required this.spin,
    required this.tBias,
    required this.color,
  });
}

class _BlackHolePainter extends CustomPainter {
  _BlackHolePainter({
    required this.progress, // 0..1
    required this.starCount,
    required this.portalA,
    required this.portalB,
    required this.originResolver,
    required this.snapshot,
    required this.debris,
  });

  final double progress;
  final int starCount;
  final Color portalA, portalB;
  final ui.Image? snapshot;
  final List<_Debris> debris;
  final Offset Function(Size) originResolver;

  @override
  void paint(Canvas canvas, Size size) {
    final center = originResolver(size);
    final ss = size.shortestSide;

    // Split animation phases
    final suck = (progress <= .5) ? (progress / .5) : 1.0; // 0..1 (collapse)
    final reveal = (progress > .5)
        ? ((progress - .5) / .5)
        : 0.0; // 0..1 (expand)

    // Background darken + subtle vignette
    _backdrop(canvas, size, progress, center);

    // Star swirl (curved streaks)
    _stars(canvas, size, center, starCount, progress);

    // Debris spiraling in
    _debris(canvas, size, center, debris, progress);

    // Suck the live snapshot into the singularity with RGB split + shake
    if (snapshot != null && suck > 0) {
      _suckSnapshot(canvas, size, center, snapshot!, suck, progress);
    }

    // Mid flash for punch
    if ((progress - .5).abs() < 0.035) {
      final k = (0.035 - (progress - .5).abs()) / 0.035;
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withOpacity(0.22 * k),
      );
    }

    // Portal reveal: cut a growing hole + chromatic rings
    if (reveal > 0) {
      _portal(canvas, size, center, reveal, ss);
    }
  }

  void _backdrop(Canvas canvas, Size size, double p, Offset center) {
    final dark = Paint()..color = Colors.black.withOpacity(0.65 * p);
    canvas.drawRect(Offset.zero & size, dark);

    final glow =
        RadialGradient(
          colors: [
            portalA.withOpacity(.55 * p),
            portalB.withOpacity(.30 * p),
            Colors.transparent,
          ],
          stops: const [.0, .38, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: size.shortestSide * (.25 + .75 * p),
          ),
        );
    canvas.drawCircle(center, size.shortestSide, Paint()..shader = glow);
  }

  void _stars(Canvas canvas, Size size, Offset c, int count, double p) {
    final rnd = math.Random(11);
    final swirl = ui.lerpDouble(0.0, 1.2, p)!; // radians of curve at max
    for (int i = 0; i < count; i++) {
      final base = rnd.nextDouble();
      final ang = rnd.nextDouble() * math.pi * 2;
      final dir = Offset(math.cos(ang), math.sin(ang));
      final len = ui.lerpDouble(
        0,
        size.shortestSide * 0.95,
        p * (0.35 + 0.65 * base),
      )!;
      final start = c + dir * ui.lerpDouble(36, 6, p)! * (1 - p);
      final end = c + dir * len;

      // curve control point (perpendicular bend)
      final n = Offset(-dir.dy, dir.dx);
      final bend = n * (20.0 + 80.0 * base) * p * math.sin(p * math.pi) * swirl;
      final cp = Offset.lerp(start, end, 0.5)! + bend;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(cp.dx, cp.dy, end.dx, end.dy);

      final glow = Paint()
        ..color = Colors.white.withOpacity(.085)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ui.lerpDouble(1.6, 0.35, p)!
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow);

      final core = Paint()
        ..color = Colors.white.withOpacity(.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ui.lerpDouble(1.0, 0.22, p)!
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, core);
    }
  }

  void _debris(
    Canvas canvas,
    Size size,
    Offset center,
    List<_Debris> seeds,
    double p,
  ) {
    if (seeds.isEmpty) return;
    final ss = size.shortestSide;
    for (final d in seeds) {
      // progress per-particle (some start later)
      final tp = ((p - d.tBias).clamp(0.0, 1.0));
      if (tp <= 0) continue;

      // spiral toward center
      final r0 = d.radius0 * ss;
      final r = ui.lerpDouble(r0, 6, tp)!;
      final theta = d.angle0 + ui.lerpDouble(0, 2.6, tp)!; // swirl angle
      final pos = center + Offset(math.cos(theta), math.sin(theta)) * r;

      final rot = ui.lerpDouble(0, d.spin, tp)!;
      final sz = ui.lerpDouble(d.size, d.size * .4, tp)!;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      final glow = Paint()
        ..color = d.color.withOpacity(.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: sz * 2.2, height: sz),
          const Radius.circular(2),
        ),
        glow,
      );
      final core = Paint()..color = d.color.withOpacity(.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: sz * 1.4,
            height: sz * .8,
          ),
          const Radius.circular(1.6),
        ),
        core,
      );
      canvas.restore();
    }
  }

  void _suckSnapshot(
    Canvas canvas,
    Size size,
    Offset center,
    ui.Image img,
    double suck,
    double p,
  ) {
    // Subtle camera shake near the midpoint
    final shakeAmp = 6.0 * math.sin(math.pi * p) * math.sin(2 * math.pi * p);
    final shake = Offset(
      math.sin(21 * p * math.pi) * shakeAmp,
      math.cos(17 * p * math.pi) * shakeAmp,
    );

    final angle = ui.lerpDouble(0, -0.55, suck)!; // radians
    final scale = ui.lerpDouble(1.0, 0.03, suck)!; // collapse
    final wobble = 0.02 * math.sin(p * 10 * math.pi); // tiny z-shake imitation

    // Draw into a layer so we can blur/tint pieces
    final layer = Offset.zero & size;
    canvas.saveLayer(layer, Paint());

    // RGB split: draw three passes with slight offsets & channel filters
    final offsets = [Offset(1.2, 0.8), Offset(-1.0, -0.6), Offset(0.0, 0.0)];
    final mats = [_matR, _matG, _matB];

    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(
        center.dx + shake.dx + offsets[i].dx * (1 + 12 * (1 - suck)),
        center.dy + shake.dy + offsets[i].dy * (1 + 12 * (1 - suck)),
      );
      canvas.rotate(angle + wobble * (i == 2 ? 1 : .5));
      canvas.scale(scale, scale);

      final blurSigma = ui.lerpDouble(0, 9, suck)!;
      final paint = Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        )
        ..colorFilter = ColorFilter.matrix(mats[i])
        ..blendMode = BlendMode.plus;

      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: size.width,
        height: size.height,
      );
      canvas.drawImageRect(img, src, dst, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  void _portal(Canvas canvas, Size size, Offset center, double t, double ss) {
    final veilBounds = Offset.zero & size;
    canvas.saveLayer(veilBounds, Paint());

    // fade veil
    canvas.drawRect(
      veilBounds,
      Paint()..color = Colors.black.withOpacity(ui.lerpDouble(0.65, 0.0, t)!),
    );

    // punch hole
    final holeR = ui.lerpDouble(ss * 0.04, ss * 1.25, t)!;
    final eraser = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, holeR, eraser);

    // chromatic ring stack (white + A + B)
    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(7, 1.5, t)!
      ..color = Colors.white.withOpacity(ui.lerpDouble(0.95, 0.0, t)!);
    canvas.drawCircle(center, holeR, white);

    final r1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(10, 2, t)!
      ..color = portalA.withOpacity(ui.lerpDouble(0.45, 0.0, t)!);
    canvas.drawCircle(center, holeR * 1.03, r1);

    final r2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(10, 2, t)!
      ..color = portalB.withOpacity(ui.lerpDouble(0.45, 0.0, t)!);
    canvas.drawCircle(center, holeR * 0.97, r2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlackHolePainter old) =>
      old.progress != progress ||
      old.starCount != starCount ||
      old.portalA != portalA ||
      old.portalB != portalB ||
      old.snapshot != snapshot ||
      old.debris != debris;
}

// Color matrix helpers for RGB split (isolate channels)
const List<double> _matR = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
const List<double> _matG = <double>[
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
const List<double> _matB = <double>[
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
