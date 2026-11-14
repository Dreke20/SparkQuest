import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'storage_service.dart';
import 'supabase_service.dart';

/// Bridges native Android local notifications (`MethodChannel`) with a live
/// Supabase Realtime Phoenix WebSocket (`public.messages`, `public.matches`,
/// `public.call_signals`) for sparks, chats, incoming calls, and WebRTC signaling.
class PushNotificationService extends ChangeNotifier {
  static final PushNotificationService instance =
      PushNotificationService._internal();
  PushNotificationService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.sparkquest.sparkquest/notifications');

  static const String channelSparks = 'sparkquest_sparks';
  static const String channelMessages = 'sparkquest_messages';
  static const String channelCalls = 'sparkquest_calls';

  WebSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _initialized = false;
  bool _realtimeConnected = false;
  bool _disposed = false;
  int _refCounter = 1;
  int _reconnectAttempts = 0;

  void Function(String title, String body)? onInAppBanner;
  void Function(Map<String, dynamic> callSignal)? onIncomingCall;
  void Function(Map<String, dynamic> callSignal)? onCallSignalUpdate;

  bool get isRealtimeConnected => _realtimeConnected;
  bool get isInitialized => _initialized;

  Future<void> initialize({bool requestAndroidPermission = false}) async {
    if (_initialized) return;
    _initialized = true;
    await StorageService.instance.init();

    final isTestBinding =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTestBinding) return;

