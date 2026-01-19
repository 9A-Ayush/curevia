import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import 'fcm_service.dart';
import 'fcm_token_service.dart';

/// Service specifically for payment notifications
class PaymentNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send payment success notification to patient
  static Future<void> sendPaymentSuccessToPatient({
    required String patientId,
    required String appointmentId,
    required double amount,
    required String paymentMethod,
    String? doctorName,
  }) async {
    try {
      print('🔔 Sending payment success notification to patient: $patientId');
      
      // Get patient's FCM token
      final patientFCMToken = await FCMTokenService.getUserFCMToken(patientId);
      
      if (patientFCMToken == null) {
        print('⚠️ No FCM token found for patient: $patientId');
        return;
      }

      // Create notification
      final notification = NotificationModel(
        id: 'payment_success_${DateTime.now().millisecondsSinceEpoch}',
        title: '💰 Payment Received Successfully!',
        body: 'Your payment of ₹${amount.toStringAsFixed(0)} via $paymentMethod has been confirmed${doctorName != null ? ' for your appointment with Dr. $doctorName' : ''}.',
        type: NotificationType.paymentSuccess,
        data: {
          'appointmentId': appointmentId,
          'amount': amount.toString(),
          'paymentMethod': paymentMethod,
          'patientId': patientId,
          if (doctorName != null) 'doctorName': doctorName,
        },
        timestamp: DateTime.now(),
      );

      // Send FCM notification
      await FCMService.instance.showLocalNotification(notification);

      // Store in Firestore for notification history
      await _firestore.collection('notifications').add({
        'userId': patientId,
        'type': 'payment_success',
        'title': notification.title,
        'body': notification.body,
        'data': notification.data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print('✅ Payment success notification sent to patient: $patientId');
    } catch (e) {
      print('❌ Error sending payment success notification: $e');
    }
  }

  /// Send payment received notification to doctor
  static Future<void> sendPaymentReceivedToDoctor({
    required String doctorId,
    required String appointmentId,
    required double amount,
    required String paymentMethod,
    required String patientName,
  }) async {
    try {
      print('🔔 Sending payment received notification to doctor: $doctorId');
      
      // Get doctor's FCM token
      final doctorFCMToken = await FCMTokenService.getDoctorFCMToken(doctorId);
      
      if (doctorFCMToken == null) {
        print('⚠️ No FCM token found for doctor: $doctorId');
        return;
      }

      // Create notification
      final notification = NotificationModel(
        id: 'payment_received_${DateTime.now().millisecondsSinceEpoch}',
        title: '💰 Payment Received',
        body: 'Payment of ₹${amount.toStringAsFixed(0)} received from $patientName via $paymentMethod.',
        type: NotificationType.paymentReceived,
        data: {
          'appointmentId': appointmentId,
          'amount': amount.toString(),
          'paymentMethod': paymentMethod,
          'patientName': patientName,
          'doctorId': doctorId,
        },
        timestamp: DateTime.now(),
      );

      // Send FCM notification
      await FCMService.instance.showLocalNotification(notification);

      // Store in Firestore for notification history
      await _firestore.collection('notifications').add({
        'userId': doctorId,
        'type': 'payment_received',
        'title': notification.title,
        'body': notification.body,
        'data': notification.data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print('✅ Payment received notification sent to doctor: $doctorId');
    } catch (e) {
      print('❌ Error sending payment received notification: $e');
    }
  }

  /// Test payment notifications
  static Future<void> testPaymentNotifications({
    required String patientId,
    required String doctorId,
    String? appointmentId,
  }) async {
    try {
      print('🧪 Testing payment notifications...');
      
      final testAppointmentId = appointmentId ?? 'test_appointment_${DateTime.now().millisecondsSinceEpoch}';
      
      // Test patient notification
      await sendPaymentSuccessToPatient(
        patientId: patientId,
        appointmentId: testAppointmentId,
        amount: 500.0,
        paymentMethod: 'UPI',
        doctorName: 'Test Doctor',
      );
      
      // Test doctor notification
      await sendPaymentReceivedToDoctor(
        doctorId: doctorId,
        appointmentId: testAppointmentId,
        amount: 500.0,
        paymentMethod: 'UPI',
        patientName: 'Test Patient',
      );
      
      print('✅ Payment notification tests completed');
    } catch (e) {
      print('❌ Error testing payment notifications: $e');
    }
  }
}