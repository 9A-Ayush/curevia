import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../services/permissions/app_permissions_service.dart';

/// Screen to request all necessary permissions
class PermissionsRequestScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsRequestScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionsRequestScreen> createState() =>
      _PermissionsRequestScreenState();
}

class _PermissionsRequestScreenState extends State<PermissionsRequestScreen> {
  final Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = false;
  int _androidVersion = 0;
  List<PermissionInfo> _filteredPermissions = [];

  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      permission: Permission.camera,
      title: 'Camera',
      description: 'Take photos for profile and medical documents',
      icon: Icons.camera_alt,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.microphone,
      title: 'Microphone',
      description: 'Enable voice and video calls with doctors',
      icon: Icons.mic,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.photos,
      title: 'Photos & Media',
      description: 'Access photos for profile and medical records',
      icon: Icons.photo_library,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.storage,
      title: 'Storage',
      description: 'Save and access medical documents and PDFs (Android 10 and below)',
      icon: Icons.folder,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.manageExternalStorage,
      title: 'File Management',
      description: 'Download and manage medical documents (Android 11-12)',
      icon: Icons.file_download,
      isRequired: true,
      androidVersionRequired: 30,
    ),
    PermissionInfo(
      permission: Permission.videos,
      title: 'Videos',
      description: 'Access video files for medical records (Android 13+)',
      icon: Icons.video_library,
      isRequired: true,
      androidVersionRequired: 33,
    ),
    PermissionInfo(
      permission: Permission.audio,
      title: 'Audio Files',
      description: 'Access audio files for medical records (Android 13+)',
      icon: Icons.audiotrack,
      isRequired: true,
      androidVersionRequired: 33,
    ),
    PermissionInfo(
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Receive appointment reminders and health alerts',
      icon: Icons.notifications,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.location,
      title: 'Location',
      description: 'Find nearby doctors and clinics',
      icon: Icons.location_on,
      isRequired: false,
    ),
    PermissionInfo(
      permission: Permission.locationWhenInUse,
      title: 'Location (When In Use)',
      description: 'Access location only when using the app',
      icon: Icons.my_location,
      isRequired: false,
    ),
    PermissionInfo(
      permission: Permission.phone,
      title: 'Phone',
      description: 'Make emergency calls to doctors',
      icon: Icons.phone,
      isRequired: false,
    ),
    PermissionInfo(
      permission: Permission.bluetoothConnect,
      title: 'Bluetooth',
      description: 'Connect to health monitoring devices',
      icon: Icons.bluetooth,
      isRequired: false,
      androidVersionRequired: 31,
    ),
    PermissionInfo(
      permission: Permission.bluetoothScan,
      title: 'Bluetooth Scan',
      description: 'Scan for nearby health devices',
      icon: Icons.bluetooth_searching,
      isRequired: false,
      androidVersionRequired: 31,
    ),
    PermissionInfo(
      permission: Permission.activityRecognition,
      title: 'Activity Recognition',
      description: 'Track your fitness and health activities',
      icon: Icons.directions_run,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.sensors,
      title: 'Sensors',
      description: 'Access device sensors for health monitoring',
      icon: Icons.sensors,
      isRequired: true,
    ),
    PermissionInfo(
      permission: Permission.systemAlertWindow,
      title: 'Display Over Apps',
      description: 'Show emergency alerts over other apps',
      icon: Icons.picture_in_picture,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    await _getAndroidVersion();
    _filterPermissionsByPlatform();
    await _checkPermissions();
  }

  Future<void> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _androidVersion = androidInfo.version.sdkInt;
      });
    }
  }

  void _filterPermissionsByPlatform() {
    _filteredPermissions = _permissions.where((permInfo) {
      // Filter out Android version-specific permissions
      if (Platform.isAndroid && permInfo.androidVersionRequired != null) {
        return _androidVersion >= permInfo.androidVersionRequired!;
      }
      
      // Filter out platform-specific permissions
      if (Platform.isIOS) {
        // Some permissions are Android-only
        final androidOnlyPermissions = [
          Permission.manageExternalStorage,
          Permission.systemAlertWindow,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ];
        if (androidOnlyPermissions.contains(permInfo.permission)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Future<void> _checkPermissions() async {
    for (final permInfo in _filteredPermissions) {
      final status = await permInfo.permission.status;
      setState(() {
        _permissionStatuses[permInfo.permission] = status;
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    for (final permInfo in _filteredPermissions) {
      if (_permissionStatuses[permInfo.permission]?.isGranted != true) {
        final status = await permInfo.permission.request();
        setState(() {
          _permissionStatuses[permInfo.permission] = status;
        });
      }
    }

    setState(() => _isLoading = false);

    // Check if all required permissions are granted
    final allRequiredGranted = _filteredPermissions
        .where((p) => p.isRequired)
        .every((p) => _permissionStatuses[p.permission]?.isGranted == true);

    if (allRequiredGranted) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestSinglePermission(PermissionInfo permInfo) async {
    final status = await permInfo.permission.status;

    if (status.isPermanentlyDenied) {
      await AppPermissionsService.showSettingsDialog(
        context: context,
        permissionName: permInfo.title,
      );
      return;
    }

    final newStatus = await permInfo.permission.request();
    setState(() {
      _permissionStatuses[permInfo.permission] = newStatus;
    });
  }

  void _showPermissionInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why We Need These Permissions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Curevia is a comprehensive healthcare app that requires specific permissions to provide you with the best medical experience:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildPermissionInfoItem(
                    Icons.camera_alt,
                    'Camera & Photos',
                    'Take photos of medical documents, prescriptions, and upload profile pictures.',
                  ),
                  _buildPermissionInfoItem(
                    Icons.folder,
                    'Storage & Files',
                    'Save and access medical documents, PDFs, and reports on your device.',
                  ),
                  _buildPermissionInfoItem(
                    Icons.mic,
                    'Microphone',
                    'Enable voice and video calls with doctors for telemedicine consultations.',
                  ),
                  _buildPermissionInfoItem(
                    Icons.notifications,
                    'Notifications',
                    'Receive important reminders for appointments, medication, and health alerts.',
                  ),
                  _buildPermissionInfoItem(
                    Icons.location_on,
                    'Location',
                    'Find nearby doctors, clinics, and pharmacies based on your location.',
                  ),
                  _buildPermissionInfoItem(
                    Icons.bluetooth,
                    'Bluetooth',
                    'Connect to health monitoring devices like blood pressure monitors and fitness trackers.',
                  ),
                  _buildPermissionInfoItem(
                    Icons.directions_run,
                    'Activity & Sensors',
                    'Track your fitness activities and health metrics for better health insights.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: AppColors.info, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Your Privacy Matters',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We only use these permissions for their intended medical purposes. Your data is encrypted and never shared without your consent.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got It'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: ThemeUtils.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRequiredGranted = _filteredPermissions
        .where((p) => p.isRequired)
        .every((p) => _permissionStatuses[p.permission]?.isGranted == true);

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'App Permissions',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We need your permission to provide the best healthcare experience',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (Platform.isAndroid && _androidVersion > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Android ${_androidVersion >= 33 ? '13+' : _androidVersion >= 30 ? '11-12' : '10 and below'} detected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showPermissionInfo,
                    icon: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                    label: Text(
                      'Why do we need these permissions?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Permissions list
            Expanded(
              child: _filteredPermissions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPermissions.length,
                      itemBuilder: (context, index) {
                        final permInfo = _filteredPermissions[index];
                        final status = _permissionStatuses[permInfo.permission];

                        return _buildPermissionCard(permInfo, status);
                      },
                    ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!allRequiredGranted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Required permissions must be granted to continue',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestAllPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              allRequiredGranted ? 'Continue' : 'Grant Permissions',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (allRequiredGranted)
                    TextButton(
                      onPressed: widget.onPermissionsGranted,
                      child: const Text('Skip Optional Permissions'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionInfo permInfo, PermissionStatus? status) {
    final isGranted = status?.isGranted == true;
    final isDenied = status?.isDenied == true;
    final isPermanentlyDenied = status?.isPermanentlyDenied == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGranted
              ? AppColors.success.withOpacity(0.3)
              : ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isGranted
                ? AppColors.success.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            permInfo.icon,
            color: isGranted ? AppColors.success : AppColors.primary,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                permInfo.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (permInfo.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (permInfo.androidVersionRequired != null && Platform.isAndroid)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'API ${permInfo.androidVersionRequired}+',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              permInfo.description,
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isGranted
                      ? Icons.check_circle
                      : isPermanentlyDenied
                          ? Icons.block
                          : Icons.circle_outlined,
                  size: 16,
                  color: isGranted
                      ? AppColors.success
                      : isPermanentlyDenied
                          ? AppColors.error
                          : ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(width: 4),
                Text(
                  isGranted
                      ? 'Granted'
                      : isPermanentlyDenied
                          ? 'Denied - Open Settings'
                          : isDenied
                              ? 'Denied'
                              : 'Not Requested',
                  style: TextStyle(
                    color: isGranted
                        ? AppColors.success
                        : isPermanentlyDenied
                            ? AppColors.error
                            : ThemeUtils.getTextSecondaryColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: !isGranted
            ? IconButton(
                icon: Icon(
                  isPermanentlyDenied ? Icons.settings : Icons.arrow_forward,
                  color: AppColors.primary,
                ),
                onPressed: () => _requestSinglePermission(permInfo),
              )
            : Icon(Icons.check_circle, color: AppColors.success),
      ),
    );
  }
}

class PermissionInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;
  final int? androidVersionRequired;

  const PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.isRequired = false,
    this.androidVersionRequired,
  });
}
