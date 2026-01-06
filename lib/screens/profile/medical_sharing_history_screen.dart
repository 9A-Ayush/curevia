import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/medical_report_sharing_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_utils.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common/custom_button.dart';

class MedicalSharingHistoryScreen extends ConsumerStatefulWidget {
  const MedicalSharingHistoryScreen({super.key});

  @override
  ConsumerState<MedicalSharingHistoryScreen> createState() =>
      _MedicalSharingHistoryScreenState();
}

class _MedicalSharingHistoryScreenState
    extends ConsumerState<MedicalSharingHistoryScreen> {
  List<Map<String, dynamic>> _sharingHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSharingHistory();
  }

  Future<void> _loadSharingHistory() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        final history = await MedicalReportSharingService
            .getPatientSharingHistory(user.uid);
        setState(() {
          _sharingHistory = history;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load sharing history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeSharing(String sharingId) async {
    final user = ref.read(authProvider).userModel;
    if (user == null) return;

    final success = await MedicalReportSharingService.revokeSharing(
      sharingId,
      user.uid,
    );

    if (success) {
      _showSuccessSnackBar('Sharing access revoked successfully');
      _loadSharingHistory(); // Refresh the list
    } else {
      _showErrorSnackBar('Failed to revoke sharing access');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Sharing History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sharingHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSharingHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sharingHistory.length,
                    itemBuilder: (context, index) {
                      final sharing = _sharingHistory[index];
                      return _buildSharingItem(sharing);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share_outlined,
              size: 60,
              color: ThemeUtils.getPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Sharing History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t shared any medical reports with doctors yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Go Back',
            onPressed: () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSharingItem(Map<String, dynamic> sharing) {
    final doctorName = sharing['doctorName'] ?? 'Unknown Doctor';
    final reportCount = (sharing['sharedReportIds'] as List?)?.length ?? 0;
    final sharedAt = sharing['sharedAt']?.toDate() ?? DateTime.now();
    final expiresAt = sharing['expiresAt']?.toDate();
    final isActive = sharing['isActive'] ?? false;
    final sharingStatus = sharing['sharingStatus'] ?? 'unknown';
    final viewedByDoctor = sharing['viewedByDoctor'] ?? false;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (sharingStatus) {
      case 'active':
        statusColor = AppColors.success;
        statusText = 'Active';
        statusIcon = Icons.check_circle;
        break;
      case 'expired':
        statusColor = Colors.orange;
        statusText = 'Expired';
        statusIcon = Icons.schedule;
        break;
      case 'revoked':
        statusColor = AppColors.error;
        statusText = 'Revoked';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      Text(
                        '$reportCount report${reportCount != 1 ? 's' : ''} shared',
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Shared: ${_formatDate(sharedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),

            if (expiresAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expires: ${_formatDate(expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ],

            if (viewedByDoctor) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Viewed by doctor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            // Message if available
            if (sharing['message'] != null && sharing['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSurfaceVariantColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sharing['message'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (isActive && sharingStatus == 'active') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSharingDetails(sharing),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmRevokeSharing(sharing['id']),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Revoke'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSharingDetails(Map<String, dynamic> sharing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sharing Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Doctor', sharing['doctorName'] ?? 'Unknown'),
              _buildDetailRow('Reports Shared', '${(sharing['sharedReportIds'] as List?)?.length ?? 0}'),
              _buildDetailRow('Allergies Shared', '${(sharing['sharedAllergies'] as List?)?.length ?? 0}'),
              _buildDetailRow('Status', sharing['sharingStatus'] ?? 'Unknown'),
              _buildDetailRow('Shared Date', _formatDate(sharing['sharedAt']?.toDate() ?? DateTime.now())),
              if (sharing['expiresAt'] != null)
                _buildDetailRow('Expires', _formatDate(sharing['expiresAt'].toDate())),
              _buildDetailRow('Viewed by Doctor', sharing['viewedByDoctor'] ? 'Yes' : 'No'),
              if (sharing['viewedAt'] != null)
                _buildDetailRow('Viewed Date', _formatDate(sharing['viewedAt'].toDate())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeSharing(String sharingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Sharing'),
        content: const Text(
          'Are you sure you want to revoke this sharing? The doctor will no longer be able to access your medical reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _revokeSharing(sharingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}