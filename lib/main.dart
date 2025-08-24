import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';

import 'widgets/animated_background.dart';
import 'widgets/laser_ribbon_overlay.dart';
import 'widgets/particle_cursor_overlay.dart';
import 'widgets/playground_section.dart';
import 'widgets/wormhole_overlay.dart';
import 'sections/hero_section.dart';
import 'sections/projects_section.dart';
import 'sections/about_section.dart';
import 'sections/contact_section.dart';
import 'data/profile.dart';

void main() {
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0ea5e9),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0b1020),
      cardTheme: CardThemeData(
        color: const Color(0xFF1a1d2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );

    return MaterialApp(
      title: 'Portfolio — ${Profile.name}',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey overlayKey = GlobalKey();
  // Use these keys for Scrollable.ensureVisible targets
  final homeKey = GlobalKey();
  final projectsKey = GlobalKey();
  final aboutKey = GlobalKey();
  final contactKey = GlobalKey();
  final playgroundKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubicEmphasized,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 Wrap everything with the wormhole overlay
      body: WormholeOverlay(
        key: overlayKey,
        child: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackground()),
            const Positioned.fill(child: LaserRibbonOverlay()),
            const Positioned.fill(child: ParticleCursorOverlay(count: 160)),

            // content first
            ListView(
              controller: _scroll,
              padding: EdgeInsets.zero,
              children: [
                KeyedSubtree(key: homeKey, child: const HeroSection()),
                KeyedSubtree(
                  key: projectsKey,
                  child: const _Section(child: ProjectsSection()),
                ),
                KeyedSubtree(
                  key: playgroundKey,
                  child: const _Section(child: PlaygroundSection()),
                ),
                KeyedSubtree(
                  key: aboutKey,
                  child: const _Section(child: AboutSection()),
                ),
                KeyedSubtree(
                  key: contactKey,
                  child: const _Section(child: ContactSection()),
                ),
                const SizedBox(height: 40),
                const _Footer(),
              ],
            ),

            // nav LAST so it’s on top and receives taps
            _GlassNav(
              onNavigate: (id) {
                void warpTo(GlobalKey k) => (overlayKey.currentState as dynamic)
                    ?.jump(() => _scrollTo(k));

                switch (id) {
                  case 'home':
                    warpTo(homeKey);
                    break;
                  case 'projects':
                    warpTo(projectsKey);
                    break;
                  case 'playground':
                    warpTo(playgroundKey);
                    break;
                  case 'about':
                    warpTo(aboutKey);
                    break;
                  case 'contact':
                    warpTo(contactKey);
                    break;
                }
              },
            ),

            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () =>
                    (overlayKey.currentState as dynamic)?.jump(() {}),
                child: const Icon(Icons.auto_awesome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
          child: child,
        ),
      ),
    );
  }
}

class _GlassNav extends StatelessWidget {
  final void Function(String id) onNavigate;
  const _GlassNav({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.35),
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 60,
            child: Row(
              children: [
                Text(
                  "⚡ ${Profile.name.split(' ').first}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _NavButton("Home", () => onNavigate('home')),
                _NavButton("Projects", () => onNavigate('projects')),
                _NavButton("Playground", () => onNavigate('playground')),
                _NavButton("About", () => onNavigate('about')),
                _NavButton("Contact", () => onNavigate('contact')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _NavButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

class _Footer extends StatelessWidget {
  const _Footer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            _Link("GitHub", Profile.github),
            _Link("LinkedIn", Profile.linkedin),
            if (Profile.twitter.isNotEmpty) _Link("Twitter", Profile.twitter),
          ],
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final String url;
  const _Link(this.label, this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      },
      child: Text(label),
    );
  }
}

// Bottom glass nav that warps from the tapped button
class _BottomWarpNav extends StatelessWidget {
  final VoidCallback onHome, onProjects, onPlayground, onAbout, onContact;
  const _BottomWarpNav({
    required this.onHome,
    required this.onProjects,
    required this.onPlayground,
    required this.onAbout,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.35),
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WarpButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTarget: onHome,
                ),
                _WarpButton(
                  icon: Icons.toys,
                  label: 'Play',
                  onTarget: onPlayground,
                ),
                _WarpButton(
                  icon: Icons.auto_awesome,
                  label: 'Projects',
                  onTarget: onProjects,
                ),
                _WarpButton(
                  icon: Icons.info_outline,
                  label: 'About',
                  onTarget: onAbout,
                ),
                _WarpButton(
                  icon: Icons.mail_outline,
                  label: 'Contact',
                  onTarget: onContact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTarget;
  const _WarpButton({
    required this.icon,
    required this.label,
    required this.onTarget,
  });

  @override
  Widget build(BuildContext context) {
    // Builder gives us a button-local context so we can get its RenderBox at tap-time.
    return Builder(
      builder: (btnCtx) {
        return TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // Find the button’s center in GLOBAL coordinates
            final box = btnCtx.findRenderObject() as RenderBox?;
            Offset? origin;
            if (box != null) {
              origin = box.localToGlobal(box.size.center(Offset.zero));
            }
            // Warp from that point, then run your navigation mid-warp
            WormholeOverlay.of(btnCtx).jump(() => onTarget(), origin: origin);
          },
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
      },
    );
  }
}
