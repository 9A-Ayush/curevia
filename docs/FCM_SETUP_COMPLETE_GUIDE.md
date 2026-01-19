# Complete FCM Setup Guide - Curevia App

## Overview
This guide will help you set up Firebase Cloud Messaging (FCM) for sending push notifications in your Curevia app using the Firebase Admin SDK service account key.

## 🔑 Service Account Key Setup

### 1. Service Account Key Location
You have the service account key at:
```
d:\folder\curevia\curevia-f31a8-firebase-adminsdk-fbsvc-1a9966980f.json
```

### 2. Key Details
- **Project ID**: `curevia-f31a8`
- **Service Account Email**: `firebase-adminsdk-fbsvc@curevia-f31a8.iam.gserviceaccount.com`
- **Key ID**: `1a9966980fd5f07bce6c37feb2c8e45897d1d4ff`

## 🚀 Backend Setup (Node.js Email Service)

### 1. Move Service Account Key
Move the service account key to your email service directory:

```bash
# Copy the key to your email service folder
copy "d:\folder\curevia\curevia-f31a8-firebase-adminsdk-fbsvc-1a9966980f.json" "email-service\serviceAccountKey.json"
```

### 2. Update Email Service Environment
Add to `email-service/.env`:

```env
# Firebase Admin SDK
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
FIREBASE_PROJECT_ID=curevia-f31a8

# FCM Configuration
FCM_SERVER_KEY_PATH=./serviceAccountKey.json
```

### 3. Install Firebase Admin SDK
In your email service directory:

```bash
cd email-service
npm install firebase-admin
```

### 4. Create FCM Service Module
Create `email-service/services/fcm-service.js`:

```javascript
const admin = require('firebase-admin');
const path = require('path');

class FCMService {
  constructor() {
    this.initialized = false;
    this.initializeFirebase();
  }

  initializeFirebase() {
    try {
      if (!admin.apps.length) {
        const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
        
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: 'curevia-f31a8'
        });
        
        this.initialized = true;
        console.log('✅ Firebase Admin SDK initialized successfully');
      }
    } catch (error) {
      console.error('❌ Firebase Admin SDK initialization failed:', error);
      this.initialized = false;
    }
  }

  async sendNotification(fcmToken, notification) {
    if (!this.initialized) {
      throw new Error('Firebase Admin SDK not initialized');
    }

    try {
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl || undefined,
        },
        data: notification.data || {},
        android: {
          notification: {
            channelId: notification.channelId || 'default',
            sound: notification.sound || 'default',
            priority: 'high',
            defaultSound: true,
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: notification.sound || 'default',
              badge: 1,
              'content-available': 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ FCM notification sent successfully:', response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ FCM notification failed:', error);
      throw error;
    }
  }

  async sendBulkNotifications(tokens, notification) {
    if (!this.initialized) {
      throw new Error('Firebase Admin SDK not initialized');
    }

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl || undefined,
        },
        data: notification.data || {},
        tokens: tokens,
        android: {
          notification: {
            channelId: notification.channelId || 'default',
            sound: notification.sound || 'default',
            priority: 'high',
            defaultSound: true,
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: notification.sound || 'default',
              badge: 1,
              'content-available': 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`✅ Bulk FCM notifications sent: ${response.successCount}/${tokens.length}`);
      
      if (response.failureCount > 0) {
        console.warn(`⚠️ ${response.failureCount} notifications failed`);
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`❌ Token ${tokens[idx]} failed:`, resp.error);
          }
        });
      }

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
        responses: response.responses,
      };
    } catch (error) {
      console.error('❌ Bulk FCM notifications failed:', error);
      throw error;
    }
  }

  async validateToken(fcmToken) {
    if (!this.initialized) {
      throw new Error('Firebase Admin SDK not initialized');
    }

    try {
      // Try to send a dry-run message to validate the token
      const message = {
        token: fcmToken,
        notification: {
          title: 'Test',
          body: 'Test',
        },
        dryRun: true,
      };

      await admin.messaging().send(message);
      return { valid: true };
    } catch (error) {
      console.warn(`⚠️ Invalid FCM token: ${fcmToken.substring(0, 20)}...`);
      return { valid: false, error: error.message };
    }
  }
}

module.exports = FCMService;
```

### 5. Update Email Service Server
Update `email-service/server.js` to include FCM endpoints:

