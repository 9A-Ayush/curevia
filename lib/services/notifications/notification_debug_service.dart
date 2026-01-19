import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import 'fcm_token_service.dart';
import 'role_based_notification_service.dart';
import '../email_service.dart';

/// Debug service for testing notification and email functionality
class NotificationDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test appointment booking notifications
  static Future<Map<String, dynamic>> testAppointmentNotifications({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
  }) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test': 'appointment_notifications',
      'results': {},
    };

    try {
      // Get FCM tokens
      final patientToken = await FCMTokenService.getUserFCMToken(patientId);
      final doctorToken = await FCMTokenService.getDoctorFCMToken(doctorId);

      results['results']['fcm_tokens'] = {
        'patient_token_found': patientToken != null,
        'doctor_token_found': doctorToken != null,
        'patient_token': patientToken?.substring(0, 20) ?? 'null',
        'doctor_token': doctorToken?.substring(0, 20) ?? 'null',
      };

      // Test patient notification
      if (patientToken != null) {
        try {
          await RoleBasedNotificationService.instance.sendAppointmentBookingConfirmation(
            patientId: patientId,
            patientFCMToken: patientToken,
            doctorName: doctorName,
            appointmentId: 'test_appointment_${DateTime.now().millisecondsSinceEpoch}',
            appointmentDate: DateTime.now().add(const Duration(days: 1)),
            timeSlot: '10:00 AM',
            consultationType: 'online',
          );
          results['results']['patient_notification'] = 'success';
        } catch (e) {
          results['results']['patient_notification'] = 'failed: $e';
        }
      } else {
        results['results']['patient_notification'] = 'skipped: no FCM token';
      }

      // Test doctor notification
      if (doctorToken != null) {
        try {
          await RoleBasedNotificationService.instance.sendAppointmentBookingToDoctor(
            doctorId: doctorId,
            doctorFCMToken: doctorToken,
            patientName: patientName,
            appointmentId: 'test_appointment_${DateTime.now().millisecondsSinceEpoch}',
            appointmentDate: DateTime.now().add(const Duration(days: 1)),
            timeSlot: '10:00 AM',
            consultationType: 'online',
          );
          results['results']['doctor_notification'] = 'success';
        } catch (e) {
          results['results']['doctor_notification'] = 'failed: $e';
        }
      } else {
        results['results']['doctor_notification'] = 'skipped: no FCM token';
      }

    } catch (e) {
      results['results']['error'] = e.toString();
    }

    return results;
  }

  /// Test payment notifications
  static Future<Map<String, dynamic>> testPaymentNotifications({
    required String patientId,
    required String doctorId,
    required String patientName,
  }) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test': 'payment_notifications',
      'results': {},
    };

    try {
      // Get FCM tokens
      final patientToken = await FCMTokenService.getUserFCMToken(patientId);
      final doctorToken = await FCMTokenService.getDoctorFCMToken(doctorId);

      results['results']['fcm_tokens'] = {
        'patient_token_found': patientToken != null,
        'doctor_token_found': doctorToken != null,
      };

      // Test patient payment success notification
      if (patientToken != null) {
        try {
          await RoleBasedNotificationService.instance.sendPaymentSuccessToPatient(
            patientId: patientId,
            patientFCMToken: patientToken,
            paymentId: 'test_payment_${DateTime.now().millisecondsSinceEpoch}',
            orderId: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
            amount: 500.0,
            currency: 'INR',
            paymentMethod: 'UPI',
          );
          results['results']['patient_payment_notification'] = 'success';
        } catch (e) {
          results['results']['patient_payment_notification'] = 'failed: $e';
        }
      } else {
        results['results']['patient_payment_notification'] = 'skipped: no FCM token';
      }

      // Test doctor payment received notification
      if (doctorToken != null) {
        try {
          await RoleBasedNotificationService.instance.sendPaymentReceivedToDoctor(
            doctorId: doctorId,
            doctorFCMToken: doctorToken,
            patientName: patientName,
            paymentId: 'test_payment_${DateTime.now().millisecondsSinceEpoch}',
            amount: 500.0,
            currency: 'INR',
            appointmentId: 'test_appointment_${DateTime.now().millisecondsSinceEpoch}',
          );
          results['results']['doctor_payment_notification'] = 'success';
        } catch (e) {
          results['results']['doctor_payment_notification'] = 'failed: $e';
        }
      } else {
        results['results']['doctor_payment_notification'] = 'skipped: no FCM token';
      }

    } catch (e) {
      results['results']['error'] = e.toString();
    }

    return results;
  }

  /// Test admin verification notifications
  static Future<Map<String, dynamic>> testAdminVerificationNotifications({
    required String doctorId,
    required String doctorName,
    required String doctorEmail,
  }) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test': 'admin_verification_notifications',
      'results': {},
    };

    try {
      // Get admin FCM tokens
      final adminTokens = await FCMTokenService.getAdminFCMTokens();

      results['results']['admin_tokens'] = {
        'count': adminTokens.length,
        'tokens_found': adminTokens.isNotEmpty,
      };

      if (adminTokens.isNotEmpty) {
        try {
          await RoleBasedNotificationService.instance.sendDoctorVerificationRequestToAdmin(
            adminFCMTokens: adminTokens,
            doctorId: doctorId,
            doctorName: doctorName,
            email: doctorEmail,
            specialization: 'General Medicine',
            phoneNumber: '+91 9876543210',
          );
          results['results']['admin_notification'] = 'success';
        } catch (e) {
          results['results']['admin_notification'] = 'failed: $e';
        }
      } else {
        results['results']['admin_notification'] = 'skipped: no admin tokens';
      }

    } catch (e) {
      results['results']['error'] = e.toString();
    }

    return results;
  }

  /// Test doctor verification status notifications
  static Future<Map<String, dynamic>> testDoctorVerificationStatusNotifications({
    required String doctorId,
    required String status, // 'approved' or 'rejected'
    String? rejectionReason,
  }) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test': 'doctor_verification_status_notifications',
      'results': {},
    };

    try {
      // Get doctor FCM token
      final doctorToken = await FCMTokenService.getDoctorFCMToken(doctorId);

      results['results']['doctor_token_found'] = doctorToken != null;

      if (doctorToken != null) {
        try {
          // Test push notification
          await RoleBasedNotificationService.instance.sendVerificationStatusUpdate(
            doctorId: doctorId,
            doctorFCMToken: doctorToken,
            status: status,
            rejectionReason: rejectionReason,
          );
          results['results']['push_notification'] = 'success';
        } catch (e) {
          results['results']['push_notification'] = 'failed: $e';
        }

        try {
          // Test email notification
          await EmailService.sendDoctorVerificationEmail(
            doctorId: doctorId,
            status: status,
            adminId: 'test_admin',
          );
          results['results']['email_notification'] = 'success';
        } catch (e) {
          results['results']['email_notification'] = 'failed: $e';
        }
      } else {
        results['results']['push_notification'] = 'skipped: no FCM token';
        results['results']['email_notification'] = 'skipped: no FCM token';
      }

    } catch (e) {
      results['results']['error'] = e.toString();
    }

    return results;
  }

  /// Test email service connectivity
  static Future<Map<String, dynamic>> testEmailService() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test': 'email_service_connectivity',
      'results': {},
    };

    try {
      // Test with a dummy doctor ID
      final testResult = await EmailService.sendDoctorVerificationEmail(
        doctorId: 'test_doctor_${DateTime.now().millisecondsSinceEpoch}',
        status: 'approved',
        adminId: 'test_admin',
      );

      results['results']['email_service_response'] = testResult ? 'success' : 'failed';
    } catch (e) {
      results['results']['email_service_response'] = 'failed: $e';
    }

    return results;
  }

  /// Get comprehensive notification system status
  static Future<Map<String, dynamic>> getSystemStatus() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'system_status': {},
    };

    try {
      // Count users with FCM tokens
      final usersWithTokens = await _firestore
          .collection(AppConstants.usersCollection)
          .where('fcmToken', isNull: false)
          .get();

      // Count doctors with FCM tokens
      final doctorsWithTokens = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('fcmToken', isNull: false)
          .get();

      // Count admins
      final admins = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'admin')
          .get();

      // Count admins with FCM tokens
      final adminsWithTokens = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'admin')
          .where('fcmToken', isNull: false)
          .get();

      // Count recent notifications
      final recentNotifications = await _firestore
          .collection('notifications')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))
          ))
          .get();

      results['system_status'] = {
        'users_with_fcm_tokens': usersWithTokens.docs.length,
        'doctors_with_fcm_tokens': doctorsWithTokens.docs.length,
        'total_admins': admins.docs.length,
        'admins_with_fcm_tokens': adminsWithTokens.docs.length,
        'notifications_last_24h': recentNotifications.docs.length,
        'email_service_configured': true, // EmailService exists
      };

    } catch (e) {
      results['system_status']['error'] = e.toString();
    }

    return results;
  }

  /// Run comprehensive notification tests
  static Future<Map<String, dynamic>> runComprehensiveTests({
    required String testPatientId,
    required String testDoctorId,
    required String testPatientName,
    required String testDoctorName,
    required String testDoctorEmail,
  }) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'comprehensive_test_results': {},
    };

    try {
      // Run all tests
      final systemStatus = await getSystemStatus();
      final appointmentTest = await testAppointmentNotifications(
        patientId: testPatientId,
        doctorId: testDoctorId,
        patientName: testPatientName,
        doctorName: testDoctorName,
      );
      final paymentTest = await testPaymentNotifications(
        patientId: testPatientId,
        doctorId: testDoctorId,
        patientName: testPatientName,
      );
      final adminTest = await testAdminVerificationNotifications(
        doctorId: testDoctorId,
        doctorName: testDoctorName,
        doctorEmail: testDoctorEmail,
      );
      final verificationApprovalTest = await testDoctorVerificationStatusNotifications(
        doctorId: testDoctorId,
        status: 'approved',
      );
      final verificationRejectionTest = await testDoctorVerificationStatusNotifications(
        doctorId: testDoctorId,
        status: 'rejected',
        rejectionReason: 'Test rejection reason',
      );
      final emailTest = await testEmailService();

      results['comprehensive_test_results'] = {
        'system_status': systemStatus,
        'appointment_notifications': appointmentTest,
        'payment_notifications': paymentTest,
        'admin_notifications': adminTest,
        'verification_approval': verificationApprovalTest,
        'verification_rejection': verificationRejectionTest,
        'email_service': emailTest,
      };

      // Generate summary
      final summary = <String, int>{
        'total_tests': 6,
        'passed': 0,
        'failed': 0,
        'skipped': 0,
      };

      for (final test in results['comprehensive_test_results'].values) {
        if (test is Map<String, dynamic> && test.containsKey('results')) {
          final testResults = test['results'] as Map<String, dynamic>;
          for (final result in testResults.values) {
            if (result is String) {
              if (result == 'success') summary['passed'] = (summary['passed'] ?? 0) + 1;
              else if (result.startsWith('failed:')) summary['failed'] = (summary['failed'] ?? 0) + 1;
              else if (result.startsWith('skipped:')) summary['skipped'] = (summary['skipped'] ?? 0) + 1;
            }
          }
        }
      }

      results['test_summary'] = summary;

    } catch (e) {
      results['comprehensive_test_results']['error'] = e.toString();
    }

    return results;
  }
}