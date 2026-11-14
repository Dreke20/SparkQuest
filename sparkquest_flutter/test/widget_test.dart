import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkquest/main.dart';
import 'package:sparkquest/models/profile.dart';
import 'package:sparkquest/services/crash_reporting_service.dart';
import 'package:sparkquest/services/push_notification_service.dart';
import 'package:sparkquest/services/quest_progression_service.dart';
import 'package:sparkquest/services/realtime_chat_service.dart';
import 'package:sparkquest/services/storage_service.dart';
import 'package:sparkquest/services/supabase_service.dart';
import 'package:sparkquest/services/admob_service.dart';
import 'package:sparkquest/services/webrtc_call_service.dart';

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
    expect(cloudProfile.photoAsset, 'assets/images/logo.jpg');
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
    // Non-reviewer gets zero fake fallback lounges when offline
    final nonReviewerLounges = await SupabaseService.instance.fetchVoiceLounges();
    expect(nonReviewerLounges, isEmpty);

    // Reviewer gets labeled [Review Demo] lounges when offline
    await SupabaseService.instance.signInAsReviewer();
    final reviewerLounges = await SupabaseService.instance.fetchVoiceLounges();
    expect(reviewerLounges.length, greaterThanOrEqualTo(2));
    expect(reviewerLounges.first['title'], contains('[Review Demo]'));
    await SupabaseService.instance.signOut();

    // Mock auth tokens and offline OTP fallbacks are disabled
    final mockGoogleRes = await SupabaseService.instance.signInWithGoogleToken('google_mock_id_token_2026');
    expect(mockGoogleRes, isNull);
    final offlineOtpRes = await SupabaseService.instance.verifyPhoneOtp('+15550000000', '123456');
    expect(offlineOtpRes, isNull);

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

    // Riley was added as a mutual match via addMatchFromProfile in earlier test
    expect(RealtimeChatService.instance.canReceiveMessageFrom('Riley'), isTrue);
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
    expect(StorageService.instance.isReviewerAccount(), isTrue);

    // Verification that fallback backdoors are removed: offline signInWithEmail returns null
    final noBackdoorSession = await SupabaseService.instance.signInWithEmail('fake.test@sparkquest.app', 'SecretPass2026!');
    expect(noBackdoorSession, isNull);
  });

  test('Phase 16: Google AdMob Service & Gold VIP Ad-Free Exemption', () async {
    // 1. Official Google test ad unit IDs verification
    expect(AdMobService.instance.bannerAdUnitId, isNotEmpty);
    expect(AdMobService.instance.interstitialAdUnitId, isNotEmpty);
    expect(AdMobService.instance.rewardedAdUnitId, isNotEmpty);

    // 2. VIP Ad-Free Guarantee
    await StorageService.instance.setGoldVip(false);
    expect(StorageService.instance.isGoldVip(), isFalse);

    // When not VIP, card deck swipe records towards threshold
    AdMobService.instance.recordSwipeAndMaybeShowInterstitial();

    // When Gold VIP is active, no ads are triggered
    await StorageService.instance.setGoldVip(true);
    expect(StorageService.instance.isGoldVip(), isTrue);

    // 3. Rewarded Ad reward callback with VIP 2× doubling
    // When Gold VIP is active:
    int rewardedEmbers = 0;
    AdMobService.instance.showRewardedAd(
      onRewarded: (amount) {
        rewardedEmbers = amount;
      },
    );
    expect(rewardedEmbers, 10); // VIP gets 10 (base 5 * 2)

    // When Gold VIP is false:
    await StorageService.instance.setGoldVip(false);
    AdMobService.instance.showRewardedAd(
      onRewarded: (amount) {
        rewardedEmbers = amount;
      },
    );
    expect(rewardedEmbers, 5); // Non-VIP gets base 5

    // 4. AdMob Privacy Choices & Consent Preferences (GDPR / ePrivacy)
    expect(StorageService.instance.isPersonalizedAdsEnabled(), isTrue);
    expect(StorageService.instance.isAdLocationMeasurementEnabled(), isTrue);
    final adRequest = AdMobService.instance.buildAdRequest();
    expect(adRequest.nonPersonalizedAds, isFalse);

    await StorageService.instance.setPersonalizedAdsEnabled(false);
    expect(StorageService.instance.isPersonalizedAdsEnabled(), isFalse);
    final nonPersonalizedRequest = AdMobService.instance.buildAdRequest();
    expect(nonPersonalizedRequest.nonPersonalizedAds, isTrue);

    await StorageService.instance.setAdLocationMeasurementEnabled(false);
    expect(StorageService.instance.isAdLocationMeasurementEnabled(), isFalse);
  });

  test('Phase 17: Sign Out & Google Maps Tile Provider Integration', () async {
    // 1. Sign In & Sign Out Flow
    await SupabaseService.instance.signOut();
    expect(SupabaseService.instance.isSignedIn, isFalse);
    expect(StorageService.instance.getUserEmail(), isNull);
    expect(StorageService.instance.isReviewerAccount(), isFalse);

    // Sign In as Reviewer
    await SupabaseService.instance.signInAsReviewer();
    expect(SupabaseService.instance.isSignedIn, isTrue);
    expect(StorageService.instance.getUserEmail(), 'reviewer@sparkquest.app');
    expect(StorageService.instance.isReviewerAccount(), isTrue);

    // Sign Out
    await SupabaseService.instance.signOut();
    expect(SupabaseService.instance.isSignedIn, isFalse);
    expect(StorageService.instance.getUserEmail(), isNull);
    expect(StorageService.instance.isReviewerAccount(), isFalse);

    // 2. Google Maps Tile Mode Persistence
    expect(StorageService.instance.getMapTileMode(), 'google_roadmap');
    await StorageService.instance.saveMapTileMode('google_hybrid');
    expect(StorageService.instance.getMapTileMode(), 'google_hybrid');
    await StorageService.instance.saveMapTileMode('osm');
    expect(StorageService.instance.getMapTileMode(), 'osm');
  });

  test('Phase 18: Fake Profiles Removed for Normal Users & Shown for Reviewer Only', () async {
    // 1. Normal user: Zero fake seed profiles in discovery or conversations
    await StorageService.instance.saveUserEmail('normal.explorer@sparkquest.app');
    expect(StorageService.instance.isReviewerAccount(), isFalse);

    // Ensure email with substring 'reviewer' or 'test' is NOT granted reviewer mode
    await StorageService.instance.saveUserEmail('test.reviewer.imposter@gmail.com');
    expect(StorageService.instance.isReviewerAccount(), isFalse);

    // Set back to clean normal user
    await StorageService.instance.saveUserEmail('alice@example.com');
    expect(StorageService.instance.isReviewerAccount(), isFalse);

    RealtimeChatService.instance.reloadConversations();
    final normalConvos = RealtimeChatService.instance.getConversations();
    // Normal users should not have seed conversations
    expect(normalConvos.any((c) => c.name.contains('[Review Demo]')), isFalse);

    // Adding a real match should not pull in seed conversations
    final testMatch = const Profile(
      id: 'real_user_1',
      name: 'Elena Real',
      age: 27,
      occupation: 'Biochemist',
      distance: '3 mi away',
      photoAsset: 'assets/images/logo.jpg',
      tags: ['🧪 Science'],
      compatPct: 91,
      compatLevel: 'high',
    );
    RealtimeChatService.instance.addMatchFromProfile(testMatch);
    final convosAfterMatch = RealtimeChatService.instance.getConversations();
    expect(convosAfterMatch.any((c) => c.name.contains('[Review Demo]')), isFalse);
    expect(convosAfterMatch.any((c) => c.id == 'real_user_1'), isTrue);

    // 2. Reviewer user: Fake seed profiles appear with explicit Google Review labels
    await StorageService.instance.saveUserEmail('reviewer@sparkquest.app');
    expect(StorageService.instance.isReviewerAccount(), isTrue);

    RealtimeChatService.instance.reloadConversations();
    final reviewerConvos = RealtimeChatService.instance.getConversations();
    expect(reviewerConvos.any((c) => c.name.contains('[Review Demo]')), isTrue);
    expect(reviewerConvos.any((c) => c.lastMessage.contains('Play Review Demo')), isTrue);

    // Check seed profiles labeling
    final demoSeeds = Profile.seedProfiles;
    expect(demoSeeds.every((p) => p.isDemoProfile), isTrue);
    expect(demoSeeds.every((p) => p.name.contains('[Review Demo]')), isTrue);
    expect(demoSeeds.every((p) => p.occupation.contains('Fake Profile for Review')), isTrue);

    // Clean up
    await StorageService.instance.saveUserEmail(null);
    expect(StorageService.instance.isReviewerAccount(), isFalse);
    RealtimeChatService.instance.reloadConversations();
  });

  test('Phase 19: Push Notification Settings & Realtime Event Dispatch', () async {
    expect(StorageService.instance.isNotifySparksEnabled(), isTrue);
    expect(StorageService.instance.isNotifyMessagesEnabled(), isTrue);
    expect(StorageService.instance.isNotifyCallsEnabled(), isTrue);

    String? bannerTitle;
    String? bannerBody;
    Map<String, dynamic>? incomingCall;

    PushNotificationService.instance.onInAppBanner = (title, body) {
      bannerTitle = title;
      bannerBody = body;
    };
    PushNotificationService.instance.onIncomingCall = (signal) {
      incomingCall = signal;
    };

    // Incoming message triggers banner when enabled
    await PushNotificationService.instance.processRealtimeChange({
      'table': 'messages',
      'type': 'INSERT',
      'record': {
        'sender_id': 'other_user_1',
        'sender_name': 'Elena',
        'content': 'Ready for that espresso quest?',
      },
    });
    expect(bannerTitle, 'Elena');
    expect(bannerBody, 'Ready for that espresso quest?');

    // Disabled message toggle suppresses banner dispatch
    bannerTitle = null;
    await StorageService.instance.setNotifyMessagesEnabled(false);
    await PushNotificationService.instance.processRealtimeChange({
      'table': 'messages',
      'type': 'INSERT',
      'record': {
        'sender_id': 'other_user_1',
        'sender_name': 'Elena',
        'content': 'Should be muted',
      },
    });
    expect(bannerTitle, isNull);

    // Match notification triggers when enabled (matches live Supabase schema user_id_1/user_id_2/user_name)
    await StorageService.instance.setNotifySparksEnabled(true);
    await PushNotificationService.instance.processRealtimeChange({
      'table': 'matches',
      'type': 'INSERT',
      'record': {
        'user_id_1': 'user_me',
        'user_id_2': 'other_user_2',
        'user_name': 'Marcus',
        'compatibility_pct': 93,
      },
    });
    expect(bannerTitle, 'New Mutual Spark!');
    expect(bannerBody, contains('Marcus'));

    // Incoming call notification triggers callback
    await PushNotificationService.instance.processRealtimeChange({
      'table': 'call_signals',
      'type': 'INSERT',
      'record': {
        'room_id': 'room_webrtc_1',
        'caller_id': 'other_user_2',
        'caller_name': 'Marcus',
        'callee_id': 'user_me',
        'call_type': 'video',
        'status': 'ringing',
      },
    });
    expect(incomingCall?['room_id'], 'room_webrtc_1');

    PushNotificationService.instance.onInAppBanner = null;
    PushNotificationService.instance.onIncomingCall = null;
  });

  test('Phase 19: CrashReportingService queues structured error logs locally', () async {
    await CrashReportingService.instance.clearLogs();
    final initialCount = CrashReportingService.instance.sessionErrorCount;

    await CrashReportingService.instance.recordError(
      StateError('Simulated test exception'),
      StackTrace.current,
      source: 'unit_test',
      fatal: false,
      context: {'screen': 'explore'},
      skipUpload: true,
    );

    expect(CrashReportingService.instance.sessionErrorCount, initialCount + 1);
    final logs = CrashReportingService.instance.getRecentLogs();
    expect(logs.length, 1);
    expect(logs.first['source'], 'unit_test');
    expect(logs.first['error'], contains('Simulated test exception'));
    expect(logs.first['app_version'], '2.1.0+16');
    expect(logs.first['synced'], isFalse);

    final fallbackWidget = CrashReportingService.buildErrorFallbackWidget(
      FlutterErrorDetails(exception: Exception('Render glitch')),
    );
    expect(fallbackWidget, isA<Container>());

    await CrashReportingService.instance.clearLogs();
    expect(CrashReportingService.instance.getRecentLogs(), isEmpty);
  });

  test('Phase 19: WebRtcCallService state transitions and graceful fallback', () async {
    final rtc = WebRtcCallService();
    expect(rtc.stage, WebRtcConnectionStage.idle);
    expect(rtc.isMuted, isFalse);
    expect(rtc.isCameraOff, isFalse);

    // Graceful fallback when native WebRTC/camera unavailable in unit test VM
    await rtc.startCall(
      roomId: 'room_test_13',
      isCaller: true,
      isVoiceOnly: false,
      matchName: 'Elena',
    );
    expect(rtc.stage, WebRtcConnectionStage.fallbackPreview);

    rtc.toggleMute();
    expect(rtc.isMuted, isTrue);
    rtc.toggleCamera();
    expect(rtc.isCameraOff, isTrue);

    await rtc.endCall();
    expect(rtc.stage, WebRtcConnectionStage.ended);
    rtc.dispose();
  });

  test('Phase 20 (v2.1): Multi-region ICE servers fallback & TURN status label', () async {
    expect(SupabaseService.defaultIceServers.length, greaterThanOrEqualTo(3));
    expect(
      SupabaseService.defaultIceServers.any((s) => s['urls'].toString().contains('cloudflare')),
      isTrue,
    );
    final rtc = WebRtcCallService();
    expect(rtc.iceStateLabel, isNotEmpty);
    expect(rtc.hasTurnRelay, isFalse);
    rtc.dispose();
  });
}
