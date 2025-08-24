import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';
import '../models/project.dart';
import '../data/projects.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 3
        : width > 900
        ? 2
        : 1;

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
            mainAxisExtent: 380,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
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
  double _dx = 0, _dy = 0; // tilt degrees
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
            _dx = (pos.dx / box.size.width - .5) * 12; // stronger tilt
            _dy = (pos.dy / box.size.height - .5) * -12;
          });
        }
      },
      onExit: (_) => setState(() => {_dx = 0, _dy = 0, _hover = false}),
      onEnter: (_) => setState(() => _hover = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateX(_dy * pi / 180)
          ..rotateY(_dx * pi / 180)
          ..translate(0.0, _hover ? -8.0 : 0.0),
        child: Container(
          // Neon gradient border wrapper
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFFA78BFA), Color(0xFF34D399)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(1.6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: scheme.surface.withOpacity(.1),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                if (_hover)
                  BoxShadow(
                    color: scheme.primary.withOpacity(.28),
                    blurRadius: 28,
                    spreadRadius: 1,
                    offset: const Offset(0, 16),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Media
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.28), // tweak 0.20–0.45
                      BlendMode.darken,
                    ),
                    child: Image.network(
                      widget.p.coverImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Readability gradient bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 220, // was 180
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.70), // was .55
                        ],
                      ),
                    ),
                  ),
                ),
                // Shine sweep overlay when hovering
                if (_hover)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Transform.rotate(
                          angle: -pi / 6,
                          child: FractionallySizedBox(
                            widthFactor: .5,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.08),
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

                // Text + actions
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
                              widget.p.tags.first,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.p.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    const Shadow(
                                      blurRadius: 10,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            children: [
                              for (final t in widget.p.tags) TagChip(t),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _GlowButton(
                                label: 'Code',
                                icon: Icons.code,
                                onTap: () => _launch(widget.p.repoUrl),
                              ),
                              const SizedBox(width: 8),
                              if (widget.p.liveUrl != null)
                                _GlowButton(
                                  label: 'Live',
                                  icon: Icons.link,
                                  onTap: () => _launch(widget.p.liveUrl!),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

class _GlowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlowButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF22D3EE)],
          ),
          boxShadow: [
            if (_hover)
              BoxShadow(
                color: scheme.primary.withOpacity(.45),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: InkWell(
          onTap: widget.onTap,
          splashColor: Colors.white24,
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
