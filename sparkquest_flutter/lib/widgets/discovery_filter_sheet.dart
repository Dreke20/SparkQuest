import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class DiscoveryFilterSheet extends StatefulWidget {
  final VoidCallback onFiltersChanged;

  const DiscoveryFilterSheet({super.key, required this.onFiltersChanged});

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  late RangeValues _ageRange;
  late double _maxDistance;
  late bool _verifiedOnly;
  late String _selectedVibe;
  late String _selectedIntent;
  late bool _dealbreakerStrict;
  late String _teleportCity;
  late bool _freeTonightOnly;

  final List<String> _vibes = [
    'All Vibes',
    '🎨 Art',
    '🏔️ Hiking',
    '☕ Coffee',
    '🎮 Gaming',
    '🎵 Music',
    '🧘 Yoga',
  ];

  final List<String> _intents = [
    'All Intents',
    '🛡️ Long-Term Co-Op Partner',
    '🗺️ Adventure & Spontaneous Dates',
    '✨ New In Town / Open to Sparks',
  ];

  final List<String> _cities = [
    'San Francisco, CA',
    'New York City, NY',
    'Austin, TX',
    'Tokyo, Japan',
    'London, UK',
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      StorageService.instance.getMinAge().toDouble(),
      StorageService.instance.getMaxAge().toDouble(),
    );
    _maxDistance = StorageService.instance.getMaxDistance().toDouble();
    _verifiedOnly = StorageService.instance.getVerifiedOnly();
    _selectedVibe = StorageService.instance.getSelectedVibe();
    _selectedIntent = StorageService.instance.getSelectedIntent();
    _dealbreakerStrict = StorageService.instance.isDealbreakerStrict();
    _teleportCity = StorageService.instance.getTeleportCity();
    _freeTonightOnly = StorageService.instance.isFreeTonightFilter();
  }

  Future<void> _saveAndApply() async {
    HapticFeedback.mediumImpact();
    await StorageService.instance.saveDiscoveryFilters(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _maxDistance.round(),
      verifiedOnly: _verifiedOnly,
      vibe: _selectedVibe,
    );
    await StorageService.instance.saveSelectedIntent(_selectedIntent);
    await StorageService.instance.setDealbreakerStrict(_dealbreakerStrict);
    await StorageService.instance.saveTeleportCity(_teleportCity);
    await StorageService.instance.setFreeTonightFilter(_freeTonightOnly);
    widget.onFiltersChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _resetFilters() async {
    HapticFeedback.lightImpact();
    setState(() {
      _ageRange = const RangeValues(18, 38);
      _maxDistance = 25;
      _verifiedOnly = false;
      _selectedVibe = 'All Vibes';
      _selectedIntent = 'All Intents';
      _dealbreakerStrict = false;
      _teleportCity = 'San Francisco, CA';
      _freeTonightOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
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
                      Icon(Icons.tune, color: AppTheme.neonCyan, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Discovery Radar & Dealbreakers',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: AppTheme.sparkCoral,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // #13: Teleport / Passport Mode
              const Text(
                '🌍 PASSPORT / TELEPORT PORTAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.questGold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cities.map((city) {
                    final selected = _teleportCity == city;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(city),
                        selected: selected,
                        selectedColor: AppTheme.questGold,
                        backgroundColor: AppTheme.bgCard,
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _teleportCity = city);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // #4: Relationship Intent Filter
              const Text(
                'DATING INTENT & QUEST GOAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.emeraldGreen,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _intents.map((intent) {
                  final selected = _selectedIntent == intent;
                  return ChoiceChip(
                    label: Text(intent),
                    selected: selected,
                    selectedColor: AppTheme.emeraldGreen,
                    backgroundColor: AppTheme.bgCard,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : AppTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11.5,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIntent = intent);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Vibe Filter Chips
              const Text(
                'VIBE & INTERESTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vibes.map((vibe) {
                  final selected = _selectedVibe == vibe;
                  return ChoiceChip(
                    label: Text(vibe),
                    selected: selected,
                    selectedColor: AppTheme.electricViolet,
                    backgroundColor: AppTheme.bgCard,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedVibe = vibe);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Age Range Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AGE RANGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.questGold,
                    ),
                  ),
                  Text(
                    '${_ageRange.start.round()} – ${_ageRange.end.round()} yrs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 50,
                divisions: 32,
                activeColor: AppTheme.questGold,
                inactiveColor: Colors.white12,
                onChanged: (val) => setState(() => _ageRange = val),
              ),

              // Distance Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MAXIMUM DISTANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  Text(
                    'Within ${_maxDistance.round()} mi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: AppTheme.neonCyan,
                inactiveColor: Colors.white12,
                onChanged: (val) => setState(() => _maxDistance = val),
              ),

              // #12: Hard Dealbreaker Strict Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: AppTheme.sparkCoral,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Strict Dealbreaker Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Never show profiles outside my exact filters',
                              style: TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _dealbreakerStrict,
                      activeThumbColor: AppTheme.sparkCoral,
                      onChanged: (val) =>
                          setState(() => _dealbreakerStrict = val),
                    ),
                  ],
                ),
              ),

              // #14: Free Tonight Only Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: AppTheme.questGold, size: 20),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free Tonight Only ⚡',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Show adventurers ready for a spontaneous date',
                              style: TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _freeTonightOnly,
                      activeThumbColor: AppTheme.questGold,
                      onChanged: (val) =>
                          setState(() => _freeTonightOnly = val),
                    ),
                  ],
                ),
              ),

              // Verified Only Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppTheme.emeraldGreen,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Profiles Only',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '3D Liveness Anti-Catfish verified',
                              style: TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _verifiedOnly,
                      activeThumbColor: AppTheme.emeraldGreen,
                      onChanged: (val) => setState(() => _verifiedOnly = val),
                    ),
                  ],
                ),
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
                onPressed: _saveAndApply,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Apply Radar Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