```javascript
const FCMService = require('./services/fcm-service');
const fcmService = new FCMService();

// Test FCM notification endpoint
app.post('/test-fcm', async (req, res) => {
  try {
    const { fcmToken, title, body } = req.body;
    
    if (!fcmToken || !title || !body) {
      return res.status(400).json({ 
        error: 'fcmToken, title, and body are required' 
      });
    }
    
    const notification = {
      title: title,
      body: body,
      channelId: 'test_notifications',
      sound: 'default',
      data: {
        type: 'test',
        timestamp: new Date().toISOString(),
      }
    };
    
    const result = await fcmService.sendNotification(fcmToken, notification);
    
    res.json({ 
      success: true, 
      message: 'Test FCM notification sent successfully',
      messageId: result.messageId
    });
  } catch (error) {
    console.error('❌ Test FCM error:', error);
    res.status(500).json({ 
      error: 'Failed to send test FCM notification',
      details: error.message 
    });
  }
});

// Send appointment notification endpoint
app.post('/send-appointment-notification', async (req, res) => {
  try {
    const { 
      fcmToken, 
      patientName, 
      doctorName, 
      appointmentDate, 
      appointmentTime,
      type // 'booking', 'reminder', 'cancellation'
    } = req.body;
    
    if (!fcmToken || !patientName || !doctorName || !appointmentDate || !type) {
      return res.status(400).json({ 
        error: 'Missing required fields' 
      });
    }
    
    let notification;
    
    switch (type) {
      case 'booking':
        notification = {
          title: '✅ Appointment Confirmed',
          body: `Your appointment with Dr. ${doctorName} is confirmed for ${appointmentDate} at ${appointmentTime}`,
          channelId: 'appointment_notifications',
          sound: 'appointment_notification',
          data: {
            type: 'appointment_booking',
            patientName,
            doctorName,
            appointmentDate,
            appointmentTime,
          }
        };
        break;
        
      case 'reminder':
        notification = {
          title: '⏰ Appointment Reminder',
          body: `Your appointment with Dr. ${doctorName} is in 1 hour`,
          channelId: 'appointment_notifications',
          sound: 'appointment_notification',
          data: {
            type: 'appointment_reminder',
            patientName,
            doctorName,
            appointmentDate,
            appointmentTime,
          }
        };
        break;
        
      case 'cancellation':
        notification = {
          title: '❌ Appointment Cancelled',
          body: `Your appointment with Dr. ${doctorName} has been cancelled`,
          channelId: 'appointment_notifications',
          sound: 'default',
          data: {
            type: 'appointment_cancellation',
            patientName,
            doctorName,
            appointmentDate,
            appointmentTime,
          }
        };
        break;
        
      default:
        return res.status(400).json({ error: 'Invalid notification type' });
    }
    
    const result = await fcmService.sendNotification(fcmToken, notification);
    
    res.json({ 
      success: true, 
      message: `${type} notification sent successfully`,
      messageId: result.messageId
    });
  } catch (error) {
    console.error('❌ Appointment notification error:', error);
    res.status(500).json({ 
      error: 'Failed to send appointment notification',
      details: error.message 
    });
  }
});

// Validate FCM token endpoint
app.post('/validate-fcm-token', async (req, res) => {
  try {
    const { fcmToken } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({ error: 'fcmToken is required' });
    }
    
    const result = await fcmService.validateToken(fcmToken);
    
    res.json({ 
      success: true, 
      valid: result.valid,
      error: result.error || null
    });
  } catch (error) {
    console.error('❌ Token validation error:', error);
    res.status(500).json({ 
      error: 'Failed to validate FCM token',
      details: error.message 
    });
  }
});
```

## 📱 Flutter App Setup

### 1. Update FCM Service
Update `lib/services/notifications/fcm_service.dart` to work with the backend:

```dart
/// Send FCM notification via backend service
static Future<bool> sendNotificationViaBackend({
  required String fcmToken,
  required String title,
  required String body,
  String? type,
  Map<String, dynamic>? data,
}) async {
  try {
    const baseUrl = kDebugMode 
      ? 'http://localhost:3000'
      : 'https://curvia-mail-service.onrender.com';
    
    final response = await http.post(
      Uri.parse('$baseUrl/test-fcm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      }),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      debugPrint('✅ Backend FCM notification sent: ${result['messageId']}');
      return true;
    } else {
      debugPrint('❌ Backend FCM notification failed: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('❌ Backend FCM notification error: $e');
    return false;
  }
}
```