    if (requestAndroidPermission) {
      await requestPermission();
    }
    unawaited(connectRealtime());
  }

  /// Requests Android 13+ POST_NOTIFICATIONS runtime permission via MainActivity.
  Future<bool> requestPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      return granted ?? true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('hasPermission');
      return granted ?? true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Displays a native Android notification tray alert.
  Future<bool> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String channelId = channelMessages,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('showNotification', {
        'id': id,
        'title': title,
        'body': body,
        'channelId': channelId,
      });
      return result ?? true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendTestNotification() async {
    await requestPermission();
    final ok = await showLocalNotification(
      id: 9101,
      title: 'SparkQuest Alerts Active',
      body: 'Live notifications for Sparks, Guild Chats, and Video Calls are ready.',
      channelId: channelSparks,
    );
    onInAppBanner?.call(
      'SparkQuest',
      'Notification test triggered (${ok ? 'tray alert sent' : 'in-app preview'})',
    );
    return ok;
  }

  /// Connects to Supabase Realtime WebSocket (`vsn=1.0.0`) and subscribes to
  /// `messages`, `matches`, and `call_signals`.
  Future<void> connectRealtime() async {
    if (_disposed || _realtimeConnected) return;

    final wsUrl =
        'wss://${SupabaseService.projectRef}.supabase.co/realtime/v1/websocket'
        '?apikey=${SupabaseService.anonKey}&vsn=1.0.0';

    try {
      _socket = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 10));
      _realtimeConnected = true;
      _reconnectAttempts = 0;
      notifyListeners();

      _socket!.listen(
        _handleSocketFrame,
        onDone: _handleSocketClosed,
        onError: (_) => _handleSocketClosed(),
        cancelOnError: true,
      );

      _joinPostgresTopic('realtime:public:messages', 'messages');
      _joinPostgresTopic('realtime:public:matches', 'matches');
      _joinPostgresTopic('realtime:public:call_signals', 'call_signals');

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendFrame({
          'topic': 'phoenix',
          'event': 'heartbeat',
          'payload': <String, dynamic>{},
          'ref': 'hb_${_refCounter++}',
        });
      });
    } catch (_) {
      _handleSocketClosed();
    }
  }

  void _joinPostgresTopic(String topic, String table) {
    _sendFrame({
      'topic': topic,
      'event': 'phx_join',
      'payload': {
        'config': {
          'broadcast': {'self': false},
          'presence': {'key': ''},
          'postgres_changes': [
            {
              'event': '*',
              'schema': 'public',
              'table': table,
            }
          ],
        },
        'access_token':
            SupabaseService.instance.accessToken ?? SupabaseService.anonKey,
      },
      'ref': 'join_${_refCounter++}',
    });
  }

  void _sendFrame(Map<String, dynamic> frame) {
    try {
      _socket?.add(jsonEncode(frame));
    } catch (_) {}
  }

  void _handleSocketClosed() {
    _heartbeatTimer?.cancel();
    _socket = null;
    if (_realtimeConnected) {
      _realtimeConnected = false;
      notifyListeners();
    }
    if (_disposed) return;

    final isTestBinding =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTestBinding) return;

    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 3).clamp(3, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      unawaited(connectRealtime());
    });
  }

  void _handleSocketFrame(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final event = decoded['event']?.toString();
      if (event != 'postgres_changes') return;

      final payload = decoded['payload'];
      if (payload is! Map<String, dynamic>) return;
      final data = payload['data'];
      if (data is! Map<String, dynamic>) return;

      processRealtimeChange(data);
    } catch (_) {}
  }

  /// Processes a decoded Supabase `postgres_changes` `data` block.
  /// Exposed cleanly for unit testing notification filtering and dispatch.
  @visibleForTesting
  Future<void> processRealtimeChange(Map<String, dynamic> data) async {
    final table = data['table']?.toString() ?? '';
    final type = data['type']?.toString().toUpperCase() ?? '';
    final record = data['record'];
    if (record is! Map<String, dynamic>) return;

    final myId = SupabaseService.instance.currentUserId ?? 'user_me';

    if (table == 'messages' && type == 'INSERT') {
      final senderId = record['sender_id']?.toString() ?? '';
      if (senderId.isEmpty || senderId == myId) return;
      if (!StorageService.instance.isNotifyMessagesEnabled()) return;

      final senderName =
          record['sender_name']?.toString() ?? 'SparkQuest Match';
      final body = record['content']?.toString() ?? 'Sent you a message';
      onInAppBanner?.call(senderName, body);
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: senderName,
        body: body,
        channelId: channelMessages,
      );
    } else if (table == 'matches' && type == 'INSERT') {
      final userA = record['user_a']?.toString() ?? '';
      final userB = record['user_b']?.toString() ?? '';
      if (userA != myId && userB != myId && myId != 'user_me') return;
      if (!StorageService.instance.isNotifySparksEnabled()) return;

      final partnerName =
          record['partner_name']?.toString() ?? 'A nearby Adventurer';
      final synergy = record['synergy_score']?.toString() ?? '90';
      const title = 'New Mutual Spark!';
      final body = '$partnerName ($synergy% Synergy) sparked with you.';
      onInAppBanner?.call(title, body);
      await showLocalNotification(
        id: (DateTime.now().millisecondsSinceEpoch + 17) % 100000,
        title: title,
        body: body,
        channelId: channelSparks,
      );
    } else if (table == 'call_signals') {
      onCallSignalUpdate?.call(record);

      final status = record['status']?.toString() ?? '';
      final callerId = record['caller_id']?.toString() ?? '';
      final calleeId = record['callee_id']?.toString() ?? '';
      final forMe = calleeId == myId || calleeId == 'all';
      if (status == 'ringing' && callerId != myId && forMe) {
        if (!StorageService.instance.isNotifyCallsEnabled()) return;
        final callerName = record['caller_name']?.toString() ?? 'Spark Match';
        final callType = record['call_type']?.toString() ?? 'video';
        final title = 'Incoming ${callType == 'voice' ? 'Voice' : 'Video'} Date Call';
        final body = '$callerName is calling on SparkQuest';
        onIncomingCall?.call(record);
        await showLocalNotification(
          id: (DateTime.now().millisecondsSinceEpoch + 31) % 100000,
          title: title,
          body: body,
          channelId: channelCalls,
        );
      }
    }
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _socket?.close();
    _socket = null;
    _realtimeConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}
