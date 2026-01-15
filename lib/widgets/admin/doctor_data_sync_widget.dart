import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/doctor_data_sync_helper.dart';

/// Widget for testing and fixing doctor data issues in admin screens
class DoctorDataSyncWidget extends StatefulWidget {
  const DoctorDataSyncWidget({super.key});

  @override
  State<DoctorDataSyncWidget> createState() => _DoctorDataSyncWidgetState();
}

class _DoctorDataSyncWidgetState extends State<DoctorDataSyncWidget> {
  bool _isLoading = false;
  String _status = 'Ready to sync doctor data';
  Map<String, dynamic>? _lastSummary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: ThemeUtils.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Doctor Data Sync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_getStatusColor()),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  'Check Summary',
                  Icons.analytics,
                  _getSummary,
                  AppColors.info,
                ),
                _buildActionButton(
                  'Sync All Data',
                  Icons.sync,
                  _syncAllData,
                  AppColors.primary,
                ),
                _buildActionButton(
                  'Initialize Missing',
                  Icons.add_circle,
                  _initializeMissing,
                  AppColors.success,
                ),
              ],
            ),
            
            // Summary display
            if (_lastSummary != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Data Summary:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildSummaryDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSummaryDisplay() {
    if (_lastSummary?['error'] != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Text(
          'Error: ${_lastSummary!['error']}',
          style: TextStyle(color: AppColors.error),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Total Doctors', _lastSummary!['totalDoctors']?.toString() ?? '0'),
          _buildSummaryRow('Complete Data', _lastSummary!['complete']?.toString() ?? '0'),
          _buildSummaryRow('Missing Name', _lastSummary!['missingName']?.toString() ?? '0'),
          _buildSummaryRow('Missing Email', _lastSummary!['missingEmail']?.toString() ?? '0'),
          _buildSummaryRow('Missing Phone', _lastSummary!['missingPhone']?.toString() ?? '0'),
          
          if (_lastSummary!['issues'] != null && (_lastSummary!['issues'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Doctors with Issues:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 4),
            ...(_lastSummary!['issues'] as List).take(5).map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• ${issue['doctorId']}: Missing ${(issue['missing'] as List).join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
            )).toList(),
            if ((_lastSummary!['issues'] as List).length > 5)
              Text(
                '... and ${(_lastSummary!['issues'] as List).length - 5} more',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('✅') || _status.contains('success') || _status.contains('complete')) {
      return AppColors.success;
    } else if (_status.contains('❌') || _status.contains('error') || _status.contains('failed')) {
      return AppColors.error;
    } else if (_status.contains('⚠️') || _status.contains('warning') || _status.contains('issues')) {
      return AppColors.warning;
    } else {
      return AppColors.info;
    }
  }

  IconData _getStatusIcon() {
    if (_status.contains('✅') || _status.contains('success') || _status.contains('complete')) {
      return Icons.check_circle;
    } else if (_status.contains('❌') || _status.contains('error') || _status.contains('failed')) {
      return Icons.error;
    } else if (_status.contains('⚠️') || _status.contains('warning') || _status.contains('issues')) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  Future<void> _getSummary() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting data summary...';
    });

    try {
      final summary = await DoctorDataSyncHelper.getDoctorDataSummary();
      
      setState(() {
        _lastSummary = summary;
        
        if (summary['error'] != null) {
          _status = '❌ Error getting summary: ${summary['error']}';
        } else {
          final total = summary['totalDoctors'] ?? 0;
          final complete = summary['complete'] ?? 0;
          final issues = total - complete;
          
          if (issues == 0) {
            _status = '✅ All $total doctors have complete data';
          } else {
            _status = '⚠️ $issues of $total doctors have data issues';
          }
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error getting summary: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAllData() async {
    setState(() {
      _isLoading = true;
      _status = 'Syncing all doctor data...';
    });

    try {
      await DoctorDataSyncHelper.syncAllDoctorData();
      
      // Get updated summary
      final summary = await DoctorDataSyncHelper.getDoctorDataSummary();
      
      setState(() {
        _lastSummary = summary;
        _status = '✅ Data sync completed successfully';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Sync failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeMissing() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing missing doctor documents...';
    });

    try {
      await DoctorDataSyncHelper.initializeMissingDoctorDocuments();
      
      // Get updated summary
      final summary = await DoctorDataSyncHelper.getDoctorDataSummary();
      
      setState(() {
        _lastSummary = summary;
        _status = '✅ Missing documents initialized successfully';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Initialization failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}