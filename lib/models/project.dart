class Project {
  final String title;
  final String description;
  final List<String> tags;
  final String repoUrl;
  final String? liveUrl;
  final String coverImageUrl;

  const Project({
    required this.title,
    required this.description,
    required this.tags,
    required this.repoUrl,
    this.liveUrl,
    required this.coverImageUrl,
  });
}