### 2. Create FCM Direct Service
Create `lib/services/notifications/fcm_direct_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Direct FCM service using backend
class FCMDirectService {
  static const String _baseUrl = kDebugMode 
    ? 'http://localhost:3000'
    : 'https://curvia-mail-service.onrender.com';
  
  /// Send test FCM notification
  static Future<bool> sendTestNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/test-fcm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Test FCM notification sent: ${result['messageId']}');
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
  
  /// Send appointment notification
  static Future<bool> sendAppointmentNotification({
    required String fcmToken,
    required String patientName,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
    required String type, // 'booking', 'reminder', 'cancellation'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-appointment-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': fcmToken,
          'patientName': patientName,
          'doctorName': doctorName,
          'appointmentDate': appointmentDate,
          'appointmentTime': appointmentTime,
          'type': type,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Appointment FCM notification sent: ${result['messageId']}');
        return true;
      } else {
        debugPrint('❌ Appointment FCM notification failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Appointment FCM notification error: $e');
      return false;
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
      );
      
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
}
```

## 🎯 Available FCM Endpoints

### Basic FCM Operations

#### 1. Test FCM Notification
```bash
curl -X POST http://localhost:3000/test-fcm \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN",
    "title": "Test Notification",
    "body": "This is a test notification",
    "channelId": "test",
    "sound": "default",
    "data": {"type": "test"}
  }'
```

#### 2. Validate FCM Token
```bash
curl -X POST http://localhost:3000/validate-fcm-token \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN"
  }'
```

#### 3. Send Bulk FCM Notifications
```bash
curl -X POST http://localhost:3000/send-bulk-fcm \
  -H "Content-Type: application/json" \
  -d '{
    "fcmTokens": ["token1", "token2", "token3"],
    "title": "Bulk Notification",
    "body": "This is sent to multiple devices",
    "channelId": "general",
    "sound": "default"
  }'
```

### Integrated Notifications (FCM + Email)

#### 4. Appointment Notifications
```bash
curl -X POST http://localhost:3000/send-appointment-notification \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "patient_123",
    "doctorId": "doctor_456",
    "appointmentId": "appointment_789",
    "type": "booked",
    "appointmentData": {
      "date": "2024-01-20",
      "time": "10:00 AM"
    }
  }'
```

**Types**: `booked`, `confirmed`, `cancelled`, `reminder`

#### 5. Payment Notifications
```bash
curl -X POST http://localhost:3000/send-payment-notification \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "patient_123",
    "doctorId": "doctor_456",
    "paymentId": "payment_101",
    "type": "success",
    "amount": 500,
    "paymentData": {
      "method": "UPI",
      "transactionId": "TXN123456"
    }
  }'
```

**Types**: `success`, `failed`, `refund`

#### 6. Doctor Verification Notifications (FCM + Email)
```bash
curl -X POST http://localhost:3000/send-doctor-verification-with-fcm \
  -H "Content-Type: application/json" \
  -d '{
    "doctorId": "doctor_456",
    "status": "approved",
    "adminId": "admin_789"
  }'
```

**Status**: `approved`, `rejected`

### Legacy Email-Only Endpoints

#### 7. Doctor Verification (Email Only)
```bash
curl -X POST http://localhost:3000/send-doctor-verification \
  -H "Content-Type: application/json" \
  -d '{
    "doctorId": "doctor_456",
    "status": "approved",
    "adminId": "admin_789"
  }'
```

## 🧪 Testing Your FCM Setup

### Automated Test Script
Run the comprehensive test script:

```bash
cd email-service
node test-fcm-integration.js
```

This will test all FCM endpoints and provide a detailed report.

### Manual Testing
Create a test script `email-service/test-fcm.js`:

```javascript
const FCMService = require('./services/fcm-service');

async function testFCM() {
  const fcmService = new FCMService();
  
  // Replace with a real FCM token from your app
  const testToken = 'YOUR_TEST_FCM_TOKEN_HERE';
  
  const notification = {
    title: '🧪 Test Notification',
    body: 'This is a test notification from Curevia backend',
    channelId: 'test_notifications',
    sound: 'default',
    data: {
      type: 'test',
      timestamp: new Date().toISOString(),
    }
  };
  
  try {
    const result = await fcmService.sendNotification(testToken, notification);
    console.log('✅ Test notification sent successfully:', result);
  } catch (error) {
    console.error('❌ Test notification failed:', error);
  }
}

// Run the test
testFCM();
```

### 2. Flutter Test Widget
Add to your debug screen or create a test widget:

