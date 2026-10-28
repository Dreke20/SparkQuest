class Profile {
  final String id;
  final String name;
  final int age;
  final String occupation;
  final String distance;
  final String photoAsset;
  final List<String> photoGallery;
  final List<String> tags;
  final int compatPct;
  final String compatLevel; // 'high', 'medium'
  final bool isVerified;
  final bool hasVoicePrompt;
  final String voicePromptText;
  final String rpgClass;
  final String relationshipIntent;
  final String pronouns;
  final String height;
  final String languages;
  final String zodiac;
  final List<String> lifestyleVitals;
  final String anthemTitle;
  final String anthemArtist;
  final String pollQuestion;
  final List<String> pollOptions;
  final bool isFreeTonight;
  final bool isStandout;

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.occupation,
    required this.distance,
    required this.photoAsset,
    this.photoGallery = const [],
    required this.tags,
    required this.compatPct,
    required this.compatLevel,
    this.isVerified = true,
    this.hasVoicePrompt = true,
    this.voicePromptText = "My idea of the perfect Sunday morning 🌅",
    this.rpgClass = '⚡ Maverick Explorer',
    this.relationshipIntent = '🛡️ Long-Term Co-Op Partner',
    this.pronouns = 'they/them',
    this.height = "5'8\"",
    this.languages = 'English',
    this.zodiac = '♎ Libra',
    this.lifestyleVitals = const [
      '☕ Coffee Addict',
      '🍷 Socially',
      '🚭 Non-Smoker',
      '🐕 Pet Friendly',
    ],
    this.anthemTitle = 'Midnight City',
    this.anthemArtist = 'M83',
    this.pollQuestion = 'Pick our first Co-Op Quest:',
    this.pollOptions = const [
      '☕ Espresso crawl + bookstore',
      '🌅 Golden Hour park overlook',
      '🕹️ Arcade bar boss battle',
    ],
    this.isFreeTonight = true,
    this.isStandout = false,
  });

  List<String> get effectiveGallery => photoGallery.isNotEmpty
      ? photoGallery
      : [
          photoAsset,
          'assets/images/quest_coffee.png',
          'assets/images/quest_hiking.png',
        ];

  int computeDynamicChemistry(List<String> userTags, String userArchetype) {
    int shared = 0;
    for (final tag in tags) {
      final keyword = tag.split(' ').last.toLowerCase();
      if (userTags.any((u) => u.toLowerCase().contains(keyword))) {
        shared++;
      }
    }
    final classBonus = userArchetype.split(' ').last.toLowerCase() !=
            rpgClass.split(' ').last.toLowerCase()
        ? 4
        : 2;
    return (compatPct + (shared * 2) + classBonus).clamp(72, 99);
  }

  List<String> computeSynergyReasons(
    List<String> userTags,
    String userArchetype,
  ) {
    final reasons = <String>[];
    for (final tag in tags) {
      final keyword = tag.split(' ').last.toLowerCase();
      if (userTags.any((u) => u.toLowerCase().contains(keyword))) {
        reasons.add('Shared passion for $tag (+15% Chemistry)');
      }
    }
    reasons.add(
      'Complementary Party Synergy: $userArchetype × $rpgClass (+20% Co-Op Bonus)',
    );
    if (isFreeTonight) {
      reasons.add('Both active for spontaneous evening quests ⚡');
    }
    return reasons;
  }

  factory Profile.fromCloudMap(Map<String, dynamic> map) {
    final rawId = (map['user_id'] ?? map['id'] ?? 'explorer').toString();
    final rawName = (map['name'] ?? 'Explorer').toString();
    final firstName = rawName.split(' ').first;
    final lower = firstName.toLowerCase();

    String resolvedAsset = 'assets/images/sophia.png';
    if (lower.contains('maya')) {
      resolvedAsset = 'assets/images/maya.png';
    } else if (lower.contains('liam') || lower.contains('jordan')) {
      resolvedAsset = 'assets/images/jordan.png';
    } else if (lower.contains('chloe') || lower.contains('riley')) {
      resolvedAsset = 'assets/images/riley.png';
    } else if (lower.contains('zoe') || lower.contains('taylor')) {
      resolvedAsset = 'assets/images/taylor.png';
    } else if (lower.contains('kael') || lower.contains('alex')) {
      resolvedAsset = 'assets/images/alex.png';
    }

    final rawTags = map['tags'];
    final parsedTags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>['☕ Coffee', '🏔️ Hiking', '✨ Quests'];

    return Profile(
      id: rawId,
      name: rawName,
      age: (map['age'] is int) ? map['age'] as int : 25,
      occupation: (map['city'] ?? 'San Francisco, CA').toString(),
      distance: 'Cloud Synced ☁️',
      photoAsset: resolvedAsset,
      photoGallery: [
        resolvedAsset,
        'assets/images/quest_coffee.png',
        'assets/images/quest_hiking.png',
      ],
      tags: parsedTags,
      compatPct: 91,
      compatLevel: 'high',
      isVerified: map['is_verified'] == true,
      hasVoicePrompt: true,
      voicePromptText: (map['voice_prompt_title'] ??
              map['bio'] ??
              'My ideal first date...')
          .toString(),
      rpgClass: (map['rpg_class'] ?? '⚡ Cloud Vanguard').toString(),
      relationshipIntent: '🛡️ Long-Term Co-Op Partner',
      isFreeTonight: true,
      isStandout: true,
    );
  }

  static List<Profile> get seedProfiles => [
    const Profile(
      id: 'sophia',
      name: 'Sophia',
      age: 24,
      occupation: 'Photographer',
      distance: '2 mi away',
      photoAsset: 'assets/images/sophia.png',
      photoGallery: [
        'assets/images/sophia.png',
        'assets/images/quest_coffee.png',
        'assets/images/quest_hiking.png',
      ],
      tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'],
      compatPct: 92,
      compatLevel: 'high',
      voicePromptText: 'My idea of the perfect Sunday morning 🌅',
      rpgClass: '🎨 Creative Alchemist',
      relationshipIntent: '🛡️ Long-Term Co-Op Partner',
      pronouns: 'she/her',
      height: "5'6\"",
      languages: 'English, French',
      zodiac: '♓ Pisces',
      lifestyleVitals: [
        '☕ Matcha & Espresso',
        '🍷 Wine Nights',
        '🐕 Golden Retriever Mom',
        '🥾 Weekend Hiker',
      ],
      anthemTitle: 'Sunset Lover',
      anthemArtist: 'Petit Biscuit',
      pollQuestion: 'Vote on our Sunday morning quest:',
      pollOptions: [
        '🥐 Tartine Bakery + SFMOMA gallery walk',
        '🌉 Lands End coastal trail with Polaroids',
        '🍵 Hidden Japanese tea garden',
      ],
      isFreeTonight: true,
      isStandout: true,
    ),
    const Profile(
      id: 'alex',
      name: 'Alex',
      age: 27,
      occupation: 'Software Engineer',
      distance: '5 mi away',
      photoAsset: 'assets/images/alex.png',
      photoGallery: [
        'assets/images/alex.png',
        'assets/images/quest_arcade.png',
        'assets/images/quest_coffee.png',
      ],
      tags: ['🎮 Gaming', '🍳 Cooking', '📚 Books'],
      compatPct: 87,
      compatLevel: 'high',
      voicePromptText: 'My secret, completely useless talent 🪄',
      rpgClass: '🌌 Night Owl Strategist',
      relationshipIntent: '🛡️ Long-Term Co-Op Partner',
      pronouns: 'he/him',
      height: "5'11\"",
      languages: 'English, Japanese',
      zodiac: '♏ Scorpio',
      lifestyleVitals: [
        '🕹️ Co-Op Gamer',
        '🍜 Ramen Chef',
        '🚭 Non-Smoker',
        '🏋️ Climbing Gym 4x/wk',
      ],
      anthemTitle: 'Instant Crush',
      anthemArtist: 'Daft Punk ft. Julian Casablancas',
      pollQuestion: 'Which Co-Op challenge are we winning first?',
      pollOptions: [
        '🕹️ Emporium Arcade high-score showdown',
        '🍝 Homemade pasta & tiramisu cook-off',
        '🎲 Strategy board game café night',
      ],
      isFreeTonight: true,
      isStandout: true,
    ),
    const Profile(
      id: 'maya',
      name: 'Maya',
      age: 25,
      occupation: 'Yoga Instructor',
      distance: '3 mi away',
      photoAsset: 'assets/images/maya.png',
      photoGallery: [
        'assets/images/maya.png',
        'assets/images/quest_hiking.png',
        'assets/images/quest_coffee.png',
      ],
      tags: ['🧘 Yoga', '🌱 Vegan', '✈️ Travel'],
      compatPct: 84,
      compatLevel: 'high',
      voicePromptText: 'My most unhinged travel story ✈️',
      rpgClass: '🌿 Zen Pathfinder',
      relationshipIntent: '🗺️ Adventure & Spontaneous Dates',
      pronouns: 'she/her',
      height: "5'7\"",
      languages: 'English, Spanish',
      zodiac: '♊ Gemini',
      lifestyleVitals: [
        '🧘 Daily Flow',
        '🌱 Plant-Based',
        '🌊 Cold Plunge Club',
        '✈️ 18 Countries',
      ],
      anthemTitle: 'Oceans',
      anthemArtist: 'RY X',
      pollQuestion: 'Pick a spontaneous twilight adventure:',
      pollOptions: [
        '🌅 Dolores Park sunset picnic + kombucha',
        '🕯️ Candlelight sound bath & herbal tea',
        '🌮 Vegan street taco crawl in the Mission',
      ],
      isFreeTonight: true,
      isStandout: false,
    ),
    const Profile(
      id: 'jordan',
      name: 'Jordan',
      age: 28,
      occupation: 'Music Producer',
      distance: '1 mi away',
      photoAsset: 'assets/images/jordan.png',
      photoGallery: [
        'assets/images/jordan.png',
        'assets/images/quest_arcade.png',
        'assets/images/quest_coffee.png',
      ],
      tags: ['🎵 Music', '🎬 Film', '🍷 Wine'],
      compatPct: 94,
      compatLevel: 'high',
      voicePromptText: 'What my voice sounds like at 7 AM ☕',
      rpgClass: '🎵 Maverick Bard',
      relationshipIntent: '🗺️ Adventure & Spontaneous Dates',
      pronouns: 'he/they',
      height: "6'0\"",
      languages: 'English',
      zodiac: '♌ Leo',
      lifestyleVitals: [
        '🎹 Vinyl Collector',
        '🍷 Natural Wine',
        '🎬 A24 Film Buff',
        '🌙 Late Night Studio',
      ],
      anthemTitle: 'Electric Feel',
      anthemArtist: 'MGMT',
      pollQuestion: 'Our ideal Friday night soundtrack:',
      pollOptions: [
        '🎷 Underground jazz speakeasy',
        '💿 Vinyl crate-digging + espresso martinis',
        '🍿 35mm midnight screening at The Castro',
      ],
      isFreeTonight: false,
      isStandout: true,
    ),
    const Profile(
      id: 'riley',
      name: 'Riley',
      age: 23,
      occupation: 'Med Student',
      distance: '4 mi away',
      photoAsset: 'assets/images/riley.png',
      photoGallery: [
        'assets/images/riley.png',
        'assets/images/quest_hiking.png',
        'assets/images/quest_coffee.png',
      ],
      tags: ['🏃 Running', '🐕 Dogs', '📖 Reading'],
      compatPct: 81,
      compatLevel: 'medium',
      voicePromptText: 'Hot take on pineapple pizza 🍕',
      rpgClass: '🛡️ Guardian Healer',
      relationshipIntent: '🛡️ Long-Term Co-Op Partner',
      pronouns: 'she/her',
      height: "5'5\"",
      languages: 'English, Mandarin',
      zodiac: '♍ Virgo',
      lifestyleVitals: [
        '🏃 Half-Marathoner',
        '🐕 Shelter Volunteer',
        '☕ Oat Latte Loyal',
        '📚 Sci-Fi Reader',
      ],
      anthemTitle: 'Golden Hour',
      anthemArtist: 'JVKE',
      pollQuestion: 'Best way to recharge after a 12-hour shift:',
      pollOptions: [
        '🐕 Crissy Field dog beach walk',
        '🍜 Steaming hot pot + cozy conversation',
        '🍦 Bi-Rite ice cream on the steps',
      ],
      isFreeTonight: false,
      isStandout: false,
    ),
    const Profile(
      id: 'taylor',
      name: 'Taylor',
      age: 26,
      occupation: 'Product Designer',
      distance: '6 mi away',
      photoAsset: 'assets/images/taylor.png',
      photoGallery: [
        'assets/images/taylor.png',
        'assets/images/quest_coffee.png',
        'assets/images/quest_arcade.png',
      ],
      tags: ['🎨 Design', '☕ Coffee', '🎸 Guitar'],
      compatPct: 89,
      compatLevel: 'high',
      voicePromptText: 'My most unhinged travel story ✈️',
      rpgClass: '✨ Arcane Architect',
      relationshipIntent: '✨ New In Town / Open to Sparks',
      pronouns: 'they/them',
      height: "5'9\"",
      languages: 'English, Italian',
      zodiac: '♒ Aquarius',
      lifestyleVitals: [
        '🎨 Ceramics Studio',
        '🎸 Indie Acoustic',
        '☕ Pour-Over Snob',
        '🚲 Fixed-Gear Cyclist',
      ],
      anthemTitle: 'Space Song',
      anthemArtist: 'Beach House',
      pollQuestion: 'Rate my ideal Saturday date:',
      pollOptions: [
        '🏺 Pottery wheel class + matcha',
        '🎸 Acoustic jam session in Golden Gate Park',
        '🥟 Chinatown dim sum treasure hunt',
      ],
      isFreeTonight: true,
      isStandout: true,
    ),
  ];
}
