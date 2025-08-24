import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient mesh blobs
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = _c.value * 2 * pi;
              return Stack(
                children: [
                  _blob(
                    t,
                    size: 420,
                    hue: (t * 16) % 360,
                    x: 0.15,
                    y: 0.18,
                    dx: 0.12,
                    dy: 0.10,
                    blur: 90,
                  ),
                  _blob(
                    t,
                    size: 520,
                    hue: (t * 16 + 120) % 360,
                    x: 0.82,
                    y: 0.22,
                    dx: 0.10,
                    dy: 0.12,
                    blur: 100,
                  ),
                  _blob(
                    t,
                    size: 460,
                    hue: (t * 16 + 240) % 360,
                    x: 0.40,
                    y: 0.85,
                    dx: 0.08,
                    dy: 0.08,
                    blur: 90,
                  ),
                ],
              );
            },
          ),

          // Subtle dot grid overlay
          CustomPaint(
            painter: _DotGridPainter(color: Colors.white.withOpacity(0.04)),
          ),

          // Soft vignette for focus
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                stops: const [0.70, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(
    double t, {
    required double size,
    required double hue,
    required double x,
    required double y,
    required double dx,
    required double dy,
    required double blur,
  }) {
    final c = HSLColor.fromAHSL(1, hue, .70, .58).toColor();
    final ox = x + sin(t) * dx;
    final oy = y + cos(t * 0.9) * dy;
    return Positioned(
      left: ox * MediaQuery.of(context).size.width - size / 2,
      top: oy * MediaQuery.of(context).size.height - size / 2,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 28.0; // grid spacing
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
