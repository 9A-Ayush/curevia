import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/mood_model.dart';

/// Service for managing mood entries in Firebase
class MoodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'mood_entries';

  /// Save a new mood entry
  static Future<String> saveMoodEntry({
    required String userId,
    required EmotionType emotionType,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final moodEntry = MoodEntry(
        id: '', // Will be set by Firestore
        userId: userId,
        mood: emotionType.emoji,
        label: emotionType.label,
        emotionType: emotionType,
        timestamp: DateTime.now(),
        notes: notes,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(moodEntry.toFirestore());

      print('Mood entry saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving mood entry: $e');
      throw Exception('Failed to save mood entry: $e');
    }
  }

  /// Get mood entries stream for real-time updates
  static Stream<List<MoodEntry>> getMoodEntriesStream({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      // Try the optimized query with ordering first
      try {
        query = query.orderBy('timestamp', descending: true);
        
        // Apply date filters if provided
        if (startDate != null) {
          query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        if (endDate != null) {
          query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }

        // Apply limit if provided
        if (limit != null) {
          query = query.limit(limit);
        }

        return query.snapshots().map((snapshot) {
          final entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
          print('Mood entries loaded successfully: ${entries.length} items');
          return entries;
        });
      } catch (indexError) {
        print('Index not ready, using fallback query: $indexError');
        
        // Fallback: Simple query without ordering (will work without index)
        return _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .limit(limit ?? 50)
            .snapshots()
            .map((snapshot) {
              var entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
              
              // Sort client-side since we can't use orderBy without index
              entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              
              // Apply date filters client-side if needed
              if (startDate != null) {
                entries = entries.where((entry) => entry.timestamp.isAfter(startDate)).toList();
              }
              if (endDate != null) {
                entries = entries.where((entry) => entry.timestamp.isBefore(endDate)).toList();
              }
              
              print('Mood entries loaded with fallback: ${entries.length} items');
              return entries;
            });
      }
    } catch (e) {
      print('Error getting mood entries stream: $e');
      return Stream.value([]);
    }
  }

  /// Get mood entries for a specific date range
  static Future<List<MoodEntry>> getMoodEntries({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      // Try optimized query first
      try {
        query = query.orderBy('timestamp', descending: true);

        // Apply date filters
        if (startDate != null) {
          query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        if (endDate != null) {
          query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }

        // Apply limit
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        return snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
      } catch (indexError) {
        print('Index not ready, using fallback query: $indexError');
        
        // Fallback: Simple query without ordering
        final snapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .limit(limit ?? 50)
            .get();
            
        var entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
        
        // Sort client-side
        entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Apply date filters client-side
        if (startDate != null) {
          entries = entries.where((entry) => entry.timestamp.isAfter(startDate)).toList();
        }
        if (endDate != null) {
          entries = entries.where((entry) => entry.timestamp.isBefore(endDate)).toList();
        }
        
        return entries;
      }
    } catch (e) {
      print('Error getting mood entries: $e');
      return [];
    }
  }

  /// Get recent mood entries (last 7 days)
  static Future<List<MoodEntry>> getRecentMoodEntries({
    required String userId,
    int days = 7,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return getMoodEntries(
      userId: userId,
      startDate: startDate,
      limit: 50,
    );
  }

  /// Get mood statistics
  static Future<MoodStatistics> getMoodStatistics({
    required String userId,
    int days = 7,
  }) async {
    try {
      final entries = await getRecentMoodEntries(userId: userId, days: days);
      
      if (entries.isEmpty) {
        return const MoodStatistics(
          totalEntries: 0,
          emotionCounts: {},
          averageMoodScore: 0.0,
          recentEntries: [],
        );
      }

      // Count emotions
      final emotionCounts = <EmotionType, int>{};
      double totalScore = 0.0;

      for (final entry in entries) {
        emotionCounts[entry.emotionType] = (emotionCounts[entry.emotionType] ?? 0) + 1;
        
        // Calculate mood score (happy=2, normal=1, sad=0)
        switch (entry.emotionType) {
          case EmotionType.happy:
            totalScore += 2.0;
            break;
          case EmotionType.normal:
            totalScore += 1.0;
            break;
          case EmotionType.sad:
            totalScore += 0.0;
            break;
        }
      }

      // Find dominant mood
      EmotionType? dominantMood;
      int maxCount = 0;
      emotionCounts.forEach((emotion, count) {
        if (count > maxCount) {
          maxCount = count;
          dominantMood = emotion;
        }
      });

      final averageScore = totalScore / entries.length;
      final lastEntry = entries.isNotEmpty ? entries.first : null;

      return MoodStatistics(
        totalEntries: entries.length,
        emotionCounts: emotionCounts,
        dominantMood: dominantMood,
        averageMoodScore: averageScore,
        recentEntries: entries.take(10).toList(),
        lastEntryDate: lastEntry?.timestamp,
      );
    } catch (e) {
      print('Error getting mood statistics: $e');
      return const MoodStatistics(
        totalEntries: 0,
        emotionCounts: {},
        averageMoodScore: 0.0,
        recentEntries: [],
      );
    }
  }

  /// Update a mood entry
  static Future<void> updateMoodEntry({
    required String entryId,
    EmotionType? emotionType,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (emotionType != null) {
        updateData['mood'] = emotionType.emoji;
        updateData['label'] = emotionType.label;
        updateData['emotionType'] = emotionType.toString();
      }
      
      if (notes != null) {
        updateData['notes'] = notes;
      }
      
      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(entryId).update(updateData);
      print('Mood entry updated: $entryId');
    } catch (e) {
      print('Error updating mood entry: $e');
      throw Exception('Failed to update mood entry: $e');
    }
  }

  /// Delete a mood entry
  static Future<void> deleteMoodEntry(String entryId) async {
    try {
      await _firestore.collection(_collection).doc(entryId).delete();
      print('Mood entry deleted: $entryId');
    } catch (e) {
      print('Error deleting mood entry: $e');
      throw Exception('Failed to delete mood entry: $e');
    }
  }

  /// Get mood entry by ID
  static Future<MoodEntry?> getMoodEntryById(String entryId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(entryId).get();
      if (doc.exists) {
        return MoodEntry.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting mood entry by ID: $e');
      return null;
    }
  }

  /// Check if user has logged mood today
  static Future<bool> hasMoodEntryToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking today\'s mood entry: $e');
      return false;
    }
  }

  /// Get mood entries for a specific date
  static Future<List<MoodEntry>> getMoodEntriesForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting mood entries for date: $e');
      return [];
    }
  }
}