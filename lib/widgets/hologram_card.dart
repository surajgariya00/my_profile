import 'dart:math';
import 'package:flutter/material.dart';
import '../models/project.dart';

class HologramProjectCard extends StatefulWidget {
  final Project p;
  const HologramProjectCard(this.p, {super.key});

  @override
  State<HologramProjectCard> createState() => _HologramProjectCardState();
}

class _HologramProjectCardState extends State<HologramProjectCard> {
  double _dx = 0, _dy = 0; // tilt
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.globalToLocal(e.position);
          setState(() {
            _dx = (pos.dx / box.size.width - .5) * 16;
            _dy = (pos.dy / box.size.height - .5) * -16;
          });
        }
      },
      onExit: (_) => setState(() => {_dx = 0, _dy = 0, _hover = false}),
      onEnter: (_) => setState(() => _hover = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0016)
          ..rotateX(_dy * pi / 180)
          ..rotateY(_dx * pi / 180)
          ..translate(0.0, _hover ? -10.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            // Outer glow frame changes with tilt
            boxShadow: [
              if (_hover)
                BoxShadow(
                  color: scheme.primary.withOpacity(.35),
                  blurRadius: 36,
                  spreadRadius: 1,
                  offset: const Offset(0, 18),
                ),
            ],
          ),
          child: _HoloFrame(
            dx: _dx,
            dy: _dy,
            child: _HoloSurface(p: widget.p, hover: _hover),
          ),
        ),
      ),
    );
  }
}

class _HoloFrame extends StatelessWidget {
  const _HoloFrame({required this.child, required this.dx, required this.dy});
  final Widget child;
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment(-dx / 12, -dy / 12),
          end: Alignment(dx / 12, dy / 12),
          colors: const [
            Color(0xFF60A5FA),
            Color(0xFFA78BFA),
            Color(0xFF34D399),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(.40),
          border: Border.all(color: Colors.white12),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _HoloSurface extends StatelessWidget {
  const _HoloSurface({required this.p, required this.hover});
  final Project p;
  final bool hover;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.22),
              BlendMode.darken,
            ),
            child: Image.network(p.coverImageUrl, fit: BoxFit.cover),
          ),
        ),

        // Deep gradient for caption readability
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 230,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(.72)],
              ),
            ),
          ),
        ),

        // Sheen sweep
        if (hover)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: hover ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Transform.rotate(
                  angle: -pi / 6,
                  child: FractionallySizedBox(
                    widthFactor: .55,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Subtle scanlines overlay (adds hologram texture)
        Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),

        // Bottom caption + actions
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      p.tags.first,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter oldDelegate) => false;
}
