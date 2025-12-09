import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart';

/// Service for tracking user activities
class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _activitiesCollection = 'user_activities';

  /// Log a new activity
  static Future<void> logActivity({
    required String userId,
    required String type,
    required String title,
    required String description,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activityId = _firestore.collection(_activitiesCollection).doc().id;
      final now = DateTime.now();

      final activity = {
        'id': activityId,
        'userId': userId,
        'type': type,
        'title': title,
        'description': description,
        'relatedId': relatedId,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection(_activitiesCollection)
          .doc(activityId)
          .set(activity);
    } catch (e) {
      // Silently fail - activity logging shouldn't break the app
      // In production, log to error tracking service
    }
  }

  /// Get recent activities for a user
  static Future<List<ActivityModel>> getRecentActivities({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // In production, log to error tracking service
      return [];
    }
  }

  /// Stream of recent activities
  static Stream<List<ActivityModel>> getActivitiesStream({
    required String userId,
    int limit = 10,
  }) {
    return _firestore
        .collection(_activitiesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityModel.fromMap(doc.data()))
            .toList());
  }

  /// Log appointment booking
  static Future<void> logAppointmentBooked({
    required String userId,
    required String appointmentId,
    required String doctorName,
  }) async {
    await logActivity(
      userId: userId,
      type: 'appointment_booked',
      title: 'Appointment Booked',
      description: 'Booked appointment with $doctorName',
      relatedId: appointmentId,
    );
  }

  /// Log appointment completed
  static Future<void> logAppointmentCompleted({
    required String userId,
    required String appointmentId,
    required String doctorName,
  }) async {
    await logActivity(
      userId: userId,
      type: 'appointment_completed',
      title: 'Appointment Completed',
      description: 'Completed consultation with $doctorName',
      relatedId: appointmentId,
    );
  }

  /// Log prescription received
  static Future<void> logPrescriptionReceived({
    required String userId,
    required String prescriptionId,
    required String doctorName,
  }) async {
    await logActivity(
      userId: userId,
      type: 'prescription_received',
      title: 'Prescription Received',
      description: 'Received prescription from $doctorName',
      relatedId: prescriptionId,
    );
  }

  /// Log health record added
  static Future<void> logHealthRecordAdded({
    required String userId,
    required String recordId,
    required String recordType,
  }) async {
    await logActivity(
      userId: userId,
      type: 'health_record_added',
      title: 'Health Record Added',
      description: 'Added new $recordType record',
      relatedId: recordId,
    );
  }

  /// Log symptom check
  static Future<void> logSymptomCheck({
    required String userId,
    required List<String> symptoms,
  }) async {
    await logActivity(
      userId: userId,
      type: 'symptom_check',
      title: 'Symptom Check',
      description: 'Checked symptoms: ${symptoms.join(", ")}',
      metadata: {'symptoms': symptoms},
    );
  }

  /// Log medicine search
  static Future<void> logMedicineSearch({
    required String userId,
    required String medicineName,
  }) async {
    await logActivity(
      userId: userId,
      type: 'medicine_search',
      title: 'Medicine Search',
      description: 'Searched for $medicineName',
      metadata: {'medicine': medicineName},
    );
  }
}
