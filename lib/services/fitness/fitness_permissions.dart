import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:health/health.dart'; // Temporarily disabled due to compatibility issues

/// Fitness permissions management
class FitnessPermissions {
  /// Check if all required permissions are granted
  static Future<bool> arePermissionsGranted() async {
    try {
      final activityRecognition = await Permission.activityRecognition.status;
      final sensors = await Permission.sensors.status;

      return activityRecognition.isGranted && sensors.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request all fitness permissions with user-friendly explanations
  static Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      // Show permission explanation dialog
      final shouldProceed = await _showPermissionExplanationDialog(context);
      if (!shouldProceed) return false;

      // Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();

      // Request sensors permission
      final sensorsStatus = await Permission.sensors.request();

      // Request health permissions (simplified - health plugin disabled)
      final healthGranted = await _requestHealthPermissions();

      final allGranted =
          activityStatus.isGranted && sensorsStatus.isGranted && healthGranted;

      if (!allGranted && context.mounted) {
        await _showPermissionDeniedDialog(context);
      }

      return allGranted;
    } catch (e) {
      return false;
    }
  }

  /// Show permission explanation dialog
  static Future<bool> _showPermissionExplanationDialog(
    BuildContext context,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Fitness Tracking Permissions'),
                ],
              ),
              content: const SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To provide accurate fitness tracking, we need access to:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 16),
                    _PermissionItem(
                      icon: Icons.directions_walk,
                      title: 'Physical Activity',
                      description:
                          'Track your steps, distance, and movement patterns',
                    ),
                    SizedBox(height: 12),
                    _PermissionItem(
                      icon: Icons.sensors,
                      title: 'Device Sensors',
                      description:
                          'Access accelerometer and gyroscope for activity detection',
                    ),
                    SizedBox(height: 12),
                    _PermissionItem(
                      icon: Icons.favorite,
                      title: 'Health Data',
                      description:
                          'Read and write fitness data like steps, calories, and workouts',
                    ),
                    SizedBox(height: 16),
                    Text(
                      '🔒 Your privacy is important to us. All data stays on your device and is never shared without your consent.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant Permissions'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show permission denied dialog
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Permissions Required'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Some permissions were not granted. The fitness tracker may not work properly.',
              ),
              SizedBox(height: 16),
              Text(
                'You can enable permissions later in:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Settings > Apps > Curevia > Permissions'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Request health permissions (simplified - health plugin disabled)
  static Future<bool> _requestHealthPermissions() async {
    try {
      // Health plugin temporarily disabled due to compatibility issues
      // Return true to allow basic fitness tracking with pedometer and sensors
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get permission status details
  static Future<Map<String, PermissionStatus>> getPermissionStatuses() async {
    return {
      'activityRecognition': await Permission.activityRecognition.status,
      'sensors': await Permission.sensors.status,
    };
  }

  /// Show permission settings dialog
  static Future<void> showPermissionSettings(BuildContext context) async {
    final statuses = await getPermissionStatuses();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PermissionStatusItem(
                title: 'Physical Activity',
                status: statuses['activityRecognition']!,
              ),
              const SizedBox(height: 8),
              _PermissionStatusItem(
                title: 'Device Sensors',
                status: statuses['sensors']!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (statuses.values.any((status) => !status.isGranted))
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }
}

/// Widget for displaying permission items
class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying permission status
class _PermissionStatusItem extends StatelessWidget {
  final String title;
  final PermissionStatus status;

  const _PermissionStatusItem({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final isGranted = status.isGranted;

    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: isGranted ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(
          isGranted ? 'Granted' : 'Denied',
          style: TextStyle(
            color: isGranted ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
