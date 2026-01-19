import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription_model.dart';

/// Service for managing prescriptions
class PrescriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'prescriptions';

  /// Create a new prescription
  static Future<String> createPrescription(PrescriptionModel prescription) async {
    try {
      final docRef = await _firestore.collection(_collection).add(prescription.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create prescription: $e');
    }
  }

  /// Get prescriptions for a doctor
  static Future<List<PrescriptionModel>> getDoctorPrescriptions(
    String doctorId, {
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('prescriptionDate', descending: true);

      if (startDate != null) {
        query = query.where('prescriptionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('prescriptionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get doctor prescriptions: $e');
    }
  }

  /// Get prescriptions for a patient
  static Future<List<PrescriptionModel>> getPatientPrescriptions(
    String patientId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .orderBy('prescriptionDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // If patientId field doesn't exist or there's an index issue, 
      // try alternative approach using patient name or other fields
      print('Error getting patient prescriptions by patientId: $e');
      
      // For now, return empty list. In production, you might want to:
      // 1. Create the necessary Firestore index
      // 2. Use a different query strategy
      // 3. Store patient prescriptions in a separate collection
      return [];
    }
  }

  /// Get prescriptions for a patient by name (fallback method)
  static Future<List<PrescriptionModel>> getPatientPrescriptionsByName(
    String patientName, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('patientName', isEqualTo: patientName)
          .orderBy('prescriptionDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get patient prescriptions by name: $e');
    }
  }

  /// Get prescriptions for a patient (tries multiple methods)
  static Future<List<PrescriptionModel>> getPatientPrescriptionsComprehensive(
    String patientId,
    String patientName, {
    int limit = 50,
  }) async {
    try {
      // First try by patient ID
      final prescriptionsByIds = await getPatientPrescriptions(patientId, limit: limit);
      if (prescriptionsByIds.isNotEmpty) {
        return prescriptionsByIds;
      }
      
      // Fallback to patient name
      return await getPatientPrescriptionsByName(patientName, limit: limit);
    } catch (e) {
      throw Exception('Failed to get patient prescriptions: $e');
    }
  }

  /// Get a specific prescription by ID
  static Future<PrescriptionModel?> getPrescriptionById(String prescriptionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(prescriptionId).get();
      
      if (!doc.exists) return null;
      
      return PrescriptionModel.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get prescription: $e');
    }
  }

  /// Update a prescription
  static Future<void> updatePrescription(String prescriptionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection(_collection).doc(prescriptionId).update(updates);
    } catch (e) {
      throw Exception('Failed to update prescription: $e');
    }
  }

  /// Delete a prescription
  static Future<void> deletePrescription(String prescriptionId) async {
    try {
      await _firestore.collection(_collection).doc(prescriptionId).delete();
    } catch (e) {
      throw Exception('Failed to delete prescription: $e');
    }
  }

  /// Get prescriptions for today for a doctor
  static Future<List<PrescriptionModel>> getTodayPrescriptions(String doctorId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return getDoctorPrescriptions(
      doctorId,
      startDate: today,
      endDate: tomorrow,
    );
  }

  /// Get recent prescriptions (last 7 days) for a doctor
  static Future<List<PrescriptionModel>> getRecentPrescriptions(String doctorId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return getDoctorPrescriptions(
      doctorId,
      startDate: weekAgo,
    );
  }

  /// Search prescriptions by patient name or diagnosis
  static Future<List<PrescriptionModel>> searchPrescriptions(
    String doctorId,
    String searchQuery, {
    int limit = 50,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that gets all prescriptions and filters client-side
      // For production, consider using Algolia or similar service for better search
      
      final prescriptions = await getDoctorPrescriptions(doctorId, limit: limit);
      
      final query = searchQuery.toLowerCase();
      return prescriptions.where((prescription) {
        return prescription.patientName.toLowerCase().contains(query) ||
               prescription.diagnosis?.toLowerCase().contains(query) == true ||
               prescription.medicines.any((medicine) => 
                   medicine.medicineName.toLowerCase().contains(query));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search prescriptions: $e');
    }
  }

  /// Get prescription statistics for a doctor
  static Future<Map<String, int>> getPrescriptionStats(String doctorId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonth = DateTime(now.year, now.month, 1);
      
      // Get all prescriptions for the month
      final monthlyPrescriptions = await getDoctorPrescriptions(
        doctorId,
        startDate: thisMonth,
        limit: 1000,
      );
      
      final todayCount = monthlyPrescriptions.where((p) => 
          p.prescriptionDate.year == today.year &&
          p.prescriptionDate.month == today.month &&
          p.prescriptionDate.day == today.day).length;
      
      final monthlyCount = monthlyPrescriptions.length;
      
      // Count unique patients
      final uniquePatients = monthlyPrescriptions
          .map((p) => p.patientId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .length;
      
      return {
        'today': todayCount,
        'thisMonth': monthlyCount,
        'uniquePatients': uniquePatients,
      };
    } catch (e) {
      throw Exception('Failed to get prescription stats: $e');
    }
  }

  /// Get most prescribed medicines for a doctor
  static Future<List<Map<String, dynamic>>> getMostPrescribedMedicines(
    String doctorId, {
    int limit = 10,
  }) async {
    try {
      final prescriptions = await getDoctorPrescriptions(doctorId, limit: 500);
      
      final medicineCount = <String, int>{};
      
      for (final prescription in prescriptions) {
        for (final medicine in prescription.medicines) {
          final name = medicine.medicineName;
          medicineCount[name] = (medicineCount[name] ?? 0) + 1;
        }
      }
      
      final sortedMedicines = medicineCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedMedicines
          .take(limit)
          .map((entry) => {
                'name': entry.key,
                'count': entry.value,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get most prescribed medicines: $e');
    }
  }
}