import 'package:cloud_firestore/cloud_firestore.dart';

/// Mood entry model for tracking user's emotional state
class MoodEntry {
  final String id;
  final String userId;
  final String mood; // emoji representation
  final String label; // text label (Happy, Good, Okay, etc.)
  final EmotionType emotionType;
  final DateTime timestamp;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.label,
    required this.emotionType,
    required this.timestamp,
    this.notes,
    this.metadata,
  });

  /// Create MoodEntry from Firestore document
  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      mood: data['mood'] ?? '',
      label: data['label'] ?? '',
      emotionType: EmotionType.values.firstWhere(
        (e) => e.toString() == data['emotionType'],
        orElse: () => EmotionType.normal,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      metadata: data['metadata'],
    );
  }

  /// Convert MoodEntry to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mood': mood,
      'label': label,
      'emotionType': emotionType.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  MoodEntry copyWith({
    String? id,
    String? userId,
    String? mood,
    String? label,
    EmotionType? emotionType,
    DateTime? timestamp,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      label: label ?? this.label,
      emotionType: emotionType ?? this.emotionType,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, userId: $userId, mood: $mood, label: $label, emotionType: $emotionType, timestamp: $timestamp)';
  }
}

/// Emotion types for mood tracking
enum EmotionType {
  happy,
  normal,
  sad,
}

/// Extension for EmotionType to get display properties
extension EmotionTypeExtension on EmotionType {
  String get emoji {
    switch (this) {
      case EmotionType.happy:
        return '😊';
      case EmotionType.normal:
        return '😐';
      case EmotionType.sad:
        return '🙁';
    }
  }

  String get label {
    switch (this) {
      case EmotionType.happy:
        return 'Great';
      case EmotionType.normal:
        return 'Okay';
      case EmotionType.sad:
        return 'Sad';
    }
  }

  String get displayName {
    switch (this) {
      case EmotionType.happy:
        return 'Happy';
      case EmotionType.normal:
        return 'Normal';
      case EmotionType.sad:
        return 'Sad';
    }
  }
}

/// Mood statistics for analytics
class MoodStatistics {
  final int totalEntries;
  final Map<EmotionType, int> emotionCounts;
  final EmotionType? dominantMood;
  final double averageMoodScore;
  final List<MoodEntry> recentEntries;
  final DateTime? lastEntryDate;

  const MoodStatistics({
    required this.totalEntries,
    required this.emotionCounts,
    this.dominantMood,
    required this.averageMoodScore,
    required this.recentEntries,
    this.lastEntryDate,
  });

  /// Get mood trend message
  String get trendMessage {
    if (totalEntries < 3) {
      return "Keep tracking your mood to see trends!";
    }

    if (averageMoodScore >= 2.0) {
      return "Your mood has been mostly positive this week!";
    } else if (averageMoodScore >= 1.0) {
      return "Your mood has been balanced this week.";
    } else {
      return "Consider some self-care activities to boost your mood.";
    }
  }

  /// Get trend icon
  String get trendIcon {
    if (averageMoodScore >= 2.0) {
      return "📈"; // trending up
    } else if (averageMoodScore >= 1.0) {
      return "📊"; // balanced
    } else {
      return "📉"; // trending down
    }
  }
}