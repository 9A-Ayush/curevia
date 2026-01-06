import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/notification_model.dart';
import 'notification_handler.dart';

/// Firebase Cloud Messaging Service
/// Handles FCM token management, message receiving, and notification display
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _isInitialized = false;

  /// Get the singleton instance
  static FCMService get instance => _instance;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      await _setupMessageHandlers();

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }

    // For Android, request additional permissions
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final notification = NotificationModel.fromJson(data);
        NotificationHandler.handleNotificationTap(notification);
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Save token to SharedPreferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Set up message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessage(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('FCM Token refreshed: $token');
      _saveFCMToken(token);
    });
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    final notification = _createNotificationFromMessage(message);
    await showLocalNotification(notification);
    
    // Handle the notification data
    NotificationHandler.handleNotificationReceived(notification);
  }

  /// Handle background messages (app not terminated)
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.messageId}');
    
    final notification = _createNotificationFromMessage(message);
    NotificationHandler.handleNotificationTap(notification);
  }

  /// Handle terminated messages
  Future<void> _handleTerminatedMessage(RemoteMessage message) async {
    debugPrint('Received terminated message: ${message.messageId}');
    
    final notification = _createNotificationFromMessage(message);
    NotificationHandler.handleNotificationTap(notification);
  }

  /// Create notification model from FCM message
  NotificationModel _createNotificationFromMessage(RemoteMessage message) {
    final data = message.data;
    final notificationType = NotificationType.fromString(data['type'] ?? 'general');
    
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      type: notificationType,
      data: data,
      timestamp: DateTime.now(),
      imageUrl: message.notification?.android?.imageUrl ?? data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }

  /// Show local notification for foreground messages
  Future<void> showLocalNotification(NotificationModel notification) async {
    final androidDetails = AndroidNotificationDetails(
      notification.type.channelId,
      notification.type.channelName,
      channelDescription: notification.type.channelDescription,
      importance: notification.type.isHighPriority ? Importance.high : Importance.defaultImportance,
      priority: notification.type.isHighPriority ? Priority.high : Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound(notification.type.androidSoundFile),
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification', // Use custom notification icon without blue circle
      // Force sound to play
      audioAttributesUsage: AudioAttributesUsage.notification,
      color: const Color(0xFF0175C2), // Curevia brand color
      colorized: true,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: notification.type.iosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(notification.toJson()),
    );
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    // Create channels for each notification type
    for (final type in NotificationType.values) {
      final channel = AndroidNotificationChannel(
        type.channelId,
        type.channelName,
        description: type.channelDescription,
        importance: type.isHighPriority ? Importance.high : Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound(type.androidSoundFile),
        enableVibration: true,
        playSound: true,
      );

      await androidImplementation.createNotificationChannel(channel);
      debugPrint('Created notification channel: ${type.channelId}');
    }
  }

  /// Save FCM token to SharedPreferences
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Get saved FCM token from SharedPreferences
  Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('Error getting saved FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Send FCM token to server
  Future<void> sendTokenToServer(String userId, String userType) async {
    if (_fcmToken == null) return;

    try {
      // TODO: Implement API call to send token to your server
      // This should include userId, userType (patient/doctor/admin), and the FCM token
      debugPrint('Sending FCM token to server for user: $userId, type: $userType');
      
      // Example implementation:
      // await ApiService.sendFCMToken(userId, userType, _fcmToken!);
    } catch (e) {
      debugPrint('Error sending FCM token to server: $e');
    }
  }

  /// Clear FCM token (for logout)
  Future<void> clearToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      
      debugPrint('FCM token cleared');
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }

  /// Schedule a local notification (for appointment reminders)
  Future<void> scheduleNotification({
    required NotificationModel notification,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      notification.type.channelId,
      notification.type.channelName,
      channelDescription: notification.type.channelDescription,
      importance: notification.type.isHighPriority ? Importance.high : Importance.defaultImportance,
      priority: notification.type.isHighPriority ? Priority.high : Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound(notification.type.androidSoundFile),
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification', // Use custom notification icon without blue circle
      // Force sound to play
      audioAttributesUsage: AudioAttributesUsage.notification,
      color: const Color(0xFF0175C2), // Curevia brand color
      colorized: true,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: notification.type.iosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      payload: jsonEncode(notification.toJson()),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('Scheduled notification for: $scheduledTime');
  }

  /// Cancel a scheduled notification
  Future<void> cancelScheduledNotification(String notificationId) async {
    await _localNotifications.cancel(notificationId.hashCode);
    debugPrint('Cancelled scheduled notification: $notificationId');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  
  // Handle background message processing here
  // Note: This runs in a separate isolate, so you can't access UI or most plugins
  
  // You can save the notification to local storage or perform other background tasks
}