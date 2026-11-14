import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'push_notification_service.dart';
import 'supabase_service.dart';

enum WebRtcConnectionStage {
  idle,
  initializing,
  ringing,
  connecting,
  connected,
  fallbackPreview,
  ended,
}

/// Manages real-time P2P audio/video WebRTC calls (`flutter_webrtc`) backed by
/// Supabase `public.call_signals` SDP/ICE exchange over REST + Realtime.
class WebRtcCallService extends ChangeNotifier {
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Timer? _signalPollTimer;

  WebRtcConnectionStage _stage = WebRtcConnectionStage.idle;
  bool _renderersInitialized = false;
  bool _remoteVideoReady = false;
  bool _localVideoReady = false;
  bool _muted = false;
  bool _cameraOff = false;
  bool _frontCamera = true;
  bool _appliedRemoteSdp = false;
  final Set<String> _appliedIceKeys = {};
  String _roomId = '';
  bool _isCaller = true;
  bool _isVoiceOnly = false;
  String? _lastStatusNote;

  WebRtcConnectionStage get stage => _stage;
  bool get hasRemoteVideo => _remoteVideoReady && remoteRenderer.srcObject != null;
  bool get hasLocalVideo => _localVideoReady && localRenderer.srcObject != null;
  bool get isMuted => _muted;
  bool get isCameraOff => _cameraOff;
  String? get statusNote => _lastStatusNote;

  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Starts a local media session + peer connection and negotiates SDP via Supabase.
  /// Gracefully degrades to [WebRtcConnectionStage.fallbackPreview] if hardware
  /// camera/mic or native WebRTC bindings are unavailable (e.g., headless tests).
  Future<void> startCall({
    required String roomId,
    required bool isCaller,
    required bool isVoiceOnly,
    String matchName = 'Match',
  }) async {
    _roomId = roomId;
    _isCaller = isCaller;
    _isVoiceOnly = isVoiceOnly;
    _stage = WebRtcConnectionStage.initializing;
    _lastStatusNote = 'Initializing encrypted WebRTC session...';
    notifyListeners();

    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersInitialized = true;

      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': isVoiceOnly
            ? false
            : {
                'facingMode': 'user',
                'width': {'ideal': 720},
                'height': {'ideal': 1280},
                'frameRate': {'ideal': 30},
              },
      };

      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
      _localVideoReady = !isVoiceOnly &&
          (_localStream?.getVideoTracks().isNotEmpty ?? false);

