import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify the production email service deployment
/// Run with: dart test_production_api.dart
void main() async {
  const baseUrl = 'https://curvia-mail-service.onrender.com';
  
  print('🔥 Testing Curevia Email Service Production Deployment');
  print('URL: $baseUrl');
  print('');
  
  // Test 1: Health Check
  print('📊 Test 1: Health Check');
  try {
    print('   Making request... (may take 30-60s to wake up Render service)');
    
    final healthResponse = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 90)); // Extended timeout for Render wake-up
    
    if (healthResponse.statusCode == 200) {
      final healthData = jsonDecode(healthResponse.body);
      print('   ✅ Health Check: SUCCESS');
      print('   Status: ${healthData['status']}');
      print('   Service: ${healthData['service']}');
      print('   Firebase Status: ${healthData['firebase']['error'] ?? 'Connected'}');
      print('   Real-time Listeners: ${healthData['realTime']['listenersActive']}');
    } else {
      print('   ❌ Health Check: FAILED (${healthResponse.statusCode})');
      print('   Response: ${healthResponse.body}');
    }
  } catch (e) {
    print('   ❌ Health Check: ERROR - $e');
  }
  
  print('');
  
  // Test 2: Available Endpoints
  print('📡 Test 2: Available Endpoints');
  try {
    final endpointsResponse = await http.get(
      Uri.parse('$baseUrl/nonexistent'), // This will return 404 with endpoint list
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 30));
    
    if (endpointsResponse.statusCode == 404) {
      final endpointsData = jsonDecode(endpointsResponse.body);
      print('   ✅ Endpoints List: SUCCESS');
      print('   Available endpoints:');
      for (final endpoint in endpointsData['availableEndpoints']) {
        print('     • $endpoint');
      }
    }
  } catch (e) {
    print('   ❌ Endpoints Test: ERROR - $e');
  }
  
  print('');
  
  // Test 3: Test Email (Optional - requires valid email)
  print('📧 Test 3: Test Email Function');
  print('   Skipping test email (requires valid email address)');
  print('   To test manually, use:');
  print('   curl -X POST $baseUrl/test-email \\');
  print('     -H "Content-Type: application/json" \\');
  print('     -d \'{"email":"your-email@example.com"}\'');
  
  print('');
  
  // Test 4: Dashboard Access
  print('🖥️  Test 4: Dashboard Access');
  try {
    final dashboardResponse = await http.get(
      Uri.parse('$baseUrl/dashboard'),
    ).timeout(const Duration(seconds: 30));
    
    if (dashboardResponse.statusCode == 200) {
      print('   ✅ Dashboard: SUCCESS');
      print('   Dashboard available at: $baseUrl/dashboard');
    } else {
      print('   ❌ Dashboard: FAILED (${dashboardResponse.statusCode})');
    }
  } catch (e) {
    print('   ❌ Dashboard: ERROR - $e');
  }
  
  print('');
  print('🎉 Production API Test Complete!');
  print('');
  print('📋 Next Steps:');
  print('1. Visit dashboard: $baseUrl/dashboard');
  print('2. Test email functionality with your Flutter app');
  print('3. Monitor real-time features in dashboard');
  print('4. Check Firebase integration is working');
  print('');
  print('🔧 If service is slow to respond:');
  print('   - Render free tier spins down after inactivity');
  print('   - First request may take 30-60 seconds');
  print('   - Subsequent requests will be fast');
}