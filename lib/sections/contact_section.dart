import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/section_title.dart';
import '../data/profile.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: Icons.mail, title: "Contact"),
        const SizedBox(height: 8),
        Text("I'm open to opportunities and collaborations.", style: theme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _launch("mailto:${Profile.email}"),
              icon: const Icon(Icons.email),
              label: const Text("Email me"),
            ),
            OutlinedButton.icon(
              onPressed: () => _launch(Profile.github),
              icon: const Icon(Icons.code),
              label: const Text("GitHub"),
            ),
            OutlinedButton.icon(
              onPressed: () => _launch(Profile.linkedin),
              icon: const Icon(Icons.person),
              label: const Text("LinkedIn"),
            ),
            if (Profile.resumeUrl.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _launch(Profile.resumeUrl),
                icon: const Icon(Icons.description),
                label: const Text("Resume"),
              ),
          ],
        ),
      ],
    );
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}
