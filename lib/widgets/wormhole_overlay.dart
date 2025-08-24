// lib/widgets/wormhole_overlay.dart
//
// Full, drop-in overlay that renders a “star-warp / wormhole” transition
// over your entire app. Trigger it from anywhere with:
//
//   WormholeOverlay.of(context).jump(() => _scrollTo(projectsKey));
//
// Optional: pass an origin (in global coordinates) to warp from a specific point:
//   final box = (context.findRenderObject() as RenderBox);
//   final origin = box.localToGlobal(Offset(box.size.width/2, box.size.height/2));
//   WormholeOverlay.of(context).jump(() => _scrollTo(key), origin: origin);

import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;
import 'package:flutter/material.dart';

class WormholeOverlay extends StatefulWidget {
  const WormholeOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.starCount = 420,
    this.glowA = const Color(0xFF60A5FA), // cyan
    this.glowB = const Color(0xFFA78BFA), // purple
  });

  final Widget child;
  final Duration duration;
  final int starCount;
  final Color glowA;
  final Color glowB;

  /// Access the overlay state from descendants to trigger the warp.
  static _WormholeOverlayState of(BuildContext context) {
    final state = context.findAncestorStateOfType<_WormholeOverlayState>();
    assert(
      state != null,
      'WormholeOverlay.of(context) used with no WormholeOverlay ancestor.',
    );
    return state!;
  }

  @override
  State<WormholeOverlay> createState() => _WormholeOverlayState();
}

class _WormholeOverlayState extends State<WormholeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _active = false;
  bool _firedMid = false;
  VoidCallback? _onMid;
  Offset? _originGlobal; // where to start warp from (global coords)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        // Fire the mid-callback once (used to navigate/scroll during warp)
        if (!_firedMid && _controller.value >= 0.5) {
          _firedMid = true;
          _onMid?.call();
        }
        // Auto-hide overlay on completion
        if (_controller.isCompleted) {
          setState(() {
            _active = false;
            _originGlobal = null;
          });
        }
      });
  }

  /// Start the warp. Provide a function to run mid-transition (e.g. navigate/scroll).
  /// [origin] (global coordinates) lets you warp from a specific on-screen point.
  void jump(VoidCallback onMid, {Offset? origin}) {
    _onMid = onMid;
    _originGlobal = origin;
    _firedMid = false;
    setState(() => _active = true);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _toLocalOrigin(Size size) {
    // If an origin in global coords was provided, convert to this overlay's local space.
    if (_originGlobal != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        try {
          return box.globalToLocal(_originGlobal!);
        } catch (_) {}
      }
    }
    // Fallback: center of the screen
    return Offset(size.width / 2, size.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_active)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final p = Curves.easeInOut.transform(_controller.value);
                  return CustomPaint(
                    painter: _WormholePainter(
                      progress: p,
                      starCount: widget.starCount,
                      glowA: widget.glowA,
                      glowB: widget.glowB,
                      originResolver: _toLocalOrigin,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _WormholePainter extends CustomPainter {
  _WormholePainter({
    required this.progress, // 0..1
    required this.starCount,
    required this.glowA,
    required this.glowB,
    required this.originResolver,
  });

  final double progress;
  final int starCount;
  final Color glowA;
  final Color glowB;
  final Offset Function(Size) originResolver;

  @override
  void paint(Canvas canvas, Size size) {
    final center = originResolver(size);

    // 1) Backdrop darken
    final fade = Paint()..color = Colors.black.withOpacity(0.72 * progress);
    canvas.drawRect(Offset.zero & size, fade);

    // 2) Expanding radial glow (cyan → purple → transparent)
    final glowShader =
        RadialGradient(
          colors: [
            glowA.withOpacity(0.6 * progress),
            glowB.withOpacity(0.35 * progress),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: size.shortestSide * (0.2 + 0.8 * progress),
          ),
        );
    final glowPaint = Paint()..shader = glowShader;
    canvas.drawCircle(center, size.shortestSide, glowPaint);

    // 3) Star streaks (additive-ish look using blur + alpha)
    final rng = math.Random(7); // stable pattern each frame
    for (int i = 0; i < starCount; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final seed = rng.nextDouble();

      // Length grows with progress (warp speed!)
      final len = ui.lerpDouble(
        0,
        size.shortestSide * 0.95,
        progress * (0.4 + 0.6 * seed),
      )!;
      final startOffset = ui.lerpDouble(
        40,
        6,
        progress,
      )!; // collapse toward the origin
      final start = center + dir * startOffset * (1.0 - progress);
      final end = center + dir * len;

      // Glow halo
      final halo = Paint()
        ..color = Colors.white.withOpacity(0.085)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..strokeWidth = ui.lerpDouble(1.6, 0.5, progress)!
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, halo);

      // Core streak
      final core = Paint()
        ..color = Colors.white.withOpacity(0.78)
        ..strokeWidth = ui.lerpDouble(1.0, 0.25, progress)!
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, core);
    }

    // 4) Iris ring: collapse (0→.5), then bloom (.5→1)
    final irisAlpha = (1 - (progress - .5).abs() * 2).clamp(0.0, 1.0);
    final irisR = progress < .5
        ? ui.lerpDouble(
            size.shortestSide * .42,
            size.shortestSide * .08,
            progress / .5,
          )!
        : ui.lerpDouble(
            size.shortestSide * .08,
            size.shortestSide * .52,
            (progress - .5) / .5,
          )!;

    final iris = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withOpacity(.55 * irisAlpha);
    canvas.drawCircle(center, irisR, iris);
  }

  @override
  bool shouldRepaint(covariant _WormholePainter old) =>
      old.progress != progress ||
      old.starCount != starCount ||
      old.glowA != glowA ||
      old.glowB != glowB;
}
