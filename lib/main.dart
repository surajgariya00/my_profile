import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final homeKey = GlobalKey();
  final projectsKey = GlobalKey();
  final aboutKey = GlobalKey();
  final contactKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _GlassNav(
            onNavigate: (id) {
              switch (id) {
                case 'home':
                  _scrollTo(homeKey);
                  break;
                case 'projects':
                  _scrollTo(projectsKey);
                  break;
                case 'about':
                  _scrollTo(aboutKey);
                  break;
                case 'contact':
                  _scrollTo(contactKey);
                  break;
              }
            },
          ),
          ListView(
            controller: _scroll,
            padding: EdgeInsets.zero,
            children: [
              KeyedSubtree(key: homeKey, child: const HeroSection()),
              _Section(key: projectsKey, child: const ProjectsSection()),
              _Section(key: aboutKey, child: const AboutSection()),
              _Section(key: contactKey, child: const ContactSection()),
              const SizedBox(height: 40),
              _Footer(),
            ],
          ),
        ],
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

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      constraints: const BoxConstraints(maxWidth: 1400),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
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
            _Link("Source", Profile.portfolioRepo),
          ],
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final String url;
  const _Link(this.label, this.url);

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
