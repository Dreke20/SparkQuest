import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class SparkyAiWingmanSheet extends StatefulWidget {
  final VoidCallback? onBioUpdated;

  const SparkyAiWingmanSheet({super.key, this.onBioUpdated});

  @override
  State<SparkyAiWingmanSheet> createState() => _SparkyAiWingmanSheetState();
}

class _SparkyAiWingmanSheetState extends State<SparkyAiWingmanSheet> {
  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  String _selectedArchetype = '🌌 Night Owl Strategist';
  int _rizzScore = 88;
  String _aiFeedback =
      'Strong hook! Adding a specific weekend quest idea boosts match replies by +34%.';

  final List<String> _archetypes = [
    '🌌 Night Owl Strategist',
    '🏔️ Trailblazing Adventurer',
    '☕ Cozy Artisan Explorer',
    '🎵 Indie Vibe Curator',
  ];

  final List<String> _aiBioPresets = [
    'Building cool apps by day, chasing rooftop sunsets & co-op quests by night ✨ Down for spontaneous pour-over coffee runs.',
    'Part-time trail runner, full-time espresso connoisseur ☕ Looking for a player 2 to conquer local food trucks & trivia nights 🏆',
    'Equal parts indie art gallery strolls and chaotic board game duels 🎲 Tell me your most unhinged travel story ✈️',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(
      text: StorageService.instance.getUserBio(),
    );
    _occupationController = TextEditingController(
      text: StorageService.instance.getUserOccupation(),
    );
    _selectedArchetype = StorageService.instance.getUserArchetype();
    _analyzeBio(_bioController.text);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _analyzeBio(String text) {
    final len = text.trim().length;
    int score = 65;
    if (len > 40) score += 15;
    if (len > 80) score += 10;
    if (text.contains('✨') ||
        text.contains('☕') ||
        text.contains('🏆') ||
        text.contains('✈️')) {
      score += 8;
    }
    score = score.clamp(45, 99);

    String feedback;
    if (score >= 90) {
      feedback =
          '🔥 S-Tier Explorer Bio! High specificity + conversation hooks detected.';
    } else if (score >= 78) {
      feedback =
          '✨ Great vibe! Try adding a question or emoji hook to spark instant replies.';
    } else {
      feedback =
          '💡 A bit short! Tap one of Sparky’s AI Polish presets below to boost your match rate.';
    }

    setState(() {
      _rizzScore = score;
      _aiFeedback = feedback;
    });
  }

  Future<void> _saveProfileChanges() async {
    HapticFeedback.mediumImpact();
    await StorageService.instance.saveUserBio(_bioController.text.trim());
    await StorageService.instance.saveUserOccupation(
      _occupationController.text.trim(),
    );
    await StorageService.instance.saveUserArchetype(_selectedArchetype);
    widget.onBioUpdated?.call();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Profile & Bio updated with Sparky AI!'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppTheme.questGold,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sparky AI Wingman & Bio Coach',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textDim),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Live Bio Score Meter
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '⚡ AI PROFILE MAGNETISM SCORE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonCyan,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '$_rizzScore / 100',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.questGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _rizzScore / 100.0,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.neonCyan,
                          ),
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiFeedback,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Occupation Input
                const Text(
                  'OCCUPATION / TITLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _occupationController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Bio Input
                const Text(
                  'YOUR SPARK BIO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  onChanged: _analyzeBio,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 1-Tap AI Bio Polish Presets
                const Text(
                  '✨ 1-TAP AI BIO REWRITES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.questGold,
                  ),
                ),
                const SizedBox(height: 6),
                ...List.generate(_aiBioPresets.length, (i) {
                  final preset = _aiBioPresets[i];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _bioController.text = preset;
                      _analyzeBio(preset);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: AppTheme.questGold,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              preset,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Explorer Archetype Selector
                const Text(
                  'EXPLORER ARCHETYPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _archetypes.map((arch) {
                    final active = _selectedArchetype == arch;
                    return ChoiceChip(
                      label: Text(arch),
                      selected: active,
                      selectedColor: AppTheme.electricViolet,
                      backgroundColor: AppTheme.bgCard,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : AppTheme.textSecondary,
                        fontSize: 11.5,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedArchetype = arch);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sparkCoral,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saveProfileChanges,
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  label: const Text(
                    'Save Profile & Bio Upgrades',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
}

