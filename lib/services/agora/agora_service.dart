import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../utils/env_config.dart';

/// Service for managing Agora RTC Engine
class AgoraService {
  static RtcEngine? _engine;
  static bool _isInitialized = false;

  /// Initialize Agora Engine
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request permissions
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (permissions[Permission.camera] != PermissionStatus.granted ||
          permissions[Permission.microphone] != PermissionStatus.granted) {
        debugPrint('Camera or microphone permission denied');
        return false;
      }

      // Create engine
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(RtcEngineContext(
        appId: EnvConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Enable video
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.startPreview();

      _isInitialized = true;
      debugPrint('Agora engine initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      return false;
    }
  }

  /// Join a channel
  static Future<bool> joinChannel({
    required String token,
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized) {
      debugPrint('Agora not initialized');
      return false;
    }

    try {
      await _engine?.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
      
      debugPrint('Joined channel: $channelName');
      return true;
    } catch (e) {
      debugPrint('Error joining channel: $e');
      return false;
    }
  }

  /// Leave the current channel
  static Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
      debugPrint('Left channel');
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  /// Toggle microphone mute
  static Future<void> toggleMute(bool mute) async {
    try {
      await _engine?.muteLocalAudioStream(mute);
      debugPrint('Microphone ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  /// Toggle video
  static Future<void> toggleVideo(bool disable) async {
    try {
      await _engine?.muteLocalVideoStream(disable);
      debugPrint('Video ${disable ? 'disabled' : 'enabled'}');
    } catch (e) {
      debugPrint('Error toggling video: $e');
    }
  }

  /// Switch camera (front/back)
  static Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
      debugPrint('Camera switched');
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  /// Enable/disable speaker
  static Future<void> setSpeakerphone(bool enabled) async {
    try {
      await _engine?.setEnableSpeakerphone(enabled);
      debugPrint('Speakerphone ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }
  }

  /// Get the engine instance
  static RtcEngine? get engine => _engine;

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose the engine
  static Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _isInitialized = false;
      _engine = null;
      debugPrint('Agora engine disposed');
    } catch (e) {
      debugPrint('Error disposing Agora: $e');
    }
  }
}
