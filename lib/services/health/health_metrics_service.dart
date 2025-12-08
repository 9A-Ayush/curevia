import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Health metrics model
class HealthMetrics {
  final String userId;
  final int heartRate;
  final int steps;
  final double bloodPressureSystolic;
  final double bloodPressureDiastolic;
  final double bloodSugar;
  final double weight;
  final double bmi;
  final String healthStatus; // 'Good', 'Fair', 'Poor'
  final DateTime lastUpdated;

  const HealthMetrics({
    required this.userId,
    required this.heartRate,
    required this.steps,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.bloodSugar,
    required this.weight,
    required this.bmi,
    required this.healthStatus,
    required this.lastUpdated,
  });

  factory HealthMetrics.fromMap(Map<String, dynamic> map) {
    return HealthMetrics(
      userId: map['userId'] ?? '',
      heartRate: map['heartRate'] ?? 0,
      steps: map['steps'] ?? 0,
      bloodPressureSystolic: (map['bloodPressureSystolic'] ?? 0).toDouble(),
      bloodPressureDiastolic: (map['bloodPressureDiastolic'] ?? 0).toDouble(),
      bloodSugar: (map['bloodSugar'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      bmi: (map['bmi'] ?? 0).toDouble(),
      healthStatus: map['healthStatus'] ?? 'Good',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'heartRate': heartRate,
      'steps': steps,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'bloodSugar': bloodSugar,
      'weight': weight,
      'bmi': bmi,
      'healthStatus': healthStatus,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Calculate health status based on metrics
  static String calculateHealthStatus({
    required int heartRate,
    required double bloodPressureSystolic,
    required double bloodSugar,
    required double bmi,
  }) {
    int score = 0;

    // Heart rate check (60-100 is normal)
    if (heartRate >= 60 && heartRate <= 100) score++;

    // Blood pressure check (systolic < 120 is normal)
    if (bloodPressureSystolic < 120) score++;

    // Blood sugar check (< 100 mg/dL is normal)
    if (bloodSugar < 100) score++;

    // BMI check (18.5-24.9 is normal)
    if (bmi >= 18.5 && bmi <= 24.9) score++;

    if (score >= 3) return 'Good';
    if (score >= 2) return 'Fair';
    return 'Poor';
  }
}

/// Service for managing health metrics
class HealthMetricsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's health metrics
  static Future<HealthMetrics?> getCurrentUserMetrics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('healthMetrics')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Return default metrics if none exist
        return _getDefaultMetrics(userId);
      }

      return HealthMetrics.fromMap(doc.data()!);
    } catch (e) {
      print('Error fetching health metrics: $e');
      return null;
    }
  }

  /// Update health metrics
  static Future<void> updateMetrics(HealthMetrics metrics) async {
    try {
      await _firestore
          .collection('healthMetrics')
          .doc(metrics.userId)
          .set(metrics.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating health metrics: $e');
      rethrow;
    }
  }

  /// Update specific metric
  static Future<void> updateSpecificMetric({
    required String metricName,
    required dynamic value,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('healthMetrics')
          .doc(userId)
          .set({
        metricName: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating specific metric: $e');
      rethrow;
    }
  }

  /// Get health metrics history
  static Future<List<HealthMetrics>> getMetricsHistory({
    int limit = 30,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('healthMetrics')
          .doc(userId)
          .collection('history')
          .orderBy('lastUpdated', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => HealthMetrics.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching metrics history: $e');
      return [];
    }
  }

  /// Save metrics to history
  static Future<void> saveToHistory(HealthMetrics metrics) async {
    try {
      await _firestore
          .collection('healthMetrics')
          .doc(metrics.userId)
          .collection('history')
          .add(metrics.toMap());
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  /// Get default metrics for new users
  static HealthMetrics _getDefaultMetrics(String userId) {
    return HealthMetrics(
      userId: userId,
      heartRate: 75,
      steps: 0,
      bloodPressureSystolic: 120,
      bloodPressureDiastolic: 80,
      bloodSugar: 90,
      weight: 70,
      bmi: 22.5,
      healthStatus: 'Good',
      lastUpdated: DateTime.now(),
    );
  }

  /// Stream health metrics updates
  static Stream<HealthMetrics?> streamUserMetrics() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection('healthMetrics')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return _getDefaultMetrics(userId);
      return HealthMetrics.fromMap(doc.data()!);
    });
  }
}
