import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notifications/role_based_notification_channel_service.dart';
import '../../utils/theme_utils.dart';

/// Screen for managing notification channels and role-based settings
class NotificationChannelManagementScreen extends ConsumerStatefulWidget {
  const NotificationChannelManagementScreen({super.key});

  @override
  ConsumerState<NotificationChannelManagementScreen> createState() => 
      _NotificationChannelManagementScreenState();
}

class _NotificationChannelManagementScreenState 
    extends ConsumerState<NotificationChannelManagementScreen> {
  Map<String, dynamic> _channelInfo = {};
  Map<String, Map<String, int>> _roleStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannelInfo();
  }

  Future<void> _loadChannelInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final channelService = RoleBasedNotificationChannelService.instance;
      
      // Get channel information
      final channelInfo = channelService.getChannelInfo();
      
      // Get statistics for each role
      final patientStats = await channelService.getRoleNotificationStats('patient');
      final doctorStats = await channelService.getRoleNotificationStats('doctor');
      final adminStats = await channelService.getRoleNotificationStats('admin');
      
      setState(() {
        _channelInfo = channelInfo;
        _roleStats = {
          'patient': patientStats,
          'doctor': doctorStats,
          'admin': adminStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading channel info: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Notification Channels',
          style: TextStyle(
            color: ThemeUtils.getTextOnPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ThemeUtils.getTextOnPrimaryColor(context),
            ),
            onPressed: _loadChannelInfo,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: ThemeUtils.getTextOnPrimaryColor(context),
            ),
            color: ThemeUtils.getSurfaceColor(context),
            onSelected: (value) {
              switch (value) {
                case 'test_all_roles':
                  _sendTestNotificationsToAllRoles();
                  break;
                case 'export_settings':
                  _exportChannelSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'test_all_roles',
                child: Row(
                  children: [
                    Icon(Icons.send, color: ThemeUtils.getTextPrimaryColor(context)),
                    const SizedBox(width: 8),
                    Text('Test All Roles', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_settings',
                child: Row(
                  children: [
                    Icon(Icons.download, color: ThemeUtils.getTextPrimaryColor(context)),
                    const SizedBox(width: 8),
                    Text('Export Settings', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ThemeUtils.getPrimaryColor(context),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChannelInfo,
              color: ThemeUtils.getPrimaryColor(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewSection(),
                    const SizedBox(height: 24),
                    _buildRoleChannelsSection(),
                    const SizedBox(height: 24),
                    _buildStatisticsSection(),
                    const SizedBox(height: 24),
                    _buildNotificationTypesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    return Card(
      color: ThemeUtils.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Channel Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Total Roles',
                    _channelInfo['totalRoles']?.toString() ?? '0',
                    Icons.people,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Notification Types',
                    _channelInfo['totalNotificationTypes']?.toString() ?? '0',
                    Icons.notifications,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChannelsSection() {
    final channels = _channelInfo['channels'] as Map<String, dynamic>? ?? {};
    
    return Card(
      color: ThemeUtils.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Role-Based Channels',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...channels.entries.map((entry) => _buildRoleChannelCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChannelCard(String role, dynamic notificationTypes) {
    final types = notificationTypes as List<dynamic>? ?? [];
    final stats = _roleStats[role] ?? {};
    
    Color roleColor;
    IconData roleIcon;
    
    switch (role) {
      case 'patient':
        roleColor = AppColors.info;
        roleIcon = Icons.person;
        break;
      case 'doctor':
        roleColor = AppColors.success;
        roleIcon = Icons.medical_services;
        break;
      case 'admin':
        roleColor = AppColors.warning;
        roleIcon = Icons.admin_panel_settings;
        break;
      default:
        roleColor = AppColors.primary;
        roleIcon = Icons.group;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(roleIcon, color: roleColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                    Text(
                      '${types.length} notification types',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats['total'] ?? 0}',
                  style: TextStyle(
                    color: ThemeUtils.getTextOnPrimaryColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (types.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: types.take(5).map<Widget>((type) {
                final typeStr = type.toString().split('.').last;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: roleColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (types.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${types.length - 5} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Card(
      color: ThemeUtils.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._roleStats.entries.map((entry) => _buildStatsRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String role, Map<String, int> stats) {
    Color roleColor;
    switch (role) {
      case 'patient':
        roleColor = AppColors.info;
        break;
      case 'doctor':
        roleColor = AppColors.success;
        break;
      case 'admin':
        roleColor = AppColors.warning;
        break;
      default:
        roleColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', stats['total'] ?? 0, roleColor),
              ),
              Expanded(
                child: _buildStatItem('Unread', stats['unread'] ?? 0, AppColors.error),
              ),
              Expanded(
                child: _buildStatItem('Read', stats['read'] ?? 0, AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypesSection() {
    return Card(
      color: ThemeUtils.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'All Notification Types',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NotificationType.values.map((type) {
                final typeStr = type.toString().split('.').last;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    typeStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotificationsToAllRoles() async {
    try {
      final channelService = RoleBasedNotificationChannelService.instance;
      
      // Send test notifications to all roles
      await Future.wait([
        channelService.sendRoleBasedNotification(
          type: NotificationType.general,
          title: 'Test Patient Notification',
          body: 'This is a test notification for patients',
          targetRole: 'patient',
        ),
        channelService.sendRoleBasedNotification(
          type: NotificationType.general,
          title: 'Test Doctor Notification',
          body: 'This is a test notification for doctors',
          targetRole: 'doctor',
        ),
        channelService.sendRoleBasedNotification(
          type: NotificationType.general,
          title: 'Test Admin Notification',
          body: 'This is a test notification for admins',
          targetRole: 'admin',
        ),
      ]);
      
      await _loadChannelInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test notifications sent to all roles'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notifications: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _exportChannelSettings() async {
    try {
      final channelService = RoleBasedNotificationChannelService.instance;
      
      // Get preferences for all roles
      final patientPrefs = channelService.getRoleNotificationPreferences('patient');
      final doctorPrefs = channelService.getRoleNotificationPreferences('doctor');
      final adminPrefs = channelService.getRoleNotificationPreferences('admin');
      
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'channelInfo': _channelInfo,
        'rolePreferences': {
          'patient': patientPrefs,
          'doctor': doctorPrefs,
          'admin': adminPrefs,
        },
        'statistics': _roleStats,
      };
      
      // In a real app, you would save this to a file or send to server
      debugPrint('Channel settings exported: $exportData');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Channel settings exported to debug console'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting settings: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}