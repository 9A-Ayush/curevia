import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_model.dart';
import '../services/firebase/mood_service.dart';

/// Mood tracking state
class MoodTrackingState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final EmotionType? selectedEmotion;
  final List<MoodEntry> moodHistory;
  final MoodStatistics? statistics;
  final bool hasLoggedToday;

  const MoodTrackingState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.selectedEmotion,
    this.moodHistory = const [],
    this.statistics,
    this.hasLoggedToday = false,
  });

  MoodTrackingState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    EmotionType? selectedEmotion,
    List<MoodEntry>? moodHistory,
    MoodStatistics? statistics,
    bool? hasLoggedToday,
  }) {
    return MoodTrackingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      moodHistory: moodHistory ?? this.moodHistory,
      statistics: statistics ?? this.statistics,
      hasLoggedToday: hasLoggedToday ?? this.hasLoggedToday,
    );
  }
}

/// Mood tracking provider
class MoodTrackingNotifier extends StateNotifier<MoodTrackingState> {
  MoodTrackingNotifier() : super(const MoodTrackingState());

  /// Save a new mood entry
  Future<String?> saveMoodEntry({
    required String userId,
    required EmotionType emotionType,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final entryId = await MoodService.saveMoodEntry(
        userId: userId,
        emotionType: emotionType,
        notes: notes,
        metadata: metadata,
      );

      state = state.copyWith(
        isLoading: false,
        selectedEmotion: emotionType,
        successMessage: 'Mood logged successfully!',
        hasLoggedToday: true,
      );

      // Refresh mood history and statistics
      await loadMoodHistory(userId: userId);
      await loadMoodStatistics(userId: userId);

      return entryId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Load mood history
  Future<void> loadMoodHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final entries = await MoodService.getMoodEntries(
        userId: userId,
        limit: limit ?? 50,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(moodHistory: entries);
    } catch (e) {
      print('Error loading mood history: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load mood statistics
  Future<void> loadMoodStatistics({
    required String userId,
    int days = 7,
  }) async {
    try {
      final statistics = await MoodService.getMoodStatistics(
        userId: userId,
        days: days,
      );

      state = state.copyWith(statistics: statistics);
    } catch (e) {
      print('Error loading mood statistics: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Check if user has logged mood today
  Future<void> checkTodaysMoodEntry(String userId) async {
    try {
      final hasLogged = await MoodService.hasMoodEntryToday(userId);
      state = state.copyWith(hasLoggedToday: hasLogged);
    } catch (e) {
      print('Error checking today\'s mood entry: $e');
    }
  }

  /// Update a mood entry
  Future<void> updateMoodEntry({
    required String entryId,
    required String userId,
    EmotionType? emotionType,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await MoodService.updateMoodEntry(
        entryId: entryId,
        emotionType: emotionType,
        notes: notes,
        metadata: metadata,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Mood entry updated successfully!',
      );

      // Refresh data
      await loadMoodHistory(userId: userId);
      await loadMoodStatistics(userId: userId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a mood entry
  Future<void> deleteMoodEntry({
    required String entryId,
    required String userId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await MoodService.deleteMoodEntry(entryId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Mood entry deleted successfully!',
      );

      // Refresh data
      await loadMoodHistory(userId: userId);
      await loadMoodStatistics(userId: userId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Select emotion (for UI state)
  void selectEmotion(EmotionType emotion) {
    state = state.copyWith(selectedEmotion: emotion);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear state
  void clearState() {
    state = const MoodTrackingState();
  }
}

/// Provider instances
final moodTrackingProvider = StateNotifierProvider.autoDispose<MoodTrackingNotifier, MoodTrackingState>((ref) {
  return MoodTrackingNotifier();
});

/// Real-time mood entries stream provider
final moodEntriesStreamProvider = StreamProvider.family.autoDispose<List<MoodEntry>, String>((ref, userId) {
  return MoodService.getMoodEntriesStream(
    userId: userId,
    limit: 50,
  );
});

/// Recent mood entries provider (last 7 days)
final recentMoodEntriesProvider = FutureProvider.family.autoDispose<List<MoodEntry>, String>((ref, userId) async {
  return await MoodService.getRecentMoodEntries(userId: userId);
});

/// Mood statistics provider
final moodStatisticsProvider = FutureProvider.family.autoDispose<MoodStatistics, String>((ref, userId) async {
  return await MoodService.getMoodStatistics(userId: userId);
});

/// Today's mood check provider
final todaysMoodCheckProvider = FutureProvider.family.autoDispose<bool, String>((ref, userId) async {
  return await MoodService.hasMoodEntryToday(userId);
});

/// Individual mood entry provider
final moodEntryProvider = FutureProvider.family<MoodEntry?, String>((ref, entryId) async {
  return await MoodService.getMoodEntryById(entryId);
});

/// Mood entries for specific date provider
final moodEntriesForDateProvider = FutureProvider.family<List<MoodEntry>, Map<String, dynamic>>((ref, params) async {
  return await MoodService.getMoodEntriesForDate(
    userId: params['userId'] as String,
    date: params['date'] as DateTime,
  );
});