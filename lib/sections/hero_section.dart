import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/profile.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 620,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A faint rotating radial glow directly behind the title
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = _controller.value * 2 * pi;
              final c1 = HSLColor.fromAHSL(
                1,
                (t * 90) % 360,
                .80,
                .55,
              ).toColor();
              final c2 = HSLColor.fromAHSL(
                1,
                (t * 90 + 120) % 360,
                .80,
                .55,
              ).toColor();
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(cos(t) * .25, sin(t) * .25),
                    radius: 1.1,
                    colors: [
                      c1.withOpacity(.25),
                      c2.withOpacity(.18),
                      Colors.transparent,
                    ],
                    stops: const [.0, .45, 1],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GradientText(
                      Profile.name,
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .moveY(begin: 16, end: 0, curve: Curves.easeOut)
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withOpacity(.35),
                    ),
                const SizedBox(height: 12),
                Text(
                  Profile.role,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.1,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 150.ms),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in Profile.tech)
                      Chip(
                            label: Text(t),
                            backgroundColor: Colors.white.withOpacity(.08),
                            shape: StadiumBorder(
                              side: BorderSide(color: Colors.white24),
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(.9, .9),
                            end: const Offset(1, 1),
                          )
                          .fadeIn(delay: 250.ms),
                  ],
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  children: const [
                    _CTA(text: 'View Projects', id: 'projects'),
                    _CTA(text: 'Contact Me', id: 'contact', outlined: true),
                  ],
                ).animate().fadeIn(delay: 250.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _GradientText(this.text, {this.style});

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF93C5FD), Color(0xFFA78BFA), Color(0xFF5EEAD4)],
    );
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

class _CTA extends StatefulWidget {
  final String text;
  final String id;
  final bool outlined;
  const _CTA({required this.text, required this.id, this.outlined = false});

  @override
  State<_CTA> createState() => _CTAState();
}

class _CTAState extends State<_CTA> {
  double _dx = 0, _dy = 0;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.outlined ? Colors.transparent : scheme.primary;
    final fg = widget.outlined ? Colors.white : scheme.onPrimary;
    final border = widget.outlined
        ? BorderSide(color: Colors.white24)
        : BorderSide.none;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _dx = _dy = 0;
      }),
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final pos = box.globalToLocal(e.position);
        final nx = (pos.dx / box.size.width - .5);
        final ny = (pos.dy / box.size.height - .5);
        setState(() {
          _dx = nx * 6;
          _dy = ny * 6;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..translate(_dx, _dy, 0.0)
          ..scale(_hover ? 1.04 : 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.outlined
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF22D3EE)],
                  ),
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.fromBorderSide(border),
            boxShadow: [
              if (_hover)
                BoxShadow(
                  color: scheme.primary.withOpacity(.45),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              widget.text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
