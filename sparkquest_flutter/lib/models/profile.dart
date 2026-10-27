class Profile {
  final String id;
  final String name;
  final int age;
  final String occupation;
  final String distance;
  final String photoAsset;
  final List<String> tags;
  final int compatPct;
  final String compatLevel; // 'high', 'medium'
  final bool isVerified;
  final bool hasVoicePrompt;
  final String voicePromptText;

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.occupation,
    required this.distance,
    required this.photoAsset,
    required this.tags,
    required this.compatPct,
    required this.compatLevel,
    this.isVerified = true,
    this.hasVoicePrompt = true,
    this.voicePromptText = "My idea of the perfect Sunday morning 🌅",
  });

  static List<Profile> get seedProfiles => [
    const Profile(
      id: 'sophia',
      name: 'Sophia',
      age: 24,
      occupation: 'Photographer',
      distance: '2 mi away',
      photoAsset: 'assets/images/sophia.png',
      tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'],
      compatPct: 92,
      compatLevel: 'high',
      voicePromptText: 'My idea of the perfect Sunday morning 🌅',
    ),
    const Profile(
      id: 'alex',
      name: 'Alex',
      age: 27,
      occupation: 'Software Engineer',
      distance: '5 mi away',
      photoAsset: 'assets/images/alex.png',
      tags: ['🎮 Gaming', '🍳 Cooking', '📚 Books'],
      compatPct: 87,
      compatLevel: 'high',
      voicePromptText: 'My secret, completely useless talent 🪄',
    ),
    const Profile(
      id: 'maya',
      name: 'Maya',
      age: 25,
      occupation: 'Yoga Instructor',
      distance: '3 mi away',
      photoAsset: 'assets/images/maya.png',
      tags: ['🧘 Yoga', '🌱 Vegan', '✈️ Travel'],
      compatPct: 78,
      compatLevel: 'medium',
      voicePromptText: 'My most unhinged travel story ✈️',
    ),
    const Profile(
      id: 'jordan',
      name: 'Jordan',
      age: 28,
      occupation: 'Music Producer',
      distance: '1 mi away',
      photoAsset: 'assets/images/jordan.png',
      tags: ['🎵 Music', '🎬 Film', '🍷 Wine'],
      compatPct: 94,
      compatLevel: 'high',
      voicePromptText: 'What my voice sounds like at 7 AM ☕',
    ),
    const Profile(
      id: 'riley',
      name: 'Riley',
      age: 23,
      occupation: 'Med Student',
      distance: '4 mi away',
      photoAsset: 'assets/images/riley.png',
      tags: ['🏃 Running', '🐕 Dogs', '📖 Reading'],
      compatPct: 75,
      compatLevel: 'medium',
      voicePromptText: 'Hot take on pineapple pizza 🍕',
    ),
    const Profile(
      id: 'taylor',
      name: 'Taylor',
      age: 26,
      occupation: 'Designer',
      distance: '6 mi away',
      photoAsset: 'assets/images/taylor.png',
      tags: ['🎨 Design', '☕ Coffee', '🎸 Guitar'],
      compatPct: 89,
      compatLevel: 'high',
      voicePromptText: 'My most unhinged travel story ✈️',
    ),
  ];
}
