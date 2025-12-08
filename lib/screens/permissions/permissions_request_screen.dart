import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
      permission: Permission.phone,
      title: 'Phone',
      description: 'Make emergency calls to doctors',
      icon: Icons.phone,
      isRequired: false,
    ),
    PermissionInfo(
      permission: Permission.bluetoothConnect,
      title: 'Nearby Devices',
      description: 'Connect to health monitoring devices',
      icon: Icons.bluetooth,
      isRequired: false,
    ),
    PermissionInfo(
      permission: Permission.activityRecognition,
      title: 'Activity Recognition',
      description: 'Track your fitness and health activities',
      icon: Icons.directions_run,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    for (final permInfo in _permissions) {
      final status = await permInfo.permission.status;
      setState(() {
        _permissionStatuses[permInfo.permission] = status;
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    for (final permInfo in _permissions) {
      if (_permissionStatuses[permInfo.permission]?.isGranted != true) {
        final status = await permInfo.permission.request();
        setState(() {
          _permissionStatuses[permInfo.permission] = status;
        });
      }
    }

    setState(() => _isLoading = false);

    // Check if all required permissions are granted
    final allRequiredGranted = _permissions
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

  @override
  Widget build(BuildContext context) {
    final allRequiredGranted = _permissions
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
                    'We need your permission to provide the best experience',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Permissions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final permInfo = _permissions[index];
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
            Text(
              permInfo.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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

  PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.isRequired = false,
  });
}
