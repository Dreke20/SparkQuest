import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkquest/main.dart';
import 'package:sparkquest/models/profile.dart';
import 'package:sparkquest/services/quest_progression_service.dart';
import 'package:sparkquest/services/realtime_chat_service.dart';
import 'package:sparkquest/services/storage_service.dart';
import 'package:sparkquest/services/supabase_service.dart';

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
    expect(find.textContaining('Standouts'), findsOneWidget);

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

  test('Profile.fromCloudMap parses Supabase Cloud profile rows cleanly', () {
    final cloudProfile = Profile.fromCloudMap({
      'user_id': 'user_kael',
      'name': 'Kaelen Mercer',
      'age': 28,
      'city': 'San Francisco, CA',
      'tags': ['Robotics', 'Espresso', 'Kayaking'],
      'is_verified': true,
      'voice_prompt_title': 'Geekiest obsession: Custom mechanical keyboards',
    });

    expect(cloudProfile.id, 'user_kael');
    expect(cloudProfile.name, 'Kaelen Mercer');
    expect(cloudProfile.age, 28);
    expect(cloudProfile.isVerified, isTrue);
    expect(cloudProfile.photoAsset, 'assets/images/alex.png');
  });

  test('StorageService tracks daily fortune wheel free spin cooldown', () async {
    expect(StorageService.instance.hasUsedFreeDailySpinToday(), isFalse);
    await StorageService.instance.markFreeDailySpinUsedToday();
    expect(StorageService.instance.hasUsedFreeDailySpinToday(), isTrue);
  });

  test('Phase 7 to 12: Dynamic chemistry engine & Teleport preferences', () async {
    final sophia = Profile.seedProfiles.first;
    final chem = sophia.computeDynamicChemistry(
      ['☕ Coffee', '🏔️ Hiking'],
      '🌌 Night Owl Strategist',
    );
    expect(chem, greaterThanOrEqualTo(sophia.compatPct));
    expect(sophia.effectiveGallery.length, greaterThanOrEqualTo(3));

    await StorageService.instance.saveTeleportCity('Tokyo, Japan');
    expect(StorageService.instance.getTeleportCity(), 'Tokyo, Japan');
  });

  test('Economy & Monetization Balance: spend guards, daily grant & inventory', () async {
    expect(StorageService.instance.getEmbers(), 150);
    expect(StorageService.instance.canAffordEmbers(200), isFalse);
    expect(await StorageService.instance.spendEmbers(200), isFalse);
    expect(StorageService.instance.getEmbers(), 150);

    expect(await StorageService.instance.spendEmbers(40), isTrue);
    expect(StorageService.instance.getEmbers(), 110);

    expect(StorageService.instance.hasClaimedDailyGrantToday(), isFalse);
    await StorageService.instance.markDailyGrantClaimedToday();
    expect(StorageService.instance.hasClaimedDailyGrantToday(), isTrue);

    await StorageService.instance.addInventoryItem('rose', 2);
    expect(StorageService.instance.getInventoryCount('rose'), 2);
  });

  test('Phase 13 (v2.1.0): Drop-In Voice Lounges & User Profile State', () async {
    final lounges = await SupabaseService.instance.fetchVoiceLounges();
    expect(lounges.length, greaterThanOrEqualTo(3));
    expect(lounges.first['title'], contains('Espresso'));

    final joined = await SupabaseService.instance.joinVoiceLounge(
      loungeId: 'lounge_coffee',
      userId: 'user_test',
      userName: 'Test Explorer',
    );
    expect(joined, isTrue);

    final left = await SupabaseService.instance.leaveVoiceLounge('lounge_coffee', 'user_test');
    expect(left, isTrue);

    await StorageService.instance.saveUserName('Alex Navigator');
    expect(StorageService.instance.getUserName(), 'Alex Navigator');
  });

  test('Phase 14 (v2.1.0): BLE Proximity Beacon settings & persistence', () async {
    expect(StorageService.instance.isBleBeaconBroadcasting(), isTrue);
    await StorageService.instance.setBleBeaconBroadcasting(false);
    expect(StorageService.instance.isBleBeaconBroadcasting(), isFalse);

    expect(StorageService.instance.getBleBeaconVibe(), 'Looking for Coffee ☕');
    await StorageService.instance.saveBleBeaconVibe('Ready for Trivia 🧠');
    expect(StorageService.instance.getBleBeaconVibe(), 'Ready for Trivia 🧠');

    expect(StorageService.instance.getBleBeaconRangeMeters(), 50);
    await StorageService.instance.saveBleBeaconRangeMeters(30);
    expect(StorageService.instance.getBleBeaconRangeMeters(), 30);
  });

  test('Phase 15: Message Permissions (Matches Only vs Anyone) & Reviewer Account', () async {
    // 1. Message permissions default to true (Matches only)
    expect(StorageService.instance.isMatchesOnlyMessagesEnabled(), isTrue);

    // Maya is a seed conversation (mutual match)
    expect(RealtimeChatService.instance.canReceiveMessageFrom('Maya'), isTrue);
    // Non-match user is blocked when Matches Only is enabled
    expect(RealtimeChatService.instance.canReceiveMessageFrom('RandomExplorer99'), isFalse);

    // Switch to Anyone (Open DMs)
    await StorageService.instance.setMatchesOnlyMessagesEnabled(false);
    expect(StorageService.instance.isMatchesOnlyMessagesEnabled(), isFalse);
    expect(RealtimeChatService.instance.canReceiveMessageFrom('RandomExplorer99'), isTrue);

    // 2. Reviewer Account & Email Authentication
    final reviewerSession = await SupabaseService.instance.signInAsReviewer();
    expect(reviewerSession['user']['email'], 'reviewer@sparkquest.app');
    expect(StorageService.instance.getUserName(), 'Google Play Reviewer');

    final emailSession = await SupabaseService.instance.signInWithEmail('reviewer@sparkquest.app', 'SecretPass2026!');
    expect(emailSession, isNotNull);
    expect(emailSession?['user']['email'], 'reviewer@sparkquest.app');
  });
}
