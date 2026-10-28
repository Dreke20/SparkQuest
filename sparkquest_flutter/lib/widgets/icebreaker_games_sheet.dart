import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/quest_progression_service.dart';

class IcebreakerGamesSheet extends StatefulWidget {
  final String matchName;
  final Function(String messageText) onSendGameMessage;
  final Function(int embers)? onAwardEmbers;

  const IcebreakerGamesSheet({
    super.key,
    required this.matchName,
    required this.onSendGameMessage,
    this.onAwardEmbers,
  });

  @override
  State<IcebreakerGamesSheet> createState() => _IcebreakerGamesSheetState();
}

class _IcebreakerGamesSheetState extends State<IcebreakerGamesSheet> {
  int _selectedTab = 0; // 0: Trivia, 1: 2 Truths, 2: Would You Rather, 3: Emoji

  // Trivia state
  int _triviaIndex = 0;
  int _triviaScore = 0;
  int? _selectedTriviaOption;
  bool _triviaFinished = false;

  // 2 Truths & 1 Lie state
  int? _selectedLieIndex;

  // Would You Rather state
  int _wyrIndex = 0;
  int? _selectedWyrChoice;

  // Emoji Charades state
  int? _selectedEmojiOption;

  final List<Map<String, dynamic>> _triviaQuestions = [
    {
      'q': 'What is the ideal first-date duration according to relationship psychologists?',
      'options': ['45–60 minutes (Coffee/Drink)', '4 hours (Dinner + Movie)', '15 minutes (Speed Date)'],
      'answer': 0,
    },
    {
      'q': 'Which neurotransmitter surges the most during an exciting new "Spark" connection?',
      'options': ['Melatonin', 'Dopamine', 'Cortisol'],
      'answer': 1,
    },
    {
      'q': 'In co-op adventure games, what role is known for supporting and protecting the team?',
      'options': ['Paladin / Healer 🛡️', 'Rogue Assassin 🗡️', 'Solo Berserker 🪓'],
      'answer': 0,
    },
  ];

  final List<Map<String, dynamic>> _twoTruths = [
    {'text': 'I once hiked a volcano at 4 AM just to watch the sunrise 🌋', 'isLie': false},
    {'text': 'I can make latte art that actually looks like a swan ☕', 'isLie': false},
    {'text': 'I have never eaten pizza in my entire life 🍕', 'isLie': true},
  ];

  final List<Map<String, dynamic>> _wyrList = [
    {
      'q': 'For our spontaneous weekend quest, would you rather...',
      'a': '🌲 Rent a cozy glass cabin in the mountains',
      'b': '🌃 Explore hidden speakeasies & late-night ramen in the city',
      'pctA': 64,
    },
    {
      'q': 'When traveling together, would you rather...',
      'a': '🗺️ Have every hour planned on an itinerary',
      'b': '🎲 Show up at the airport and wing the whole trip',
      'pctA': 48,
    },
  ];

  final Map<String, dynamic> _emojiPuzzle = {
    'emojis': '☕ ➕ 🎨 🖼️ ➕ 🌇 🍸',
    'hint': 'Decode ${'this'} ultimate first date combo:',
    'options': [
      'Coffee, Art Gallery & Sunset Rooftop Drinks',
      'Morning Gym, Painting a House & Juice Bar',
      'Late Night Coding, Museum & Camping',
    ],
    'answer': 0,
  };

