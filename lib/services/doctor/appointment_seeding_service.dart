import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';

/// Service for seeding test appointments for doctors
class AppointmentSeedingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed sample appointments for a doctor
  static Future<void> seedSampleAppointments({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
  }) async {
    try {
      print('🌱 Seeding sample appointments for doctor: $doctorName');

      // Create sample patients
      final samplePatients = [
        {
          'id': 'patient_1_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'John Doe',
          'phone': '+91 9876543210',
          'email': 'john.doe@example.com',
        },
        {
          'id': 'patient_2_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Jane Smith',
          'phone': '+91 9876543211',
          'email': 'jane.smith@example.com',
        },
        {
          'id': 'patient_3_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Robert Johnson',
          'phone': '+91 9876543212',
          'email': 'robert.johnson@example.com',
        },
      ];

      // Create sample appointments
      final now = DateTime.now();
      final appointments = [
        // Today's appointments
        AppointmentModel(
          id: 'apt_today_1_${now.millisecondsSinceEpoch}',
          patientId: samplePatients[0]['id']!,
          patientName: samplePatients[0]['name']!,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          appointmentDate: now,
          timeSlot: '10:00 AM - 10:30 AM',
          consultationType: 'offline',
          status: 'confirmed',
          paymentStatus: 'completed',
          consultationFee: 500.0,
          notes: 'Regular checkup',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        AppointmentModel(
          id: 'apt_today_2_${now.millisecondsSinceEpoch}',
          patientId: samplePatients[1]['id']!,
          patientName: samplePatients[1]['name']!,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          appointmentDate: now,
          timeSlot: '2:00 PM - 2:30 PM',
          consultationType: 'online',
          status: 'confirmed',
          paymentStatus: 'completed',
          consultationFee: 400.0,
          notes: 'Follow-up consultation',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),

        // Tomorrow's appointments
        AppointmentModel(
          id: 'apt_tomorrow_1_${now.millisecondsSinceEpoch}',
          patientId: samplePatients[2]['id']!,
          patientName: samplePatients[2]['name']!,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          appointmentDate: now.add(const Duration(days: 1)),
          timeSlot: '11:00 AM - 11:30 AM',
          consultationType: 'offline',
          status: 'confirmed',
          paymentStatus: 'pay_on_clinic',
          consultationFee: 600.0,
          notes: 'New patient consultation',
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),

        // Past completed appointment
        AppointmentModel(
          id: 'apt_past_1_${now.millisecondsSinceEpoch}',
          patientId: samplePatients[0]['id']!,
          patientName: samplePatients[0]['name']!,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          appointmentDate: now.subtract(const Duration(days: 3)),
          timeSlot: '3:00 PM - 3:30 PM',
          consultationType: 'offline',
          status: 'completed',
          paymentStatus: 'completed',
          consultationFee: 500.0,
          notes: 'Routine checkup completed',
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),

        // Cancelled appointment
        AppointmentModel(
          id: 'apt_cancelled_1_${now.millisecondsSinceEpoch}',
          patientId: samplePatients[1]['id']!,
          patientName: samplePatients[1]['name']!,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          appointmentDate: now.subtract(const Duration(days: 1)),
          timeSlot: '4:00 PM - 4:30 PM',
          consultationType: 'online',
          status: 'cancelled',
          paymentStatus: 'refunded',
          consultationFee: 400.0,
          notes: 'Patient cancelled due to emergency',
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      // Save appointments to Firestore
      final batch = _firestore.batch();
      
      for (final appointment in appointments) {
        final docRef = _firestore.collection('appointments').doc(appointment.id);
        batch.set(docRef, appointment.toMap());
      }

      await batch.commit();
      
      print('✅ Successfully seeded ${appointments.length} sample appointments');
      print('📊 Breakdown:');
      print('   - Today: 2 appointments');
      print('   - Tomorrow: 1 appointment');
      print('   - Past: 1 completed appointment');
      print('   - Cancelled: 1 appointment');
      
    } catch (e) {
      print('❌ Error seeding appointments: $e');
      rethrow;
    }
  }

  /// Clear all sample appointments for a doctor
  static Future<void> clearSampleAppointments({
    required String doctorId,
  }) async {
    try {
      print('🧹 Clearing sample appointments for doctor: $doctorId');

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientName', whereIn: ['John Doe', 'Jane Smith', 'Robert Johnson'])
          .get();

      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      print('✅ Cleared ${querySnapshot.docs.length} sample appointments');
      
    } catch (e) {
      print('❌ Error clearing sample appointments: $e');
      rethrow;
    }
  }

  /// Check if doctor has any appointments
  static Future<bool> hasAppointments({
    required String doctorId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking appointments: $e');
      return false;
    }
  }

  /// Get appointment statistics for a doctor
  static Future<Map<String, int>> getAppointmentStats({
    required String doctorId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
        'pending': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to data
        final appointment = AppointmentModel.fromMap(data);
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[appointment.status] = (stats[appointment.status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Error getting appointment stats: $e');
      return {};
    }
  }
}