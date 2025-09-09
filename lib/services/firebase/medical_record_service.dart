import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/medical_record_model.dart';

/// Service for managing medical records
class MedicalRecordService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get medical records for a user
  static Future<List<MedicalRecordModel>> getMedicalRecords(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get medical records: $e');
    }
  }

  /// Add medical record
  static Future<String> addMedicalRecord({
    required String userId,
    required String title,
    required String type,
    required DateTime recordDate,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? vitals,
    Map<String, dynamic>? labResults,
  }) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .add({
        'title': title,
        'type': type,
        'recordDate': Timestamp.fromDate(recordDate),
        'doctorName': doctorName,
        'hospitalName': hospitalName,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'prescription': prescription,
        'notes': notes,
        'attachments': attachments ?? [],
        'vitals': vitals ?? {},
        'labResults': labResults ?? {},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add medical record: $e');
    }
  }

  /// Update medical record
  static Future<void> updateMedicalRecord({
    required String userId,
    required String recordId,
    String? title,
    String? type,
    DateTime? recordDate,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? vitals,
    Map<String, dynamic>? labResults,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (type != null) updateData['type'] = type;
      if (recordDate != null) {
        updateData['recordDate'] = Timestamp.fromDate(recordDate);
      }
      if (doctorName != null) updateData['doctorName'] = doctorName;
      if (hospitalName != null) updateData['hospitalName'] = hospitalName;
      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (treatment != null) updateData['treatment'] = treatment;
      if (prescription != null) updateData['prescription'] = prescription;
      if (notes != null) updateData['notes'] = notes;
      if (attachments != null) updateData['attachments'] = attachments;
      if (vitals != null) updateData['vitals'] = vitals;
      if (labResults != null) updateData['labResults'] = labResults;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .doc(recordId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update medical record: $e');
    }
  }

  /// Delete medical record
  static Future<void> deleteMedicalRecord(String userId, String recordId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete medical record: $e');
    }
  }

  /// Get medical record by ID
  static Future<MedicalRecordModel?> getMedicalRecordById(
    String userId, 
    String recordId,
  ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .doc(recordId)
          .get();

      if (!doc.exists) return null;

      return MedicalRecordModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get medical record: $e');
    }
  }

  /// Get medical records by type
  static Future<List<MedicalRecordModel>> getMedicalRecordsByType(
    String userId, 
    String type,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .where('type', isEqualTo: type)
          .orderBy('recordDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get medical records by type: $e');
    }
  }

  /// Get medical records stream for real-time updates
  static Stream<List<MedicalRecordModel>> getMedicalRecordsStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('medical_records')
        .orderBy('recordDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get recent medical records (last 30 days)
  static Future<List<MedicalRecordModel>> getRecentMedicalRecords(
    String userId,
  ) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .where('recordDate', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('recordDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent medical records: $e');
    }
  }

  /// Get medical record count
  static Future<int> getMedicalRecordCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('medical_records')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get medical record count: $e');
    }
  }
}
