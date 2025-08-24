import 'package:flutter/material.dart';

class HyperspaceProgressBar extends StatefulWidget {
  const HyperspaceProgressBar({super.key, required this.controller});
  final ScrollController controller;

  @override
  State<HyperspaceProgressBar> createState() => _HyperspaceProgressBarState();
}

class _HyperspaceProgressBarState extends State<HyperspaceProgressBar> {
  double _p = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listen);
  }

  void _listen() {
    final position = widget.controller.position;
    final total = (position.maxScrollExtent + position.viewportDimension);
    final value = (position.pixels + position.viewportDimension) / total;
    setState(() => _p = value.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            // faint track
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(.06), Colors.transparent],
                  ),
                ),
              ),
            ),
            // neon bar
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _p,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF60A5FA),
                        Color(0xFFA78BFA),
                        Color(0xFF34D399),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
