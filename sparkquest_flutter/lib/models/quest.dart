class QuestItem {
  final String id;
  final String title;
  final String icon;
  int current;
  final int target;
  final int reward;
  bool isClaimed;

  QuestItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
    required this.reward,
    this.isClaimed = false,
  });

  bool get isCompleted => current >= target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'current': current,
        'isClaimed': isClaimed,
      };

  static List<QuestItem> get initialQuests => [
    QuestItem(
      id: 'engage1',
      title: 'Like 10 Profiles on Radar',
      icon: '💜',
      current: 7,
      target: 10,
      reward: 20,
    ),
    QuestItem(
      id: 'engage2',
      title: 'Send 3 Thoughtful Openers',
      icon: '💬',
      current: 1,
      target: 3,
      reward: 30,
    ),
    QuestItem(
      id: 'engage3',
      title: 'Update Profile Bio & Vibe',
      icon: '📸',
      current: 1,
      target: 1,
      reward: 20,
      isClaimed: true,
    ),
    QuestItem(
      id: 'engage4',
      title: 'Check In at a Local Map Spot',
      icon: '📍',
      current: 0,
      target: 1,
      reward: 50,
    ),
    QuestItem(
      id: 'engage5',
      title: 'Collect a Map Ember Drop',
      icon: '🔥',
      current: 0,
      target: 1,
      reward: 15,
    ),
    QuestItem(
      id: 'engage6',
      title: 'Play an Icebreaker Arcade Game',
      icon: '🎮',
      current: 0,
      target: 1,
      reward: 35,
    ),
  ];
}
