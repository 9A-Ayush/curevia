import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';

class PermissionRequestScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;
  final String userRole;

  const PermissionRequestScreen({
    super.key,
    required this.onPermissionsGranted,
    required this.userRole,
  });

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isRequesting = false;
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  final List<PermissionInfo> _requiredPermissions = [
    PermissionInfo(
      permission: Permission.camera,
      title: 'Camera',
      description: 'Required for video consultations and profile photos',
      icon: Icons.camera_alt,
    ),
    PermissionInfo(
      permission: Permission.microphone,
      title: 'Microphone',
      description: 'Required for video and audio consultations',
      icon: Icons.mic,
    ),
    PermissionInfo(
      permission: Permission.storage,
      title: 'Storage',
      description: 'Required to save medical documents and reports',
      icon: Icons.folder,
    ),
    PermissionInfo(
      permission: Permission.location,
      title: 'Location',
      description: 'Required to find nearby doctors and hospitals',
      icon: Icons.location_on,
    ),
    PermissionInfo(
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Required for appointment reminders and updates',
      icon: Icons.notifications,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permInfo in _requiredPermissions) {
      statuses[permInfo.permission] = await permInfo.permission.status;
    }
    setState(() {
      _permissionStatuses = statuses;
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequesting = true);

    try {
      // Request all permissions at once
      final permissions = _requiredPermissions.map((p) => p.permission).toList();
      final statuses = await permissions.request();

      setState(() {
        _permissionStatuses = statuses;
      });

      // Check if all critical permissions are granted
      final allGranted = _areAllCriticalPermissionsGranted();

      if (allGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All permissions granted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        widget.onPermissionsGranted();
      } else {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  bool _areAllCriticalPermissionsGranted() {
    // Camera and microphone are critical for video calls
    final camera = _permissionStatuses[Permission.camera];
    final microphone = _permissionStatuses[Permission.microphone];
    
    return camera == PermissionStatus.granted && 
           microphone == PermissionStatus.granted;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Some permissions were denied. Camera and Microphone are required for video consultations. '
          'You can grant them later in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPermissionsGranted(); // Continue anyway
            },
            child: const Text('Continue Anyway'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                'Permissions Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'To provide you with the best experience, we need access to the following:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
              ),
              const SizedBox(height: 32),

              // Permission list
              Expanded(
                child: ListView.builder(
                  itemCount: _requiredPermissions.length,
                  itemBuilder: (context, index) {
                    final permInfo = _requiredPermissions[index];
                    final status = _permissionStatuses[permInfo.permission];
                    return _buildPermissionCard(permInfo, status);
                  },
                ),
              ),

              // Bottom buttons
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Grant All Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isRequesting ? null : widget.onPermissionsGranted,
                  child: const Text('Skip for Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionInfo permInfo, PermissionStatus? status) {
    final isGranted = status == PermissionStatus.granted;
    final isDenied = status == PermissionStatus.denied || 
                     status == PermissionStatus.permanentlyDenied;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? AppColors.success
              : isDenied
                  ? AppColors.error
                  : ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      permInfo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (isGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Granted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  permInfo.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                ),
              ],
            ),
          ),
          if (isGranted)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
        ],
      ),
    );
  }
}

class PermissionInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;

  PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
  });
}