import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isInitializing = false;

  /// Get the singleton instance
  static FCMService get instance => _instance;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

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
      _isInitializing = false;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      _isInitializing = false;
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
      
      // TODO: Send updated token to backend
      _updateTokenOnServer(token);
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
      importance: notification.type.isHighPriority ? Importance.max : Importance.high,
      priority: notification.type.isHighPriority ? Priority.max : Priority.high,
      sound: RawResourceAndroidNotificationSound(notification.type.androidSoundFile),
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
      // Critical: Set audio attributes to ensure sound plays in all states
      audioAttributesUsage: AudioAttributesUsage.notification,
      color: const Color(0xFF0175C2),
      colorized: true,
      // Additional settings to ensure notification is visible and audible
      visibility: NotificationVisibility.public,
      channelShowBadge: true,
      // Ensure notification shows on lock screen
      fullScreenIntent: notification.type.isHighPriority,
      // Set category for better system handling
      category: AndroidNotificationCategory.event,
      // Ticker text for accessibility
      ticker: notification.title,
      // Auto-cancel when tapped
      autoCancel: true,
      // Show when screen is on
      onlyAlertOnce: false,
      // Ensure sound plays even if notification is updated
      tag: notification.id,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: notification.type.iosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // iOS specific settings
      interruptionLevel: notification.type.isHighPriority 
          ? InterruptionLevel.timeSensitive 
          : InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(notification.toJson()),
      );
      debugPrint('✅ Notification shown: ${notification.title}');
      debugPrint('   Channel: ${notification.type.channelId}');
      debugPrint('   Sound: ${notification.type.androidSoundFile}');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
      rethrow;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    // Delete existing channels first to ensure fresh configuration
    // This prevents issues with channels that were created without sound
    try {
      for (final type in NotificationType.values) {
        // Note: Android doesn't provide a direct way to delete channels programmatically
        // Channels persist until the app is uninstalled or user manually deletes them
        // We'll create them with proper settings to override any issues
      }
    } catch (e) {
      debugPrint('Note: Could not clear existing channels: $e');
    }

    // Create channels for each notification type with proper sound configuration
    for (final type in NotificationType.values) {
      final channel = AndroidNotificationChannel(
        type.channelId,
        type.channelName,
        description: type.channelDescription,
        importance: type.isHighPriority ? Importance.max : Importance.high,
        sound: RawResourceAndroidNotificationSound(type.androidSoundFile),
        enableVibration: true,
        playSound: true,
        // Critical: Set audio attributes to ensure sound plays
        audioAttributesUsage: AudioAttributesUsage.notification,
        enableLights: true,
        ledColor: const Color(0xFF0175C2),
      );

      await androidImplementation.createNotificationChannel(channel);
      debugPrint('✅ Created notification channel: ${type.channelId} with sound: ${type.androidSoundFile}');
    }

    // Verify channels were created successfully
    await _verifyNotificationChannels(androidImplementation);
  }

  /// Verify that notification channels are properly configured
  Future<void> _verifyNotificationChannels(AndroidFlutterLocalNotificationsPlugin androidImplementation) async {
    try {
      // Get all notification channels
      final channels = await androidImplementation.getNotificationChannels();
      
      if (channels == null || channels.isEmpty) {
        debugPrint('⚠️ Warning: No notification channels found after creation');
        return;
      }

      debugPrint('📋 Notification Channels Status:');
      for (final channel in channels) {
        debugPrint('  - ${channel.id}: ${channel.name}');
        debugPrint('    Importance: ${channel.importance}');
        debugPrint('    Sound: ${channel.sound?.sound ?? "default"}');
        debugPrint('    Vibration: ${channel.enableVibration}');
        debugPrint('    Play Sound: ${channel.playSound}');
      }
    } catch (e) {
      debugPrint('Error verifying notification channels: $e');
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

  /// Update FCM token on server
  Future<void> _updateTokenOnServer(String token) async {
    try {
      // Get current user ID from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user, skipping token update');
        return;
      }
      
      // Update token in Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
      
      debugPrint('✅ FCM token updated on server for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error updating FCM token on server: $e');
      // Don't throw error - token refresh should not fail the app
    }
  }

  /// Get saved FCM token from SharedPreferences
  Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      if (savedToken != null) {
        debugPrint('Retrieved saved FCM token: ${savedToken.substring(0, 20)}...');
        return savedToken;
      }
      
      // If no saved token, try to get a fresh one
      debugPrint('No saved FCM token found, attempting to get fresh token...');
      final freshToken = await _firebaseMessaging.getToken();
      if (freshToken != null) {
        await prefs.setString('fcm_token', freshToken);
        debugPrint('Fresh FCM token obtained and saved: ${freshToken.substring(0, 20)}...');
        _fcmToken = freshToken;
        return freshToken;
      }
      
      debugPrint('Unable to get FCM token - this might be due to:');
      debugPrint('• Google Play Services not available or outdated');
      debugPrint('• Device not connected to internet');
      debugPrint('• Firebase configuration issues');
      debugPrint('• App permissions not granted');
      
      return null;
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
      importance: notification.type.isHighPriority ? Importance.max : Importance.high,
      priority: notification.type.isHighPriority ? Priority.max : Priority.high,
      sound: RawResourceAndroidNotificationSound(notification.type.androidSoundFile),
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
      // Critical: Set audio attributes to ensure sound plays in all states
      audioAttributesUsage: AudioAttributesUsage.notification,
      color: const Color(0xFF0175C2),
      colorized: true,
      // Additional settings for scheduled notifications
      visibility: NotificationVisibility.public,
      channelShowBadge: true,
      fullScreenIntent: notification.type.isHighPriority,
      category: AndroidNotificationCategory.reminder,
      ticker: notification.title,
      autoCancel: true,
      onlyAlertOnce: false,
      tag: notification.id,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: notification.type.iosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: notification.type.isHighPriority 
          ? InterruptionLevel.timeSensitive 
          : InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
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

      debugPrint('✅ Scheduled notification for: $scheduledTime');
      debugPrint('   Channel: ${notification.type.channelId}');
      debugPrint('   Sound: ${notification.type.androidSoundFile}');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      rethrow;
    }
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