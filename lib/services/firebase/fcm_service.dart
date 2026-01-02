import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import '../navigation_service.dart';

/// Firebase Cloud Messaging service for push notifications
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String? _fcmToken;

  /// Initialize FCM service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for iOS
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('FCM: User granted provisional permission');
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        // TODO: Update token in Firestore
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Appointment channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'appointments',
          'Appointments',
          description: 'Notifications for appointments and consultations',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Medication channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'medications',
          'Medications',
          description: 'Medication reminders',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Health tips channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'health_tips',
          'Health Tips',
          description: 'Daily health tips and wellness advice',
          importance: Importance.defaultImportance,
        ),
      );

      // General channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'general',
          'General',
          description: 'General notifications',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(message);

    // Save to Firestore if userId is available
    final userId = message.data['userId'];
    if (userId != null) {
      await NotificationService.createNotification(
        userId: userId,
        title: message.notification?.title ?? 'Notification',
        message: message.notification?.body ?? '',
        type: message.data['type'] ?? 'general',
        data: message.data,
      );
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? 'general';
    final channelId = _getChannelId(type);

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Get channel ID based on notification type
  static String _getChannelId(String type) {
    switch (type) {
      case 'appointment':
        return 'appointments';
      case 'medication':
        return 'medications';
      case 'health_tip':
        return 'health_tips';
      default:
        return 'general';
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final data = message.data;

    // Navigate based on notification type
    switch (type) {
      case 'appointment':
        // Navigate to appointment management screen
        final appointmentId = data['appointmentId'];
        if (appointmentId != null) {
          NavigationService.navigateTo('/appointments', arguments: appointmentId);
        } else {
          NavigationService.navigateTo('/appointments');
        }
        break;
        
      case 'medication':
        // Navigate to medication/health screen
        NavigationService.navigateTo('/health');
        break;
        
      case 'medical':
        // Navigate to medical records
        NavigationService.navigateTo('/medical-records');
        break;
        
      case 'health_tip':
        // Navigate to health tips
        NavigationService.navigateTo('/health-tips');
        break;
        
      case 'consultation':
        // Navigate to consultations
        NavigationService.navigateTo('/consultations');
        break;
        
      default:
        // Navigate to notifications screen
        NavigationService.navigateTo('/notifications');
    }
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload == null) {
      NavigationService.navigateTo('/notifications');
      return;
    }

    try {
      // Parse payload as string representation of map
      // Format: {key1: value1, key2: value2}
      final payload = response.payload!;
      
      // Simple parsing for notification type
      if (payload.contains('appointment')) {
        NavigationService.navigateTo('/appointments');
      } else if (payload.contains('medication')) {
        NavigationService.navigateTo('/health');
      } else if (payload.contains('medical')) {
        NavigationService.navigateTo('/medical-records');
      } else {
        NavigationService.navigateTo('/notifications');
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
      NavigationService.navigateTo('/notifications');
    }
  }

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Save FCM token to Firestore
  static Future<void> saveFCMToken(String userId) async {
    if (_fcmToken == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Schedule local notification (requires timezone package)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Note: For scheduled notifications, you need to add timezone package
    // and use TZDateTime instead of DateTime
    // For now, we'll show immediate notification
    const androidDetails = AndroidNotificationDetails(
      'medications',
      'Medications',
      channelDescription: 'Medication reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show immediate notification
    // TODO: Implement proper scheduled notifications with timezone package
    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancel scheduled notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  // Handle background message
}
