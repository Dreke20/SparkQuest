import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkquest/main.dart';
import 'package:sparkquest/models/profile.dart';
import 'package:sparkquest/services/quest_progression_service.dart';
import 'package:sparkquest/services/realtime_chat_service.dart';
import 'package:sparkquest/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    QuestProgressionService.instance.loadFromStorage();
  });

  testWidgets('SparkQuest main navigation across all 5 core tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SparkQuestApp());
    await tester.pump();

    expect(find.text('SPARKQUEST'), findsOneWidget);
    expect(find.text('Mystery Match'), findsOneWidget);

    // Navigate to Radar Map tab
    await tester.tap(find.text('Radar Map'));
    await tester.pump();
    expect(find.text('✨ All Radar'), findsOneWidget);
    expect(find.text('🎉 Live Events'), findsOneWidget);

    // Navigate to Matches tab
    await tester.tap(find.text('Matches'));
    await tester.pump();
    expect(find.text('Messages'), findsOneWidget);

    // Navigate to Quests tab
    await tester.tap(find.text('Quests'));
    await tester.pump();
    expect(find.text('Daily Quests'), findsOneWidget);
    expect(find.text('Like 10 Profiles on Radar'), findsOneWidget);

    // Navigate to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('Edit Bio & AI Coach'), findsOneWidget);
  });

  test('QuestProgressionService increments quest progress and Season XP', () {
    final initialXp = QuestProgressionService.instance.seasonXp;
    QuestProgressionService.instance.incrementQuest(
      'engage6',
      amount: 1,
      xpGain: 30,
    );

    expect(QuestProgressionService.instance.seasonXp, initialXp + 30);
    final arcadeQuest = QuestProgressionService.instance.quests.firstWhere(
      (q) => q.id == 'engage6',
    );
    expect(arcadeQuest.isCompleted, isTrue);
  });

  test('RealtimeChatService adds new sparked profile to conversations', () {
    const rileyProfile = Profile(
      id: 'riley',
      name: 'Riley',
      age: 23,
      occupation: 'Med Student',
      distance: '4 mi away',
      photoAsset: 'assets/images/riley.png',
      tags: ['🏃 Running', '🐕 Dogs'],
      compatPct: 75,
      compatLevel: 'medium',
    );

    final added = RealtimeChatService.instance.addMatchFromProfile(
      rileyProfile,
    );
    expect(added.name, 'Riley');
    expect(
      RealtimeChatService.instance.getConversations().any(
        (c) => c.name == 'Riley',
      ),
      isTrue,
    );
  });

  test('StorageService blocks and unblocks users cleanly', () async {
    await StorageService.instance.blockUser('taylor');
    expect(StorageService.instance.getBlockedUsers(), contains('taylor'));

    await StorageService.instance.unblockUser('taylor');
    expect(
      StorageService.instance.getBlockedUsers(),
      isNot(contains('taylor')),
    );
  });

  test('RealtimeChatService triggers and ends Phase 5 live call signaling', () async {
    Map<String, dynamic>? receivedSignal;
    RealtimeChatService.instance.onIncomingCall = (signal) {
      receivedSignal = signal;
    };

    RealtimeChatService.instance.triggerIncomingCall(
      callerName: 'Maya',
      callerAvatar: 'assets/images/maya.png',
      isVoiceOnly: false,
    );

    expect(RealtimeChatService.instance.callSignalState, 'ringing');
    expect(receivedSignal, isNotNull);
    expect(receivedSignal!['caller_name'], 'Maya');

    await RealtimeChatService.instance.endCallSignal();
    expect(RealtimeChatService.instance.callSignalState, 'ended');
  });
}
