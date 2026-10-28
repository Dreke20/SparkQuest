import 'package:flutter/foundation.dart';
import '../models/quest.dart';
import 'storage_service.dart';

class QuestProgressionService extends ChangeNotifier {
  static final QuestProgressionService instance =
      QuestProgressionService._internal();
  QuestProgressionService._internal();

  List<QuestItem> _quests = QuestItem.initialQuests;
  int _seasonXp = 450;
  bool _initialized = false;

  List<QuestItem> get quests {
    if (!_initialized) {
      loadFromStorage();
    }
    return _quests;
  }

  int get seasonXp {
    if (!_initialized) {
      loadFromStorage();
    }
    return _seasonXp;
  }

  void loadFromStorage() {
    _initialized = true;
    _seasonXp = StorageService.instance.getSeasonXp();
    final savedMap = StorageService.instance.getQuestProgressMap();
    _quests = QuestItem.initialQuests.map((q) {
      if (savedMap.containsKey(q.id)) {
        final itemData = Map<String, dynamic>.from(savedMap[q.id] as Map);
        q.current = (itemData['current'] as int?) ?? q.current;
        q.isClaimed = (itemData['isClaimed'] as bool?) ?? q.isClaimed;
      }
      return q;
    }).toList();
  }

  void incrementQuest(String questId, {int amount = 1, int xpGain = 20}) {
    if (!_initialized) loadFromStorage();

    _seasonXp += xpGain;
    StorageService.instance.saveSeasonXp(_seasonXp);

    for (final q in _quests) {
      if (q.id == questId && q.current < q.target) {
        q.current = (q.current + amount).clamp(0, q.target);
      }
    }
    _persistQuests();
    notifyListeners();
  }

  void addSeasonXp(int xpGain) {
    if (!_initialized) loadFromStorage();
    _seasonXp += xpGain;
    StorageService.instance.saveSeasonXp(_seasonXp);
    notifyListeners();
  }

  void claimQuest(String questId) {
    if (!_initialized) loadFromStorage();
    for (final q in _quests) {
      if (q.id == questId && q.isCompleted && !q.isClaimed) {
        q.isClaimed = true;
        _seasonXp += 50;
        StorageService.instance.saveSeasonXp(_seasonXp);
      }
    }
    _persistQuests();
    notifyListeners();
  }

  void _persistQuests() {
    final map = <String, dynamic>{};
    for (final q in _quests) {
      map[q.id] = q.toJson();
    }
    StorageService.instance.saveQuestProgressMap(map);
  }
}