  void _answerTrivia(int idx) {
    if (_selectedTriviaOption != null) return;
    HapticFeedback.selectionClick();
    final isCorrect = idx == (_triviaQuestions[_triviaIndex]['answer'] as int);
    setState(() {
      _selectedTriviaOption = idx;
      if (isCorrect) _triviaScore++;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_triviaIndex < _triviaQuestions.length - 1) {
        setState(() {
          _triviaIndex++;
          _selectedTriviaOption = null;
        });
      } else {
        setState(() => _triviaFinished = true);
        QuestProgressionService.instance.incrementQuest('engage6', xpGain: 30);
        widget.onAwardEmbers?.call(35);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
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
                Row(
                  children: [
                    const Text('🎮 ', style: TextStyle(fontSize: 20)),
                    Text(
                      'Spark Arcade vs. ${widget.matchName}',
                      style: const TextStyle(
                        fontSize: 18,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabPill(0, '⚡ Trivia Duel'),
                  const SizedBox(width: 8),
                  _buildTabPill(1, '🎭 2 Truths 1 Lie'),
                  const SizedBox(width: 8),
                  _buildTabPill(2, '🔥 Would You Rather'),
                  const SizedBox(width: 8),
                  _buildTabPill(3, '🧩 Emoji Charades'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_selectedTab == 0) _buildTriviaView(),
            if (_selectedTab == 1) _buildTwoTruthsView(),
            if (_selectedTab == 2) _buildWyrView(),
            if (_selectedTab == 3) _buildEmojiCharadesView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.electricViolet : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.neonCyan : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTriviaView() {
    if (_triviaFinished) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.questGold.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              'You scored $_triviaScore / ${_triviaQuestions.length}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '+35 Embers earned! Challenge your match to beat your score.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.questGold, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sparkCoral,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onSendGameMessage(
                  '⚡ [Trivia Duel] I just scored $_triviaScore/${_triviaQuestions.length} in the Spark Trivia Duel! Bet you can’t beat my score 🏆',
                );
              },
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              label: const Text(
                'Send Challenge to Chat (+35🔥)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final current = _triviaQuestions[_triviaIndex];
    final options = current['options'] as List<String>;
    final correctIdx = current['answer'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_triviaIndex + 1} of ${_triviaQuestions.length}',
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Score: $_triviaScore',
              style: const TextStyle(
                color: AppTheme.questGold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          current['q'] as String,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(options.length, (i) {
          final isSelected = _selectedTriviaOption == i;
          final showResult = _selectedTriviaOption != null;
          Color borderColor = Colors.white12;
          if (showResult && i == correctIdx) {
            borderColor = AppTheme.emeraldGreen;
          } else if (isSelected && i != correctIdx) {
            borderColor = AppTheme.sparkCoral;
          }

          return GestureDetector(
            onTap: () => _answerTrivia(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      options[i],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  if (showResult && i == correctIdx)
                    const Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 18)
                  else if (isSelected && i != correctIdx)
                    const Icon(Icons.cancel, color: AppTheme.sparkCoral, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTwoTruthsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spot ${widget.matchName}’s Lie 🕵️',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Two of these are true, one is a total bluff. Tap the lie!',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...List.generate(_twoTruths.length, (i) {
          final item = _twoTruths[i];
          final isSelected = _selectedLieIndex == i;
          final isLie = item['isLie'] as bool;
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _selectedLieIndex = i);
              if (isLie) {
                widget.onAwardEmbers?.call(25);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedLieIndex == null
                      ? Colors.white12
                      : (isLie
                          ? AppTheme.emeraldGreen
                          : (isSelected ? AppTheme.sparkCoral : Colors.white12)),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppTheme.bgInput,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['text'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  if (_selectedLieIndex != null)
                    Text(
                      isLie ? '🤥 LIE!' : '✅ TRUE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLie ? AppTheme.emeraldGreen : AppTheme.textDim,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        if (_selectedLieIndex != null) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricViolet,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onSendGameMessage(
                '🎭 [2 Truths & A Lie] I spotted your lie! "${_twoTruths[2]['text']}" — now guess mine!',
              );
            },
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text(
              'Share Result to Chat (+25🔥)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWyrView() {
    final current = _wyrList[_wyrIndex];
    final pctA = current['pctA'] as int;
    final pctB = 100 - pctA;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          current['q'] as String,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        _wyrCard(0, current['a'] as String, pctA),
        const SizedBox(height: 10),
        _wyrCard(1, current['b'] as String, pctB),
        const SizedBox(height: 12),
        if (_selectedWyrChoice != null)
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _wyrIndex = (_wyrIndex + 1) % _wyrList.length;
                    _selectedWyrChoice = null;
                  });
                },
                child: const Text(
                  'Next Dilemma 🔄',
                  style: TextStyle(color: AppTheme.neonCyan),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkCoral,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final picked = _selectedWyrChoice == 0
                      ? current['a'] as String
                      : current['b'] as String;
                  Navigator.pop(context);
                  widget.onSendGameMessage(
                    '🔥 [Would You Rather] I picked: "$picked" — which one are you choosing?',
                  );
                },
                icon: const Icon(Icons.send, size: 16, color: Colors.white),
                label: const Text(
                  'Ask in Chat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _wyrCard(int choiceIdx, String label, int pct) {
    final selected = _selectedWyrChoice == choiceIdx;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedWyrChoice = choiceIdx);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_selectedWyrChoice != null)
              Text(
                '$pct% agree',
                style: const TextStyle(
                  color: AppTheme.questGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiCharadesView() {
    final options = _emojiPuzzle['options'] as List<String>;
    final correct = _emojiPuzzle['answer'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Decode the Emoji Date Clue 🧩',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.questGold.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              _emojiPuzzle['emojis'] as String,
              style: const TextStyle(fontSize: 28, letterSpacing: 4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(options.length, (i) {
          final isSelected = _selectedEmojiOption == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _selectedEmojiOption = i);
              if (i == correct) {
                widget.onAwardEmbers?.call(30);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedEmojiOption == null
                      ? Colors.white12
                      : (i == correct
                          ? AppTheme.emeraldGreen
                          : (isSelected ? AppTheme.sparkCoral : Colors.white12)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      options[i],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  if (_selectedEmojiOption != null && i == correct)
                    const Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 18),
                ],
              ),
            ),
          );
        }),
        if (_selectedEmojiOption != null) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onSendGameMessage(
                '🧩 [Emoji Charades] Cracked the code: ☕➕🎨➕🌇🍸 = Coffee, Art Gallery & Sunset Rooftop Drinks! When are we going?',
              );
            },
            icon: const Icon(Icons.send, size: 16, color: Colors.white),
            label: const Text(
              'Send Decoded Date to Chat (+30🔥)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

