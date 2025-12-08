import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive permission service for the app
class AppPermissionsService {
  /// Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final permissions = await Future.wait([
      Permission.camera.status,
      Permission.microphone.status,
      Permission.photos.status,
      Permission.notification.status,
      Permission.location.status,
    ]);

    return permissions.every((status) => status.isGranted);
  }

  /// Request all essential permissions at once
  static Future<Map<Permission, PermissionStatus>> requestEssentialPermissions() async {
    return await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.notification,
      Permission.location,
    ].request();
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Request photo/gallery permission
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Request storage permission (for older Android versions)
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request phone call permission
  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Request bluetooth permission
  static Future<bool> requestBluetoothPermission() async {
    final status = await Permission.bluetooth.request();
    return status.isGranted;
  }

  /// Request nearby devices permission (Android 12+)
  static Future<bool> requestNearbyDevicesPermission() async {
    final status = await Permission.bluetoothConnect.request();
    return status.isGranted;
  }

  /// Request activity recognition permission (for fitness tracking)
  static Future<bool> requestActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Request sensors permission (for fitness tracking)
  static Future<bool> requestSensorsPermission() async {
    final status = await Permission.sensors.request();
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Show permission rationale dialog
  static Future<bool?> showPermissionRationale({
    required BuildContext context,
    required String title,
    required String message,
    required String permissionName,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  /// Show settings dialog when permission is permanently denied
  static Future<void> showSettingsDialog({
    required BuildContext context,
    required String permissionName,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permissionName permission is required for this feature. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Request permission with rationale
  static Future<bool> requestPermissionWithRationale({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String message,
    required String permissionName,
  }) async {
    // Check current status
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await showSettingsDialog(
        context: context,
        permissionName: permissionName,
      );
      return false;
    }

    // Show rationale
    final shouldRequest = await showPermissionRationale(
      context: context,
      title: title,
      message: message,
      permissionName: permissionName,
    );

    if (shouldRequest != true) {
      return false;
    }

    // Request permission
    final newStatus = await permission.request();

    if (newStatus.isPermanentlyDenied) {
      await showSettingsDialog(
        context: context,
        permissionName: permissionName,
      );
      return false;
    }

    return newStatus.isGranted;
  }

  /// Get permission status text
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  /// Get permission icon
  static IconData getPermissionIcon(Permission permission) {
    if (permission == Permission.camera) {
      return Icons.camera_alt;
    } else if (permission == Permission.microphone) {
      return Icons.mic;
    } else if (permission == Permission.photos) {
      return Icons.photo_library;
    } else if (permission == Permission.notification) {
      return Icons.notifications;
    } else if (permission == Permission.location) {
      return Icons.location_on;
    } else if (permission == Permission.phone) {
      return Icons.phone;
    } else if (permission == Permission.bluetooth) {
      return Icons.bluetooth;
    } else if (permission == Permission.activityRecognition) {
      return Icons.directions_run;
    } else if (permission == Permission.sensors) {
      return Icons.sensors;
    }
    return Icons.security;
  }
}
