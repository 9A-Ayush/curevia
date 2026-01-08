import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Email service for Curevia app integration
/// Connects to the Node.js email service for automated email workflows
class EmailService {
  // Email service configuration
  static const String _baseUrl = kDebugMode 
    ? 'http://localhost:3000'  // Development
    : 'https://curvia-mail-service.onrender.com';  // Production
  
  static const Duration _timeout = Duration(seconds: 30);
  
  /// Send doctor verification email (approval/rejection)
  /// Called when admin approves or rejects a doctor
  static Future<bool> sendDoctorVerificationEmail({
    required String doctorId,
    required String status, // 'approved' or 'rejected'
    String? adminId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-doctor-verification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'doctorId': doctorId,
          'status': status,
          'adminId': adminId,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Doctor verification email sent: ${data['message']}');
        return true;
      } else {
        debugPrint('❌ Failed to send doctor verification email: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }
  
  /// Send promotional campaign to opted-in users
  /// Called when admin creates marketing campaigns
  static Future<bool> sendPromotionalCampaign({
    required String title,
    required String subtitle,
    required String content,
    required String ctaText,
    required String ctaLink,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-promotional-campaign'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'campaignData': {
            'title': title,
            'subtitle': subtitle,
            'content': content,
            'ctaText': ctaText,
            'ctaLink': ctaLink,
          }
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Promotional campaign sent: ${data['message']}');
        return true;
      } else {
        debugPrint('❌ Failed to send promotional campaign: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }
  
  /// Send health tip newsletter
  /// Called when admin publishes health tips
  static Future<bool> sendHealthTip({
    required String title,
    required String content,
    List<String>? actionItems,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-health-tip'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tip': {
            'title': title,
            'content': content,
            'actionItems': actionItems ?? [],
          }
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Health tip sent: ${data['message']}');
        return true;
      } else {
        debugPrint('❌ Failed to send health tip: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }
  
  /// Send test email for development/testing
  static Future<bool> sendTestEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/test-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Test email sent: ${data['message']}');
        return true;
      } else {
        debugPrint('❌ Failed to send test email: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }
  
  /// Get user email preferences
  static Future<Map<String, dynamic>?> getUserEmailPreferences(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/preferences/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['preferences'];
      } else {
        debugPrint('❌ Failed to get email preferences: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return null;
    }
  }
  
  /// Update user email preferences
  static Future<bool> updateUserEmailPreferences(
    String userId,
    Map<String, bool> preferences,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/preferences/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'preferences': preferences,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        debugPrint('✅ Email preferences updated');
        return true;
      } else {
        debugPrint('❌ Failed to update email preferences: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }
  
  /// Unsubscribe user from all emails
  static Future<bool> unsubscribeUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/unsubscribe/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        debugPrint('✅ User unsubscribed from all emails');
        return true;
      } else {
        debugPrint('❌ Failed to unsubscribe user: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }
  
  /// Get email service health status
  static Future<Map<String, dynamic>?> getServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Email service health check failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return null;
    }
  }
  
  /// Get email service statistics
  static Future<Map<String, dynamic>?> getEmailStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Failed to get email stats: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return null;
    }
  }
}

/// Email preferences model for user settings
class EmailPreferences {
  final bool promotional;
  final bool healthTips;
  final bool doctorUpdates;
  final bool appointmentReminders;
  
  const EmailPreferences({
    this.promotional = false,
    this.healthTips = true,
    this.doctorUpdates = true,
    this.appointmentReminders = true,
  });
  
  factory EmailPreferences.fromJson(Map<String, dynamic> json) {
    return EmailPreferences(
      promotional: json['promotional'] ?? false,
      healthTips: json['healthTips'] ?? true,
      doctorUpdates: json['doctorUpdates'] ?? true,
      appointmentReminders: json['appointmentReminders'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'promotional': promotional,
      'healthTips': healthTips,
      'doctorUpdates': doctorUpdates,
      'appointmentReminders': appointmentReminders,
    };
  }
  
  EmailPreferences copyWith({
    bool? promotional,
    bool? healthTips,
    bool? doctorUpdates,
    bool? appointmentReminders,
  }) {
    return EmailPreferences(
      promotional: promotional ?? this.promotional,
      healthTips: healthTips ?? this.healthTips,
      doctorUpdates: doctorUpdates ?? this.doctorUpdates,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
    );
  }
}