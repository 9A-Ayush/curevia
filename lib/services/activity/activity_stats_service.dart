import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Activity stats model
class ActivityStats {
  final String userId;
  final int dailySteps;
  final int dailyGoal;
  final double caloriesBurned;
  final int activeMinutes;
  final double distanceKm;
  final int workoutsCompleted;
  final DateTime date;

  const ActivityStats({
    required this.userId,
    required this.dailySteps,
    required this.dailyGoal,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.distanceKm,
    required this.workoutsCompleted,
    required this.date,
  });

  factory ActivityStats.fromMap(Map<String, dynamic> map) {
    return ActivityStats(
      userId: map['userId'] ?? '',
      dailySteps: map['dailySteps'] ?? 0,
      dailyGoal: map['dailyGoal'] ?? 10000,
      caloriesBurned: (map['caloriesBurned'] ?? 0).toDouble(),
      activeMinutes: map['activeMinutes'] ?? 0,
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      workoutsCompleted: map['workoutsCompleted'] ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dailySteps': dailySteps,
      'dailyGoal': dailyGoal,
      'caloriesBurned': caloriesBurned,
      'activeMinutes': activeMinutes,
      'distanceKm': distanceKm,
      'workoutsCompleted': workoutsCompleted,
      'date': Timestamp.fromDate(date),
    };
  }

  /// Calculate progress percentage
  double get progressPercentage {
    if (dailyGoal == 0) return 0;
    return (dailySteps / dailyGoal * 100).clamp(0, 100);
  }

  /// Check if goal is achieved
  bool get isGoalAchieved => dailySteps >= dailyGoal;
}

/// Weekly activity summary
class WeeklyActivitySummary {
  final int totalSteps;
  final double totalCalories;
  final int totalActiveMinutes;
  final double totalDistance;
  final int totalWorkouts;
  final double averageSteps;
  final List<ActivityStats> dailyStats;

  const WeeklyActivitySummary({
    required this.totalSteps,
    required this.totalCalories,
    required this.totalActiveMinutes,
    required this.totalDistance,
    required this.totalWorkouts,
    required this.averageSteps,
    required this.dailyStats,
  });
}

/// Service for managing activity stats
class ActivityStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get today's activity stats
  static Future<ActivityStats?> getTodayStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('activityStats')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return _getDefaultStats(userId);
      }

      return ActivityStats.fromMap(snapshot.docs.first.data());
    } catch (e) {
      print('Error fetching today stats: $e');
      return null;
    }
  }

  /// Update activity stats
  static Future<void> updateStats(ActivityStats stats) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final docId = '${stats.userId}_${startOfDay.millisecondsSinceEpoch}';
      
      await _firestore
          .collection('activityStats')
          .doc(docId)
          .set(stats.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating activity stats: $e');
      rethrow;
    }
  }

  /// Increment steps
  static Future<void> incrementSteps(int steps) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final docId = '${userId}_${startOfDay.millisecondsSinceEpoch}';

      await _firestore
          .collection('activityStats')
          .doc(docId)
          .set({
        'userId': userId,
        'dailySteps': FieldValue.increment(steps),
        'date': Timestamp.fromDate(startOfDay),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error incrementing steps: $e');
    }
  }

  /// Get weekly activity summary
  static Future<WeeklyActivitySummary?> getWeeklySummary() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final snapshot = await _firestore
          .collection('activityStats')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final dailyStats = snapshot.docs
          .map((doc) => ActivityStats.fromMap(doc.data()))
          .toList();

      final totalSteps = dailyStats.fold<int>(0, (sum, stat) => sum + stat.dailySteps);
      final totalCalories = dailyStats.fold<double>(0, (sum, stat) => sum + stat.caloriesBurned);
      final totalActiveMinutes = dailyStats.fold<int>(0, (sum, stat) => sum + stat.activeMinutes);
      final totalDistance = dailyStats.fold<double>(0, (sum, stat) => sum + stat.distanceKm);
      final totalWorkouts = dailyStats.fold<int>(0, (sum, stat) => sum + stat.workoutsCompleted);
      final averageSteps = dailyStats.isNotEmpty ? totalSteps / dailyStats.length : 0;

      return WeeklyActivitySummary(
        totalSteps: totalSteps,
        totalCalories: totalCalories,
        totalActiveMinutes: totalActiveMinutes,
        totalDistance: totalDistance,
        totalWorkouts: totalWorkouts,
        averageSteps: averageSteps.toDouble(),
        dailyStats: dailyStats,
      );
    } catch (e) {
      print('Error fetching weekly summary: $e');
      return null;
    }
  }

  /// Get activity history
  static Future<List<ActivityStats>> getActivityHistory({
    int days = 30,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('activityStats')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityStats.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching activity history: $e');
      return [];
    }
  }

  /// Set daily goal
  static Future<void> setDailyGoal(int goal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final docId = '${userId}_${startOfDay.millisecondsSinceEpoch}';

      await _firestore
          .collection('activityStats')
          .doc(docId)
          .set({
        'userId': userId,
        'dailyGoal': goal,
        'date': Timestamp.fromDate(startOfDay),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting daily goal: $e');
    }
  }

  /// Stream today's activity stats
  static Stream<ActivityStats?> streamTodayStats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final docId = '${userId}_${startOfDay.millisecondsSinceEpoch}';

    return _firestore
        .collection('activityStats')
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return _getDefaultStats(userId);
      return ActivityStats.fromMap(doc.data()!);
    });
  }

  /// Get default stats for new users
  static ActivityStats _getDefaultStats(String userId) {
    return ActivityStats(
      userId: userId,
      dailySteps: 0,
      dailyGoal: 10000,
      caloriesBurned: 0,
      activeMinutes: 0,
      distanceKm: 0,
      workoutsCompleted: 0,
      date: DateTime.now(),
    );
  }
}