```dart
class FCMTestWidget extends StatefulWidget {
  @override
  _FCMTestWidgetState createState() => _FCMTestWidgetState();
}

class _FCMTestWidgetState extends State<FCMTestWidget> {
  String? _fcmToken;
  bool _isLoading = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    final token = await FCMService.instance.fcmToken;
    setState(() {
      _fcmToken = token;
    });
  }

  Future<void> _testFCMNotification() async {
    if (_fcmToken == null) return;
    
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final success = await FCMDirectService.sendTestNotification(
        fcmToken: _fcmToken!,
        title: '🧪 Test from Flutter',
        body: 'This is a test notification sent from Flutter app',
      );
      
      setState(() {
        _result = success ? '✅ Test notification sent successfully!' : '❌ Test notification failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FCM Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FCM Token:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_fcmToken ?? 'Loading...', style: TextStyle(fontSize: 12)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testFCMNotification,
              child: _isLoading 
                ? CircularProgressIndicator() 
                : Text('Send Test Notification'),
            ),
            SizedBox(height: 16),
            if (_result.isNotEmpty)
              Text(_result, style: TextStyle(
                color: _result.startsWith('✅') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              )),
          ],
        ),
      ),
    );
  }
}
```

## 🔧 Deployment Steps

### 1. Local Development
```bash
# Start email service locally
cd email-service
npm start

# Test FCM endpoint
curl -X POST http://localhost:3000/test-fcm \
  -H "Content-Type: application/json" \
  -d '{"fcmToken":"YOUR_TOKEN","title":"Test","body":"Test message"}'
```

### 2. Production Deployment
```bash
# Deploy to your hosting service (Render, Heroku, etc.)
# Make sure to:
# 1. Upload serviceAccountKey.json securely
# 2. Set environment variables
# 3. Test FCM endpoints
```

## 🔒 Security Considerations

### 1. Service Account Key Security
- ✅ **DO**: Store in secure environment variables in production
- ✅ **DO**: Restrict file permissions (600)
- ❌ **DON'T**: Commit to version control
- ❌ **DON'T**: Expose in client-side code

### 2. Environment Variables
```env
# Production environment
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account",...}
# OR
FIREBASE_SERVICE_ACCOUNT_PATH=/secure/path/to/key.json
```

### 3. API Security
- Add authentication to FCM endpoints
- Rate limiting for notification sending
- Input validation and sanitization
- CORS configuration

## 📊 Monitoring & Analytics

### 1. FCM Delivery Tracking
```javascript
// Add to your FCM service
async sendNotificationWithTracking(fcmToken, notification) {
  try {
    const result = await this.sendNotification(fcmToken, notification);
    
    // Log successful delivery
    await this.logNotificationDelivery({
      fcmToken: fcmToken.substring(0, 20) + '...',
      title: notification.title,
      status: 'delivered',
      messageId: result.messageId,
      timestamp: new Date().toISOString(),
    });
    
    return result;
  } catch (error) {
    // Log failed delivery
    await this.logNotificationDelivery({
      fcmToken: fcmToken.substring(0, 20) + '...',
      title: notification.title,
      status: 'failed',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
    
    throw error;
  }
}
```

### 2. Dashboard Metrics
Add to your email service dashboard:
- Total notifications sent
- Delivery success rate
- Failed token count
- Notification types breakdown

## 🚨 Troubleshooting

### Common Issues:

1. **"Firebase Admin SDK not initialized"**
   - Check service account key path
   - Verify JSON format
   - Check file permissions

2. **"Invalid FCM token"**
   - Token expired or invalid
   - App uninstalled
   - Token not properly stored

3. **"Notification not received"**
   - Check app is in foreground/background
   - Verify notification permissions
   - Check notification channels (Android)

4. **"CORS errors"**
   - Configure CORS in email service
   - Check request headers

### Debug Commands:
```bash
# Test service account key
node -e "console.log(require('./serviceAccountKey.json').project_id)"

# Test FCM endpoint
curl -X POST http://localhost:3000/health

# Validate FCM token
curl -X POST http://localhost:3000/validate-fcm-token \
  -H "Content-Type: application/json" \
  -d '{"fcmToken":"YOUR_TOKEN"}'
```

## ✅ Success Checklist

- [ ] Service account key properly placed
- [ ] Firebase Admin SDK initialized
- [ ] FCM service endpoints working
- [ ] Test notifications sending successfully
- [ ] Flutter app receiving notifications
- [ ] Token validation working
- [ ] Error handling implemented
- [ ] Security measures in place
- [ ] Monitoring and logging active
- [ ] Production deployment tested

Your FCM setup is now complete and ready for production use! 🎉