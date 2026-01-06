import 'package:flutter_test/flutter_test.dart';
import 'package:curevia/models/mood_model.dart';
import 'package:curevia/utils/mood_utils.dart';

void main() {
  group('Mood Tracking Tests', () {
    test('EmotionType enum should have correct values', () {
      expect(EmotionType.values.length, 3);
      expect(EmotionType.values, contains(EmotionType.happy));
      expect(EmotionType.values, contains(EmotionType.normal));
      expect(EmotionType.values, contains(EmotionType.sad));
    });

    test('EmotionType extension should return correct emojis', () {
      expect(EmotionType.happy.emoji, '😊');
      expect(EmotionType.normal.emoji, '😐');
      expect(EmotionType.sad.emoji, '🙁');
    });

    test('EmotionType extension should return correct labels', () {
      expect(EmotionType.happy.label, 'Great');
      expect(EmotionType.normal.label, 'Okay');
      expect(EmotionType.sad.label, 'Sad');
    });

    test('EmotionType extension should return correct display names', () {
      expect(EmotionType.happy.displayName, 'Happy');
      expect(EmotionType.normal.displayName, 'Normal');
      expect(EmotionType.sad.displayName, 'Sad');
    });

    test('MoodEntry should be created correctly', () {
      final now = DateTime.now();
      final entry = MoodEntry(
        id: 'test_id',
        userId: 'user_123',
        mood: '😊',
        label: 'Great',
        emotionType: EmotionType.happy,
        timestamp: now,
        notes: 'Feeling great today!',
      );

      expect(entry.id, 'test_id');
      expect(entry.userId, 'user_123');
      expect(entry.mood, '😊');
      expect(entry.label, 'Great');
      expect(entry.emotionType, EmotionType.happy);
      expect(entry.timestamp, now);
      expect(entry.notes, 'Feeling great today!');
    });

    test('MoodEntry should convert to Firestore correctly', () {
      final now = DateTime.now();
      final entry = MoodEntry(
        id: 'test_id',
        userId: 'user_123',
        mood: '😊',
        label: 'Great',
        emotionType: EmotionType.happy,
        timestamp: now,
        notes: 'Feeling great today!',
      );

      final firestoreData = entry.toFirestore();

      expect(firestoreData['userId'], 'user_123');
      expect(firestoreData['mood'], '😊');
      expect(firestoreData['label'], 'Great');
      expect(firestoreData['emotionType'], 'EmotionType.happy');
      expect(firestoreData['notes'], 'Feeling great today!');
    });

    test('MoodUtils should return correct mood scores', () {
      expect(MoodUtils.getMoodScore(EmotionType.happy), 2.0);
      expect(MoodUtils.getMoodScore(EmotionType.normal), 1.0);
      expect(MoodUtils.getMoodScore(EmotionType.sad), 0.0);
    });

    test('MoodUtils should return correct supportive messages', () {
      expect(MoodUtils.getSupportiveMessage(EmotionType.happy), 
             "Wonderful! Keep up the positive energy! 🌟");
      expect(MoodUtils.getSupportiveMessage(EmotionType.normal), 
             "That's perfectly okay. Every day is different. 💙");
      expect(MoodUtils.getSupportiveMessage(EmotionType.sad), 
             "It's okay to feel this way. Take care of yourself. 💜");
    });

    test('MoodUtils should validate mood entries correctly', () {
      expect(MoodUtils.isValidMoodEntry(
        userId: 'user_123',
        emotionType: EmotionType.happy,
      ), true);

      expect(MoodUtils.isValidMoodEntry(
        userId: '',
        emotionType: EmotionType.happy,
      ), false);

      expect(MoodUtils.isValidMoodEntry(
        userId: 'user_123',
        emotionType: EmotionType.happy,
        notes: 'A' * 501, // Too long
      ), false);
    });

    test('MoodUtils should check if mood entry is recent', () {
      final now = DateTime.now();
      final recent = now.subtract(const Duration(hours: 2));
      final old = now.subtract(const Duration(hours: 6));

      expect(MoodUtils.isMoodEntryRecent(recent), true);
      expect(MoodUtils.isMoodEntryRecent(old), false);
    });

    test('MoodStatistics should have correct default values', () {
      const stats = MoodStatistics(
        totalEntries: 0,
        emotionCounts: {},
        averageMoodScore: 0.0,
        recentEntries: [],
      );

      expect(stats.totalEntries, 0);
      expect(stats.emotionCounts.isEmpty, true);
      expect(stats.averageMoodScore, 0.0);
      expect(stats.recentEntries.isEmpty, true);
    });

    test('MoodStatistics should return correct trend message', () {
      const statsEmpty = MoodStatistics(
        totalEntries: 0,
        emotionCounts: {},
        averageMoodScore: 0.0,
        recentEntries: [],
      );

      const statsPositive = MoodStatistics(
        totalEntries: 5,
        emotionCounts: {EmotionType.happy: 5},
        averageMoodScore: 2.0,
        recentEntries: [],
      );

      const statsNegative = MoodStatistics(
        totalEntries: 5,
        emotionCounts: {EmotionType.sad: 5},
        averageMoodScore: 0.0,
        recentEntries: [],
      );

      expect(statsEmpty.trendMessage, "Keep tracking your mood to see trends!");
      expect(statsPositive.trendMessage, "Your mood has been mostly positive this week!");
      expect(statsNegative.trendMessage, "Consider some self-care activities to boost your mood.");
    });
  });
}