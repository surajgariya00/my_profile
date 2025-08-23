import '../models/project.dart';

const projects = <Project>[
  Project(
    title: "Animated Todo",
    description:
        "A minimal todo app focused on micro-interactions, smooth transitions, and accessibility.",
    tags: ["Flutter", "Animations", "State Management"],
    repoUrl: "https://github.com/yourusername/animated_todo",
    liveUrl: null,
    coverImageUrl:
        "https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=1200&auto=format&fit=crop",
  ),
  Project(
    title: "Travel Cards",
    description:
        "Parallax travel cards with lazy-loaded images and hero transitions for a magazine feel.",
    tags: ["Flutter Web", "Parallax", "Design"],
    repoUrl: "https://github.com/yourusername/travel_cards",
    liveUrl: "https://yourusername.github.io/travel_cards/",
    coverImageUrl:
        "https://images.unsplash.com/photo-1491553895911-0055eca6402d?q=80&w=1200&auto=format&fit=crop",
  ),
  Project(
    title: "Crypto Watch",
    description:
        "A dashboard that visualizes crypto trends with animated charts and responsive layout.",
    tags: ["Flutter", "Charts", "Responsive"],
    repoUrl: "https://github.com/yourusername/crypto_watch",
    liveUrl: null,
    coverImageUrl:
        "https://images.unsplash.com/photo-1640340434868-492ce8f4f967?q=80&w=1200&auto=format&fit=crop",
  ),
];
