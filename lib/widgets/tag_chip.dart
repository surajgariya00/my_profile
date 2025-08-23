import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String label;
  const TagChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(.3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer)),
    );
  }
}
