import '../models/mood_model.dart';

/// Utility functions for mood tracking
class MoodUtils {
  /// Get mood score for analytics (0-2 scale)
  static double getMoodScore(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return 2.0;
      case EmotionType.normal:
        return 1.0;
      case EmotionType.sad:
        return 0.0;
    }
  }

  /// Get mood color for UI
  static String getMoodColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return '#4CAF50'; // Green
      case EmotionType.normal:
        return '#2196F3'; // Blue
      case EmotionType.sad:
        return '#9C27B0'; // Purple
    }
  }

  /// Get mood description
  static String getMoodDescription(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return 'Feeling great and positive';
      case EmotionType.normal:
        return 'Feeling balanced and okay';
      case EmotionType.sad:
        return 'Feeling down or sad';
    }
  }

  /// Get supportive message based on mood
  static String getSupportiveMessage(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return "Wonderful! Keep up the positive energy! 🌟";
      case EmotionType.normal:
        return "That's perfectly okay. Every day is different. 💙";
      case EmotionType.sad:
        return "It's okay to feel this way. Take care of yourself. 💜";
    }
  }

  /// Get recommended activities based on mood
  static List<String> getRecommendedActivities(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return [
          'Share your joy with friends',
          'Try a new hobby',
          'Go for a walk in nature',
          'Practice gratitude meditation',
        ];
      case EmotionType.normal:
        return [
          'Take some deep breaths',
          'Listen to calming music',
          'Read a good book',
          'Do some light exercise',
        ];
      case EmotionType.sad:
        return [
          'Talk to someone you trust',
          'Practice self-compassion',
          'Try gentle breathing exercises',
          'Consider professional support if needed',
        ];
    }
  }

  /// Check if mood entry is recent (within last 4 hours)
  static bool isMoodEntryRecent(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours < 4;
  }

  /// Get mood trend from list of entries
  static String getMoodTrend(List<MoodEntry> entries) {
    if (entries.length < 2) {
      return 'Not enough data';
    }

    final recent = entries.take(3).toList();
    final older = entries.skip(3).take(3).toList();

    if (older.isEmpty) {
      return 'Keep tracking to see trends';
    }

    final recentAvg = recent.map((e) => getMoodScore(e.emotionType)).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((e) => getMoodScore(e.emotionType)).reduce((a, b) => a + b) / older.length;

    if (recentAvg > olderAvg + 0.3) {
      return 'Improving 📈';
    } else if (recentAvg < olderAvg - 0.3) {
      return 'Declining 📉';
    } else {
      return 'Stable 📊';
    }
  }

  /// Format mood entry for display
  static String formatMoodEntry(MoodEntry entry) {
    final timeAgo = _getTimeAgo(entry.timestamp);
    return '${entry.mood} ${entry.label} - $timeAgo';
  }

  /// Get time ago string
  static String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Validate mood entry data
  static bool isValidMoodEntry({
    required String userId,
    required EmotionType emotionType,
    String? notes,
  }) {
    if (userId.isEmpty) return false;
    if (notes != null && notes.length > 500) return false; // Limit notes length
    return true;
  }

  /// Get mood statistics summary
  static String getMoodStatisticsSummary(MoodStatistics stats) {
    if (stats.totalEntries == 0) {
      return 'No mood entries yet. Start tracking to see insights!';
    }

    final dominantMood = stats.dominantMood?.displayName ?? 'Mixed';
    final avgScore = stats.averageMoodScore.toStringAsFixed(1);
    
    return 'You\'ve logged ${stats.totalEntries} moods. '
           'Most common: $dominantMood. '
           'Average score: $avgScore/2.0';
  }
}