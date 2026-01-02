import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/patient_service.dart';
import '../../models/user_model.dart';

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
      if (userId == null) {
        print('=== HEALTH METRICS ERROR ===');
        print('No user logged in');
        return null;
      }

      print('=== FETCHING HEALTH METRICS ===');
      print('User ID: $userId');

      final doc = await _firestore
          .collection('healthMetrics')
          .doc(userId)
          .get();

      if (!doc.exists) {
        print('No health metrics found, creating default with patient data...');
        try {
          // Get patient data to fetch actual weight
          final patientModel = await PatientService.getPatientById(userId);
          final defaultMetrics = _getDefaultMetrics(userId, patientModel);
          
          // Save default metrics to Firestore for future use
          await updateMetrics(defaultMetrics);
          print('Default metrics created and saved');
          
          return defaultMetrics;
        } catch (e) {
          print('Error getting patient data: $e');
          // Return basic default metrics if patient service fails
          final basicMetrics = _getBasicDefaultMetrics(userId);
          await updateMetrics(basicMetrics);
          return basicMetrics;
        }
      }

      final healthMetrics = HealthMetrics.fromMap(doc.data()!);
      print('Health metrics loaded:');
      print('- Heart Rate: ${healthMetrics.heartRate} bpm');
      print('- Weight: ${healthMetrics.weight} kg');
      print('- BMI: ${healthMetrics.bmi}');
      
      // If weight is default (70) or 0, try to get actual weight from patient profile
      if (healthMetrics.weight == 70.0 || healthMetrics.weight == 0.0) {
        print('Default weight detected, fetching from patient profile...');
        try {
          final patientModel = await PatientService.getPatientById(userId);
          if (patientModel?.weight != null && patientModel!.weight! > 0) {
            print('Found patient weight: ${patientModel.weight} kg');
            // Update health metrics with actual weight
            final updatedMetrics = HealthMetrics(
              userId: healthMetrics.userId,
              heartRate: healthMetrics.heartRate,
              steps: healthMetrics.steps,
              bloodPressureSystolic: healthMetrics.bloodPressureSystolic,
              bloodPressureDiastolic: healthMetrics.bloodPressureDiastolic,
              bloodSugar: healthMetrics.bloodSugar,
              weight: patientModel.weight!,
              bmi: patientModel.bmi ?? _calculateBMI(patientModel.weight!, patientModel.height),
              healthStatus: healthMetrics.healthStatus,
              lastUpdated: DateTime.now(),
            );
            
            // Save updated metrics to Firestore
            await updateMetrics(updatedMetrics);
            return updatedMetrics;
          }
        } catch (e) {
          print('Error updating weight from patient profile: $e');
          // Return original metrics if update fails
        }
      }

      return healthMetrics;
    } catch (e) {
      print('=== HEALTH METRICS ERROR ===');
      print('Error fetching health metrics: $e');
      print('Stack trace: ${StackTrace.current}');
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

  /// Update heart rate specifically
  static Future<void> updateHeartRate(int heartRate) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('healthMetrics')
          .doc(userId)
          .set({
        'heartRate': heartRate,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Heart rate updated to $heartRate bpm');
    } catch (e) {
      print('Error updating heart rate: $e');
      rethrow;
    }
  }

  /// Update weight specifically
  static Future<void> updateWeight(double weight) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Calculate BMI if height is available
      final patientModel = await PatientService.getPatientById(userId);
      double? bmi;
      if (patientModel?.height != null && patientModel!.height! > 0) {
        bmi = _calculateBMI(weight, patientModel.height);
      }

      // Update health metrics
      final updateData = {
        'weight': weight,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (bmi != null) {
        updateData['bmi'] = bmi;
      }

      await _firestore
          .collection('healthMetrics')
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
      
      print('Weight updated to $weight kg${bmi != null ? ', BMI: ${bmi.toStringAsFixed(1)}' : ''}');
    } catch (e) {
      print('Error updating weight: $e');
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

  /// Simulate real-time heart rate (for demo purposes)
  /// In a real app, this would connect to a fitness tracker or health sensor
  static Future<void> simulateRealTimeHeartRate() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Generate a realistic heart rate between 60-100 bpm
      final random = DateTime.now().millisecondsSinceEpoch % 41;
      final heartRate = 60 + random; // 60-100 bpm range
      
      await updateHeartRate(heartRate);
    } catch (e) {
      print('Error simulating heart rate: $e');
    }
  }

  /// Get default metrics for new users
  static HealthMetrics _getDefaultMetrics(String userId, [PatientModel? patientModel]) {
    double weight = 70.0; // Default weight
    double bmi = 22.5; // Default BMI
    
    // Use actual weight from patient profile if available
    if (patientModel?.weight != null && patientModel!.weight! > 0) {
      weight = patientModel.weight!;
      print('Using patient weight: $weight kg');
      
      // Calculate BMI if height is available
      if (patientModel.height != null && patientModel.height! > 0) {
        bmi = patientModel.bmi ?? _calculateBMI(weight, patientModel.height);
        print('Calculated BMI: $bmi');
      }
    } else {
      print('Using default weight: $weight kg');
    }
    
    return HealthMetrics(
      userId: userId,
      heartRate: 75,
      steps: 0,
      bloodPressureSystolic: 120,
      bloodPressureDiastolic: 80,
      bloodSugar: 90,
      weight: weight,
      bmi: bmi,
      healthStatus: 'Good',
      lastUpdated: DateTime.now(),
    );
  }

  /// Get basic default metrics without patient data (fallback)
  static HealthMetrics _getBasicDefaultMetrics(String userId) {
    return HealthMetrics(
      userId: userId,
      heartRate: 75,
      steps: 0,
      bloodPressureSystolic: 120,
      bloodPressureDiastolic: 80,
      bloodSugar: 90,
      weight: 70.0,
      bmi: 22.5,
      healthStatus: 'Good',
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculate BMI from weight and height
  static double _calculateBMI(double weight, double? height) {
    if (height == null || height <= 0) return 22.5; // Default BMI
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Stream health metrics updates
  static Stream<HealthMetrics?> streamUserMetrics() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection('healthMetrics')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) {
        try {
          // Get patient data for default metrics
          final patientModel = await PatientService.getPatientById(userId);
          return _getDefaultMetrics(userId, patientModel);
        } catch (e) {
          print('Error getting patient data in stream: $e');
          // Return basic default metrics if patient service fails
          return _getBasicDefaultMetrics(userId);
        }
      }
      return HealthMetrics.fromMap(doc.data()!);
    });
  }
}
