import 'dart:ui';

import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final void Function(String id) onNavigate;
  const NavBar({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ["home", "Home"],
      ["projects", "Projects"],
      ["about", "About"],
      ["contact", "Contact"],
    ];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.3),
        // backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      ),
      child: Row(
        children: [
          Text(
            "⚡ Portfolio",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            children: [
              for (final it in items)
                TextButton(
                  onPressed: () => onNavigate(it[0]!),
                  child: Text(it[1]!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
