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
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
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
      height: 600,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * pi;
              final c1 = HSLColor.fromAHSL(1, (t * 90) % 360, .65, .55).toColor();
              final c2 = HSLColor.fromAHSL(1, (t * 90 + 120) % 360, .65, .55).toColor();
              final c3 = HSLColor.fromAHSL(1, (t * 90 + 240) % 360, .65, .55).toColor();
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(cos(t) * .2, sin(t) * .2),
                    radius: 1.2,
                    colors: [c1, c2, c3],
                  ),
                ),
              );
            },
          ),
          Container(color: Colors.black.withOpacity(.50)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Profile.name,
                    style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800))
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .moveY(begin: 20, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 12),
                Text(Profile.role,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ))
                    .animate()
                    .fadeIn(duration: 700.ms, delay: 200.ms),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final t in Profile.tech)
                      Chip(
                        label: Text(t),
                        backgroundColor: Colors.white.withOpacity(.08),
                        shape: StadiumBorder(side: BorderSide(color: Colors.white24)),
                        labelStyle: const TextStyle(color: Colors.white),
                      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(.9,.9), end: const Offset(1,1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
