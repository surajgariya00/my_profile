import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A neon 4D Tesseract (hypercube) you can drag, click to explode, and watch rotate.
/// - Drag to change rotation (inertia preserved)
/// - Click / tap to toggle explode / collapse
/// - Auto-animates when idle
class TesseractShowcase extends StatefulWidget {
  const TesseractShowcase({super.key});

  @override
  State<TesseractShowcase> createState() => _TesseractShowcaseState();
}

class _TesseractShowcaseState extends State<TesseractShowcase>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Rotation angles for 4D planes (XY, XZ, YZ, XW, YW, ZW)
  double aXY = .0, aXZ = .0, aYZ = .0, aXW = .0, aYW = .0, aZW = .0;

  // Angular velocities (modified by drag inertia)
  double vXY = .2, vXZ = .12, vYZ = .08, vXW = .35, vYW = .18, vZW = .22;

  // drag state
  Offset? _lastDrag;
  bool _exploded = false;
  double _explodeT = 0.0; // 0..1 animation progress

  // nice neon palette
  final List<Color> ring = const [
    Color(0xFF60A5FA), // cyan
    Color(0xFF22D3EE), // aqua
    Color(0xFFA78BFA), // purple
    Color(0xFF5EEAD4), // mint
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    // time step
    const dt = 1 / 60.0;

    // smooth explode animate
    final target = _exploded ? 1.0 : 0.0;
    _explodeT += (target - _explodeT) * (1 - math.pow(0.001, dt));

    // integrate angles with gentle damping so it never goes nuts
    aXY += vXY * dt;
    aXZ += vXZ * dt;
    aYZ += vYZ * dt;
    aXW += vXW * dt;
    aYW += vYW * dt;
    aZW += vZW * dt;

    vXY *= math.pow(0.993, 60 * dt).toDouble();
    vXZ *= math.pow(0.993, 60 * dt).toDouble();
    vYZ *= math.pow(0.993, 60 * dt).toDouble();
    vXW *= math.pow(0.993, 60 * dt).toDouble();
    vYW *= math.pow(0.993, 60 * dt).toDouble();
    vZW *= math.pow(0.993, 60 * dt).toDouble();

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) => _lastDrag = d.localPosition;

  void _onDragUpdate(DragUpdateDetails d) {
    final now = d.localPosition;
    final prev = _lastDrag ?? now;
    final delta = now - prev;
    _lastDrag = now;

    // map 2D drag to a combination of 4D rotations (feels surprisingly intuitive)
    final k = 0.0035;
    vXY += delta.dx * k;
    vYZ += delta.dy * k;
    vXW += -delta.dy * k * 0.8;
    vZW += delta.dx * k * 0.6;
  }

  void _onDragEnd(DragEndDetails d) {
    _lastDrag = null;
    // add a bit of inertia based on fling
    final v = d.velocity.pixelsPerSecond;
    final k = 0.00002;
    vXY += v.dx * k;
    vYZ += v.dy * k;
    vXW += -v.dy * k * 0.6;
    vZW += v.dx * k * 0.5;
  }

  void _toggleExplode() => setState(() => _exploded = !_exploded);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row (optional)
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 22),
            const SizedBox(width: 8),
            Text(
              '4D Tesseract — Interactive',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _toggleExplode,
              icon: const Icon(Icons.blur_on),
              label: Text(_exploded ? 'Collapse' : 'Explode'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _toggleExplode,
            onPanStart: _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: CustomPaint(
              painter: _TesseractPainter(
                aXY: aXY,
                aXZ: aXZ,
                aYZ: aYZ,
                aXW: aXW,
                aYW: aYW,
                aZW: aZW,
                explodeT: _explodeT,
                ring: ring,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: Drag to rotate • Click to explode/collapse',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

// ===================== math + painter =======================

class _TesseractPainter extends CustomPainter {
  final double aXY, aXZ, aYZ, aXW, aYW, aZW; // 4D angles
  final double explodeT; // 0..1
  final List<Color> ring;

  _TesseractPainter({
    required this.aXY,
    required this.aXZ,
    required this.aYZ,
    required this.aXW,
    required this.aYW,
    required this.aZW,
    required this.explodeT,
    required this.ring,
  });

  // Generate 16 4D vertices at (-1 or 1)^4
  List<List<double>> _verts4() {
    final v = <List<double>>[];
    for (int x = -1; x <= 1; x += 2) {
      for (int y = -1; y <= 1; y += 2) {
        for (int z = -1; z <= 1; z += 2) {
          for (int w = -1; w <= 1; w += 2) {
            v.add([x.toDouble(), y.toDouble(), z.toDouble(), w.toDouble()]);
          }
        }
      }
    }
    return v;
  }

  // All edges connect vertices that differ by exactly one coordinate
  List<(int, int)> _edges(int n) {
    final e = <(int, int)>[];
    final verts = _verts4();
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        int diff = 0;
        for (int k = 0; k < 4; k++) {
          if (verts[i][k] != verts[j][k]) diff++;
        }
        if (diff == 1) e.add((i, j));
      }
    }
    return e;
  }

  // 4D rotation helper: rotate in plane (a,b) by angle t
  void _rot(List<double> p, int a, int b, double t) {
    final ca = math.cos(t), sa = math.sin(t);
    final u = p[a], v = p[b];
    p[a] = u * ca - v * sa;
    p[b] = u * sa + v * ca;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ss = size.shortestSide;

    // background panel glow
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0b1020).withOpacity(.85),
          const Color(0xFF1a1d2b).withOpacity(.85),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      bg,
    );

    // Build + rotate vertices
    final verts = _verts4();
    for (final p in verts) {
      _rot(p, 0, 1, aXY);
      _rot(p, 0, 2, aXZ);
      _rot(p, 1, 2, aYZ);
      _rot(p, 0, 3, aXW);
      _rot(p, 1, 3, aYW);
      _rot(p, 2, 3, aZW);

      // explode: push along their 4D direction (outward)
      if (explodeT > 0) {
        final s = 1.0 + 1.6 * explodeT;
        p[0] *= s;
        p[1] *= s;
        p[2] *= s;
        p[3] *= s;
      }
    }

    // 4D -> 3D perspective using w as depth into the 4th axis
    // The more positive w is, the "closer" it is.
    final proj3 = <List<double>>[];
    for (final p in verts) {
      final w = 2.4; // camera distance in 4D
      final k = w / (w - p[3]);
      proj3.add([p[0] * k, p[1] * k, p[2] * k]); // x,y,z
    }

    // 3D -> 2D perspective (z as depth)
    final pts2 = <Offset>[];
    final depths = <double>[];
    for (final p in proj3) {
      final zCam = 3.2; // camera distance in 3D
      final k = zCam / (zCam - p[2]);
      final x = p[0] * k, y = p[1] * k;
      pts2.add(center + Offset(x, y) * (ss * 0.18));
      depths.add(p[2]); // keep for sort / color
    }

    // depth sort edges for nicer painter’s algorithm look
    final E = _edges(verts.length);
    final edgesSorted = E.toList()
      ..sort((a, b) {
        final za = (depths[a.$1] + depths[a.$2]) * .5;
        final zb = (depths[b.$1] + depths[b.$2]) * .5;
        return zb.compareTo(za); // far to near
      });

    // glow + core strokes
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // draw edges with a neon gradient cycling by depth
    for (final (i, j) in edgesSorted) {
      final p1 = pts2[i], p2 = pts2[j];
      final z = ((depths[i] + depths[j]) * .5).clamp(-2.0, 2.0);
      final t = ((z + 2) / 4.0); // 0..1
      final c = _gradient(ring, t);

      glow
        ..color = c.withOpacity(.18)
        ..strokeWidth = 8.0;
      core
        ..color = c
        ..strokeWidth = 2.2;

      // glowing backdrop
      canvas.drawLine(p1, p2, glow);
      // crisp edge
      canvas.drawLine(p1, p2, core);
    }

    // draw nodes (vertices)
    final nodeGlow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final nodeCore = Paint();

    for (int i = 0; i < pts2.length; i++) {
      final o = pts2[i];
      final t = ((depths[i] + 2) / 4.0).clamp(0.0, 1.0);
      final c = _gradient(ring, t);
      final r = 4.0 + 3.0 * (1 - t); // nearer -> bigger

      nodeGlow.color = c.withOpacity(.18);
      nodeCore.color = c;

      canvas.drawCircle(o, r * 2.2, nodeGlow);
      canvas.drawCircle(o, r, nodeCore);
    }
  }

  // blend list of colors like a gradient for 0..1
  Color _gradient(List<Color> cs, double t) {
    if (cs.isEmpty) return Colors.white;
    if (cs.length == 1) return cs.first;
    t = t.clamp(0.0, 1.0);
    final x = t * (cs.length - 1);
    final i = x.floor();
    final f = x - i;
    if (i >= cs.length - 1) return cs.last;
    return Color.lerp(cs[i], cs[i + 1], f)!;
  }

  @override
  bool shouldRepaint(covariant _TesseractPainter old) =>
      old.aXY != aXY ||
      old.aXZ != aXZ ||
      old.aYZ != aYZ ||
      old.aXW != aXW ||
      old.aYW != aYW ||
      old.aZW != aZW ||
      old.explodeT != explodeT ||
      old.ring != ring;
}
