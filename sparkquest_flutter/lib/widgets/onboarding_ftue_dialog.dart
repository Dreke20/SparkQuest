import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/quest_progression_service.dart';

class OnboardingFtueDialog extends StatefulWidget {
  final Function(int bonusEmbers) onCompleted;

  const OnboardingFtueDialog({super.key, required this.onCompleted});

  @override
  State<OnboardingFtueDialog> createState() => _OnboardingFtueDialogState();
}

class _OnboardingFtueDialogState extends State<OnboardingFtueDialog> {
  int _step = 0;
  String _selectedClass = '🌌 Night Owl Strategist';
  final Set<String> _selectedTags = {'🎮 Gaming', '☕ Coffee', '🏔️ Hiking'};

  final List<Map<String, String>> _classes = [
    {
      'title': '🌌 Night Owl Strategist',
      'desc': 'Late-night ramen, rooftop stargazing & deep co-op quests',
    },
    {
      'title': '🏔️ Trailblazing Adventurer',
      'desc': 'Sunrise peaks, spontaneous road trips & outdoor thrills',
    },
    {
      'title': '☕ Cozy Artisan Explorer',
      'desc': 'Pour-over cafes, indie bookstores & rainy gallery strolls',
    },
    {
      'title': '🎵 Indie Vibe Curator',
      'desc': 'Vinyl lounges, live acoustic sets & hidden speakeasies',
    },
  ];

  final List<String> _allTags = [
    '🎨 Art',
    '🏔️ Hiking',
    '☕ Coffee',
    '🎮 Gaming',
    '🎵 Music',
    '🧘 Yoga',
    '🍳 Cooking',
    '✈️ Travel',
    '🎬 Film',
    '🐕 Dogs',
  ];

  Future<void> _finishOnboarding() async {
    HapticFeedback.heavyImpact();
    await StorageService.instance.saveUserArchetype(_selectedClass);
    await StorageService.instance.saveUserVibeTags(_selectedTags.toList());
    await StorageService.instance.setFtueCompleted(true);
    QuestProgressionService.instance.addSeasonXp(100);
    if (mounted) {
      Navigator.pop(context);
      widget.onCompleted(100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EXPLORER ONBOARDING • STEP ${_step + 1}/3',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonCyan,
                      letterSpacing: 1.1,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textDim,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3.0,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.questGold,
                  ),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 16),

              if (_step == 0) _buildClassStep(),
              if (_step == 1) _buildVibeTagsStep(),
              if (_step == 2) _buildRewardStep(),

              const SizedBox(height: 18),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _step == 2
                          ? AppTheme.questGold
                          : AppTheme.sparkCoral,
                      foregroundColor: _step == 2 ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _finishOnboarding();
                      }
                    },
                    child: Text(
                      _step == 2
                          ? 'Claim +100🔥 & Launch'
                          : 'Next Step →',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your RPG Dating Archetype 🛡️',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your archetype powers our 6-Axis Vibe Radar and co-op date quests.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 14),
        ..._classes.map((c) {
          final title = c['title']!;
          final selected = _selectedClass == title;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedClass = title);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.electricViolet.withValues(alpha: 0.25)
                    : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppTheme.neonCyan : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c['desc']!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVibeTagsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick Your Core Vibe Signals ✨',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select at least 3 interests so Sparky AI can match your frequency.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              selectedColor: AppTheme.electricViolet,
              checkmarkColor: AppTheme.neonCyan,
              backgroundColor: AppTheme.bgCard,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (val) {
                    _selectedTags.add(tag);
                  } else if (_selectedTags.length > 1) {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRewardStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.questGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text(
            'Explorer Starter Chest Ready!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Class: $_selectedClass',
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vibes: ${_selectedTags.join(' • ')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.questGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '+100 Embers 🔥  •  +100 Season Pass XP ⭐',
              style: TextStyle(
                color: AppTheme.questGold,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

