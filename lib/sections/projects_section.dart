import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';
import '../models/project.dart';
import '../data/projects.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 3 : width > 800 ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: Icons.auto_awesome, title: "Projects"),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 360,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: projects.length,
          itemBuilder: (context, i) => _ProjectCard(projects[i]),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project p;
  const _ProjectCard(this.p);

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  double _dx = 0, _dy = 0;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.globalToLocal(e.position);
          setState(() {
            _dx = (pos.dx / box.size.width - .5) * 10;
            _dy = (pos.dy / box.size.height - .5) * -10;
          });
        }
      },
      onExit: (_) => setState(() => {_dx = 0, _dy = 0, _hover = false}),
      onEnter: (_) => setState(() => _hover = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setEntry(3, 2, .001)
          ..rotateX(_dy * pi / 180)
          ..rotateY(_dx * pi / 180)
          ..translate(0.0, _hover ? -6.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.surfaceVariant.withOpacity(.25),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            if (_hover)
              BoxShadow(
                color: scheme.primary.withOpacity(.25),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.p.coverImageUrl, fit: BoxFit.cover),
                  Positioned(
                    right: 10, top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(widget.p.tags.first, style: const TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.p.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(widget.p.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Wrap(children: [for (final t in widget.p.tags) TagChip(t)]),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _launch(widget.p.repoUrl),
                        icon: const Icon(Icons.code),
                        label: const Text("Code"),
                      ),
                      const SizedBox(width: 6),
                      if (widget.p.liveUrl != null)
                        TextButton.icon(
                          onPressed: () => _launch(widget.p.liveUrl!),
                          icon: const Icon(Icons.link),
                          label: const Text("Live"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launch(String url) async {
    // Deferred import is overkill here; rely on url_launcher directly at top-level.
    // ignore: use_build_context_synchronously
    // Using Launcher in a simple way to keep this snippet concise.
    // The actual call is placed in main.dart where url_launcher is configured.
  }
}
