import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// Audio service for meditation timer completion sounds and background audio management
class MeditationAudioService {
  static final MeditationAudioService _instance = MeditationAudioService._internal();
  factory MeditationAudioService() => _instance;
  MeditationAudioService._internal();

  late AudioPlayer _completionPlayer;
  bool _isInitialized = false;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _completionPlayer = AudioPlayer();
      await _completionPlayer.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize meditation audio service: $e');
    }
  }

  /// Play calming timer completion sound
  Future<void> playTimerCompletionSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Play gentle completion chime
      await _completionPlayer.play(AssetSource('sounds/notifier.mp3'));
      
      // Add haptic feedback for better user experience
      await HapticFeedback.lightImpact();
      
      // Optional: Add a second gentle chime after 1 second
      Timer(const Duration(milliseconds: 1000), () async {
        try {
          await _completionPlayer.play(AssetSource('sounds/notifier.mp3'));
          await HapticFeedback.lightImpact();
        } catch (e) {
          print('Failed to play second completion chime: $e');
        }
      });
      
    } catch (e) {
      print('Failed to play timer completion sound: $e');
      // Fallback to haptic feedback only
      await HapticFeedback.mediumImpact();
      Timer(const Duration(milliseconds: 500), () async {
        await HapticFeedback.lightImpact();
      });
    }
  }

  /// Set volume for completion sound
  Future<void> setCompletionVolume(double volume) async {
    if (!_isInitialized) return;
    
    try {
      await _completionPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Failed to set completion volume: $e');
    }
  }

  /// Configure audio session for background playback
  Future<void> configureBackgroundAudio() async {
    try {
      // Configure audio session for background playbook
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
              AVAudioSessionOptions.allowAirPlay,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (e) {
      print('Failed to configure background audio: $e');
    }
  }

  /// Dispose of audio resources
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await _completionPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      print('Failed to dispose meditation audio service: $e');
    }
  }

  /// Check if audio service is ready
  bool get isReady => _isInitialized;
}

/// Emotion-based recommendation engine
class EmotionRecommendationEngine {
  /// Get meditation recommendations based on emotion
  static List<String> getMeditationRecommendations(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return [
          'Gratitude Meditation',
          'Loving Kindness',
          'Mindful Breathing',
        ];
      case EmotionType.normal:
        return [
          'Mindful Breathing',
          'Body Scan',
          'Focus Meditation',
        ];
      case EmotionType.sad:
        return [
          'Self-Compassion',
          'Loving Kindness',
          'Gentle Breathing',
        ];
    }
  }

  /// Get sound recommendations based on emotion
  static List<String> getSoundRecommendations(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return [
          'Birds',
          'Ocean Waves',
          'Wind Chimes',
        ];
      case EmotionType.normal:
        return [
          'Rain',
          'Forest',
          'White Noise',
        ];
      case EmotionType.sad:
        return [
          'Om',
          'Singing Bowls',
          'Piano Meditation',
        ];
    }
  }

  /// Get supportive message based on emotion
  static String getSupportiveMessage(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return "Wonderful! Let's maintain this positive energy with some uplifting meditation.";
      case EmotionType.normal:
        return "Perfect time for mindfulness. Let's find your center with gentle meditation.";
      case EmotionType.sad:
        return "It's okay to feel this way. Let's nurture yourself with some compassionate meditation.";
    }
  }

  /// Get UI mood colors based on emotion
  static EmotionMoodColors getMoodColors(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return EmotionMoodColors(
          primary: const Color(0xFF4CAF50), // Green
          background: const Color(0xFFF1F8E9), // Light green
          accent: const Color(0xFF8BC34A),
        );
      case EmotionType.normal:
        return EmotionMoodColors(
          primary: const Color(0xFF2196F3), // Blue
          background: const Color(0xFFE3F2FD), // Light blue
          accent: const Color(0xFF64B5F6),
        );
      case EmotionType.sad:
        return EmotionMoodColors(
          primary: const Color(0xFF9C27B0), // Purple
          background: const Color(0xFFF3E5F5), // Light purple
          accent: const Color(0xFFBA68C8),
        );
    }
  }
}

/// Emotion types for simplified system
enum EmotionType {
  happy,
  normal,
  sad,
}

/// Emotion option data class
class EmotionOption {
  final EmotionType type;
  final String emoji;
  final String label;
  final Color color;

  const EmotionOption({
    required this.type,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

/// Emotion mood colors for UI adaptation
class EmotionMoodColors {
  final Color primary;
  final Color background;
  final Color accent;

  const EmotionMoodColors({
    required this.primary,
    required this.background,
    required this.accent,
  });
}