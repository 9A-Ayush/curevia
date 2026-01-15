import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/email_service.dart';

/// Diagnostic utility to test and troubleshoot email service issues
class EmailServiceDiagnostic {
  static const String _baseUrl = kDebugMode 
    ? 'http://localhost:3000'  // Development
    : 'https://curvia-mail-service.onrender.com';  // Production
  
  /// Run comprehensive email service diagnostics
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'summary': <String, dynamic>{},
    };

    print('🔍 Starting Email Service Diagnostics...\n');

    // Test 1: Service Health Check
    results['tests']['healthCheck'] = await _testServiceHealth();
    
    // Test 2: Firebase Connection
    results['tests']['firebaseConnection'] = await _testFirebaseConnection();
    
    // Test 3: Email Service Configuration
    results['tests']['emailConfig'] = await _testEmailConfiguration();
    
    // Test 4: Doctor Verification Endpoint
    results['tests']['doctorVerificationEndpoint'] = await _testDoctorVerificationEndpoint();
    
    // Test 5: Test Email Functionality
    results['tests']['testEmail'] = await _testEmailFunctionality();

    // Generate summary
    results['summary'] = _generateSummary(results['tests']);
    
    print('\n📊 Diagnostic Summary:');
    print('Health Check: ${results['summary']['healthCheck']}');
    print('Firebase: ${results['summary']['firebase']}');
    print('Email Config: ${results['summary']['emailConfig']}');
    print('Doctor Verification: ${results['summary']['doctorVerification']}');
    print('Test Email: ${results['summary']['testEmail']}');
    print('\nOverall Status: ${results['summary']['overall']}');

    return results;
  }

  /// Test service health and availability
  static Future<Map<String, dynamic>> _testServiceHealth() async {
    print('🏥 Testing service health...');
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Service is healthy');
        print('   Status: ${data['status']}');
        print('   Emails sent today: ${data['dailyStats']?['emailsSentToday'] ?? 'N/A'}');
        print('   Daily limit: ${data['dailyStats']?['dailyLimit'] ?? 'N/A'}');
        
        return {
          'status': 'success',
          'data': data,
          'message': 'Service is healthy and responding'
        };
      } else {
        print('❌ Service health check failed');
        print('   Status code: ${response.statusCode}');
        print('   Response: ${response.body}');
        
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Service health check failed',
          'response': response.body
        };
      }
    } catch (e) {
      print('❌ Service health check error: $e');
      return {
        'status': 'error',
        'message': 'Cannot connect to email service',
        'error': e.toString()
      };
    }
  }

  /// Test Firebase connection and configuration
  static Future<Map<String, dynamic>> _testFirebaseConnection() async {
    print('\n🔥 Testing Firebase connection...');
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/realtime'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final firebaseStats = data['firebase'];
        
        print('✅ Firebase connection successful');
        print('   Total doctors: ${firebaseStats?['doctors']?['total'] ?? 'N/A'}');
        print('   Pending verifications: ${firebaseStats?['doctors']?['pending'] ?? 'N/A'}');
        print('   Active listeners: ${firebaseStats?['listeners']?['active'] ?? 'N/A'}');
        
        return {
          'status': 'success',
          'data': firebaseStats,
          'message': 'Firebase connection is working'
        };
      } else {
        print('❌ Firebase connection test failed');
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Firebase connection test failed'
        };
      }
    } catch (e) {
      print('❌ Firebase connection error: $e');
      return {
        'status': 'error',
        'message': 'Firebase connection failed',
        'error': e.toString()
      };
    }
  }

  /// Test email service configuration
  static Future<Map<String, dynamic>> _testEmailConfiguration() async {
    print('\n📧 Testing email configuration...');
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['stats'];
        
        print('✅ Email configuration is valid');
        print('   Service: ${data['service'] ?? 'N/A'}');
        print('   Monthly limit: ${data['monthlyLimit'] ?? 'N/A'}');
        print('   Emails sent today: ${stats?['emailsSentToday'] ?? 'N/A'}');
        print('   Remaining today: ${stats?['remaining'] ?? 'N/A'}');
        
        return {
          'status': 'success',
          'data': data,
          'message': 'Email configuration is valid'
        };
      } else {
        print('❌ Email configuration test failed');
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Email configuration test failed'
        };
      }
    } catch (e) {
      print('❌ Email configuration error: $e');
      return {
        'status': 'error',
        'message': 'Email configuration test failed',
        'error': e.toString()
      };
    }
  }

  /// Test doctor verification endpoint
  static Future<Map<String, dynamic>> _testDoctorVerificationEndpoint() async {
    print('\n👨‍⚕️ Testing doctor verification endpoint...');
    
    try {
      // Test with invalid data to check endpoint availability
      final response = await http.post(
        Uri.parse('$_baseUrl/send-doctor-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorId': 'test-doctor-id',
          'status': 'test-status', // Invalid status to test validation
        }),
      ).timeout(const Duration(seconds: 10));
      
      // We expect a 400 error for invalid status, which means endpoint is working
      if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (data['error']?.toString().contains('status must be either')) {
          print('✅ Doctor verification endpoint is working');
          print('   Endpoint validation is functioning correctly');
          
          return {
            'status': 'success',
            'message': 'Doctor verification endpoint is working',
            'validation': 'Endpoint validation is functioning'
          };
        }
      }
      
      print('❌ Doctor verification endpoint test failed');
      print('   Status code: ${response.statusCode}');
      print('   Response: ${response.body}');
      
      return {
        'status': 'error',
        'statusCode': response.statusCode,
        'message': 'Doctor verification endpoint test failed',
        'response': response.body
      };
    } catch (e) {
      print('❌ Doctor verification endpoint error: $e');
      return {
        'status': 'error',
        'message': 'Doctor verification endpoint test failed',
        'error': e.toString()
      };
    }
  }

  /// Test email functionality with a test email
  static Future<Map<String, dynamic>> _testEmailFunctionality() async {
    print('\n📨 Testing email functionality...');
    
    try {
      // Use a test email address
      const testEmail = 'test@example.com';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/test-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': testEmail}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Test email functionality working');
        print('   Message: ${data['message']}');
        
        return {
          'status': 'success',
          'data': data,
          'message': 'Test email functionality is working'
        };
      } else {
        print('❌ Test email failed');
        print('   Status code: ${response.statusCode}');
        print('   Response: ${response.body}');
        
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Test email failed',
          'response': response.body
        };
      }
    } catch (e) {
      print('❌ Test email error: $e');
      return {
        'status': 'error',
        'message': 'Test email failed',
        'error': e.toString()
      };
    }
  }

  /// Generate diagnostic summary
  static Map<String, dynamic> _generateSummary(Map<String, dynamic> tests) {
    final summary = <String, String>{};
    
    summary['healthCheck'] = tests['healthCheck']['status'] == 'success' ? '✅ OK' : '❌ FAIL';
    summary['firebase'] = tests['firebaseConnection']['status'] == 'success' ? '✅ OK' : '❌ FAIL';
    summary['emailConfig'] = tests['emailConfig']['status'] == 'success' ? '✅ OK' : '❌ FAIL';
    summary['doctorVerification'] = tests['doctorVerificationEndpoint']['status'] == 'success' ? '✅ OK' : '❌ FAIL';
    summary['testEmail'] = tests['testEmail']['status'] == 'success' ? '✅ OK' : '❌ FAIL';
    
    final successCount = summary.values.where((v) => v.contains('✅')).length;
    final totalTests = summary.length;
    
    if (successCount == totalTests) {
      summary['overall'] = '✅ ALL SYSTEMS OPERATIONAL';
    } else if (successCount >= totalTests * 0.8) {
      summary['overall'] = '⚠️ MOSTLY OPERATIONAL';
    } else {
      summary['overall'] = '❌ MULTIPLE ISSUES DETECTED';
    }
    
    return summary;
  }

  /// Test doctor verification email specifically
  static Future<bool> testDoctorVerificationEmail({
    required String doctorId,
    required String status,
  }) async {
    print('🧪 Testing doctor verification email for $doctorId...');
    
    try {
      final result = await EmailService.sendDoctorVerificationEmail(
        doctorId: doctorId,
        status: status,
        adminId: 'test-admin',
      );
      
      if (result) {
        print('✅ Doctor verification email test successful');
        return true;
      } else {
        print('❌ Doctor verification email test failed');
        return false;
      }
    } catch (e) {
      print('❌ Doctor verification email test error: $e');
      return false;
    }
  }

  /// Check if email service is reachable
  static Future<bool> isEmailServiceReachable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get email service status
  static Future<String> getEmailServiceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] ?? 'Unknown';
      } else {
        return 'Service Error (${response.statusCode})';
      }
    } catch (e) {
      return 'Unreachable';
    }
  }
}