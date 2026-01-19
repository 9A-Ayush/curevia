import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Direct FCM service using backend with Firebase Admin SDK
class FCMDirectService {
  static const String _baseUrl = kDebugMode 
    ? 'http://localhost:3000'
    : 'https://YOUR_RENDER_SERVICE_NAME.onrender.com';
  
  static const Duration _timeout = Duration(seconds: 30);
  
  /// Send test FCM notification
  static Future<bool> sendTestNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
    String? sound,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/test-fcm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
          'data': data,
          'channelId': channelId,
          'sound': sound,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Test FCM notification sent: ${result['result']['messageId']}');
        return true;
      } else {
        debugPrint('❌ Test FCM notification failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test FCM notification error: $e');
      return false;
    }
  }
  
  /// Send appointment notification (FCM + Email)
  static Future<Map<String, dynamic>> sendAppointmentNotification({
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required String type, // 'booked', 'confirmed', 'cancelled', 'reminder'
    Map<String, dynamic>? appointmentData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-appointment-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'appointmentId': appointmentId,
          'type': type,
          'appointmentData': appointmentData,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Appointment notification sent: ${result['message']}');
        return result;
      } else {
        debugPrint('❌ Appointment notification failed: ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      debugPrint('❌ Appointment notification error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Send payment notification (FCM + Email)
  static Future<Map<String, dynamic>> sendPaymentNotification({
    required String patientId,
    String? doctorId,
    required String paymentId,
    required String type, // 'success', 'failed', 'refund'
    required double amount,
    Map<String, dynamic>? paymentData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-payment-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'paymentId': paymentId,
          'type': type,
          'amount': amount,
          'paymentData': paymentData,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Payment notification sent: ${result['message']}');
        return result;
      } else {
        debugPrint('❌ Payment notification failed: ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      debugPrint('❌ Payment notification error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Send doctor verification notification (FCM + Email)
  static Future<Map<String, dynamic>> sendDoctorVerificationNotification({
    required String doctorId,
    required String status, // 'approved', 'rejected'
    String? adminId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-doctor-verification-with-fcm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorId': doctorId,
          'status': status,
          'adminId': adminId,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Doctor verification notification sent: ${result['message']}');
        return result;
      } else {
        debugPrint('❌ Doctor verification notification failed: ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      debugPrint('❌ Doctor verification notification error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Send bulk FCM notifications
  static Future<Map<String, dynamic>> sendBulkNotifications({
    required List<String> fcmTokens,
    required String title,
    required String body,
    String? channelId,
    String? sound,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-bulk-fcm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmTokens': fcmTokens,
          'title': title,
          'body': body,
          'channelId': channelId,
          'sound': sound,
          'data': data,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Bulk FCM notifications sent: ${result['message']}');
        return result;
      } else {
        debugPrint('❌ Bulk FCM notifications failed: ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      debugPrint('❌ Bulk FCM notifications error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Validate FCM token
  static Future<bool> validateFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validate-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['valid'] == true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('❌ FCM token validation error: $e');
      return false;
    }
  }
  
  /// Get FCM service health status
  static Future<Map<String, dynamic>?> getServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ FCM service health check error: $e');
      return null;
    }
  }
  
  /// Test FCM service connectivity
  static Future<bool> testServiceConnectivity() async {
    try {
      final health = await getServiceHealth();
      return health != null && health['status'] != null;
    } catch (e) {
      debugPrint('❌ FCM service connectivity test failed: $e');
      return false;
    }
  }
  
  /// Send admin notification
  static Future<bool> sendAdminNotification({
    required List<String> adminFCMTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (adminFCMTokens.isEmpty) {
        debugPrint('⚠️ No admin FCM tokens provided');
        return false;
      }
      
      final result = await sendBulkNotifications(
        fcmTokens: adminFCMTokens,
        title: title,
        body: body,
        channelId: 'admin_notifications',
        sound: 'default',
        data: data,
      );
      
      return result['success'] == true;
    } catch (e) {
      debugPrint('❌ Admin FCM notification error: $e');
      return false;
    }
  }
  
  /// Send health tip notification
  static Future<bool> sendHealthTipNotification({
    required String fcmToken,
    required String tipTitle,
    required String tipContent,
    String? category,
  }) async {
    try {
      return await sendTestNotification(
        fcmToken: fcmToken,
        title: 'Health Tip: $tipTitle',
        body: tipContent,
        data: {
          'type': 'health_tip',
          'category': category ?? 'general',
        },
        channelId: 'health_tips',
        sound: 'default',
      );
    } catch (e) {
      debugPrint('❌ Health tip FCM notification error: $e');
      return false;
    }
  }
  
  /// Send emergency notification
  static Future<bool> sendEmergencyNotification({
    required List<String> fcmTokens,
    required String emergencyType,
    required String message,
    Map<String, dynamic>? locationData,
  }) async {
    try {
      final result = await sendBulkNotifications(
        fcmTokens: fcmTokens,
        title: 'Emergency Alert: $emergencyType',
        body: message,
        channelId: 'emergency',
        sound: 'emergency_alert',
        data: {
          'type': 'emergency',
          'emergencyType': emergencyType,
          'locationData': locationData,
        },
      );
      
      return result['success'] == true;
    } catch (e) {
      debugPrint('❌ Emergency FCM notifications error: $e');
      return false;
    }
  }
}