      _peerConnection = await createPeerConnection(_rtcConfig);

      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          remoteRenderer.srcObject = _remoteStream;
          _remoteVideoReady = !isVoiceOnly &&
              (_remoteStream?.getVideoTracks().isNotEmpty ?? false);
          _stage = WebRtcConnectionStage.connected;
          _lastStatusNote = 'P2P Encrypted Stream Connected';
          notifyListeners();
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          _stage = WebRtcConnectionStage.connected;
          _lastStatusNote = 'P2P Connected';
          notifyListeners();
        }
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate == null || _roomId.isEmpty) return;
        unawaited(
          SupabaseService.instance.appendIceCandidate(
            roomId: _roomId,
            candidate: {
              'sender': _isCaller ? 'caller' : 'callee',
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          ),
        );
      };

      // Subscribe to live Realtime signal updates + light polling fallback
      PushNotificationService.instance.onCallSignalUpdate = _handleSignalRecord;
      _signalPollTimer?.cancel();
      _signalPollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_pollSignal()),
      );

      if (_isCaller) {
        _stage = WebRtcConnectionStage.ringing;
        _lastStatusNote = 'Ringing $matchName...';
        notifyListeners();

        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        if (offer.sdp != null) {
          await SupabaseService.instance.updateCallSignalOffer(
            roomId: _roomId,
            sdpOffer: jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
          );
        }
      } else {
        _stage = WebRtcConnectionStage.connecting;
        _lastStatusNote = 'Joining $matchName\'s Spark Call...';
        notifyListeners();
        await _pollSignal();
      }
    } catch (e) {
      // Safe fallback when camera/mic permission denied, hardware missing, or test harness
      _stage = WebRtcConnectionStage.fallbackPreview;
      _lastStatusNote = 'HD Preview Mode (${_isVoiceOnly ? 'Voice' : 'Video'})';
      debugPrint('WebRtcCallService fallback: $e');
      notifyListeners();
    }
  }

  Future<void> _pollSignal() async {
    if (_roomId.isEmpty || _peerConnection == null) return;
    final record = await SupabaseService.instance.fetchCallSignal(_roomId);
    if (record != null) {
      await _handleSignalRecord(record);
    }
  }

  Future<void> _handleSignalRecord(Map<String, dynamic> record) async {
    if (_peerConnection == null) return;
    if (record['room_id']?.toString() != _roomId) return;

    try {
      if (_isCaller && !_appliedRemoteSdp) {
        final rawAnswer = record['sdp_answer']?.toString();
        if (rawAnswer != null && rawAnswer.isNotEmpty) {
          final parsed = jsonDecode(rawAnswer) as Map<String, dynamic>;
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(
              parsed['sdp']?.toString(),
              parsed['type']?.toString() ?? 'answer',
            ),
          );
          _appliedRemoteSdp = true;
          _stage = WebRtcConnectionStage.connecting;
          _lastStatusNote = 'Negotiating P2P media...';
          notifyListeners();
        }
      } else if (!_isCaller && !_appliedRemoteSdp) {
        final rawOffer = record['sdp_offer']?.toString();
        if (rawOffer != null && rawOffer.isNotEmpty) {
          final parsed = jsonDecode(rawOffer) as Map<String, dynamic>;
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(
              parsed['sdp']?.toString(),
              parsed['type']?.toString() ?? 'offer',
            ),
          );
          _appliedRemoteSdp = true;

          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          if (answer.sdp != null) {
            await SupabaseService.instance.updateCallSignalAnswer(
              roomId: _roomId,
              sdpAnswer: jsonEncode({'sdp': answer.sdp, 'type': answer.type}),
            );
          }
          notifyListeners();
        }
      }

      // Apply ICE candidates sent by the remote peer
      final candidates = record['ice_candidates'] as List<dynamic>? ?? const [];
      final remoteSender = _isCaller ? 'callee' : 'caller';
      for (final item in candidates) {
        if (item is! Map<String, dynamic>) continue;
        if (item['sender'] != remoteSender) continue;
        final candStr = item['candidate']?.toString() ?? '';
        if (candStr.isEmpty || _appliedIceKeys.contains(candStr)) continue;
        _appliedIceKeys.add(candStr);

        await _peerConnection!.addCandidate(
          RTCIceCandidate(
            candStr,
            item['sdpMid']?.toString(),
            item['sdpMLineIndex'] as int?,
          ),
        );
      }
    } catch (_) {}
  }

  void toggleMute() {
    _muted = !_muted;
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = !_muted;
    }
    notifyListeners();
  }

  void toggleCamera() {
    if (_isVoiceOnly) return;
    _cameraOff = !_cameraOff;
    for (final track in _localStream?.getVideoTracks() ?? const []) {
      track.enabled = !_cameraOff;
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? const [];
    if (videoTracks.isEmpty) return;
    try {
      await Helper.switchCamera(videoTracks.first);
      _frontCamera = !_frontCamera;
      notifyListeners();
    } catch (_) {}
  }

  bool get isFrontCamera => _frontCamera;

  Future<void> endCall() async {
    _stage = WebRtcConnectionStage.ended;
    _signalPollTimer?.cancel();
    PushNotificationService.instance.onCallSignalUpdate = null;

    if (_roomId.isNotEmpty) {
      unawaited(
        SupabaseService.instance.updateCallSignalStatus(
          roomId: _roomId,
          status: 'ended',
        ),
      );
    }

    try {
      for (final track in _localStream?.getTracks() ?? const []) {
        await track.stop();
      }
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _peerConnection?.close();
    } catch (_) {}

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _remoteVideoReady = false;
    _localVideoReady = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _signalPollTimer?.cancel();
    if (_renderersInitialized) {
      unawaited(localRenderer.dispose());
      unawaited(remoteRenderer.dispose());
    }
    unawaited(_peerConnection?.close());
    super.dispose();
  }
}
