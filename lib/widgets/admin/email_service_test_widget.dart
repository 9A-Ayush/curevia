import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/email_service_diagnostic.dart';
import '../../services/email_service.dart';

/// Widget for testing email service functionality in admin screens
class EmailServiceTestWidget extends StatefulWidget {
  const EmailServiceTestWidget({super.key});

  @override
  State<EmailServiceTestWidget> createState() => _EmailServiceTestWidgetState();
}

class _EmailServiceTestWidgetState extends State<EmailServiceTestWidget> {
  bool _isLoading = false;
  String _status = 'Ready to test';
  Map<String, dynamic>? _lastResults;

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
                  Icons.email_outlined,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Email Service Testing',
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
            
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Quick Check',
                  Icons.speed,
                  _runQuickCheck,
                  AppColors.info,
                ),
                _buildTestButton(
                  'Full Diagnostics',
                  Icons.analytics,
                  _runFullDiagnostics,
                  AppColors.primary,
                ),
                _buildTestButton(
                  'Test Approval Email',
                  Icons.check_circle,
                  () => _testVerificationEmail('approved'),
                  AppColors.success,
                ),
                _buildTestButton(
                  'Test Rejection Email',
                  Icons.cancel,
                  () => _testVerificationEmail('rejected'),
                  AppColors.error,
                ),
              ],
            ),
            
            // Results display
            if (_lastResults != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Last Test Results:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildResultsDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
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

  Widget _buildResultsDisplay() {
    final summary = _lastResults?['summary'] as Map<String, dynamic>?;
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Status: ${summary['overall']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: summary['overall'].toString().contains('✅') 
                  ? AppColors.success 
                  : AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.entries
              .where((e) => e.key != 'overall')
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${e.key}:',
                            style: TextStyle(
                              color: ThemeUtils.getTextSecondaryColor(context),
                            ),
                          ),
                        ),
                        Text(
                          e.value.toString(),
                          style: TextStyle(
                            color: e.value.toString().contains('✅')
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('✅') || _status.contains('success')) {
      return AppColors.success;
    } else if (_status.contains('❌') || _status.contains('error') || _status.contains('failed')) {
      return AppColors.error;
    } else if (_status.contains('⚠️') || _status.contains('warning')) {
      return AppColors.warning;
    } else {
      return AppColors.info;
    }
  }

  IconData _getStatusIcon() {
    if (_status.contains('✅') || _status.contains('success')) {
      return Icons.check_circle;
    } else if (_status.contains('❌') || _status.contains('error') || _status.contains('failed')) {
      return Icons.error;
    } else if (_status.contains('⚠️') || _status.contains('warning')) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  Future<void> _runQuickCheck() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking email service...';
    });

    try {
      final isReachable = await EmailServiceDiagnostic.isEmailServiceReachable();
      final serviceStatus = await EmailServiceDiagnostic.getEmailServiceStatus();
      
      setState(() {
        _status = isReachable 
            ? '✅ Email service is reachable ($serviceStatus)'
            : '❌ Email service is unreachable';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Quick check failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runFullDiagnostics() async {
    setState(() {
      _isLoading = true;
      _status = 'Running full diagnostics...';
    });

    try {
      final results = await EmailServiceDiagnostic.runDiagnostics();
      final summary = results['summary'] as Map<String, dynamic>;
      
      setState(() {
        _lastResults = results;
        _status = summary['overall'].toString();
      });
    } catch (e) {
      setState(() {
        _status = '❌ Diagnostics failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testVerificationEmail(String status) async {
    setState(() {
      _isLoading = true;
      _status = 'Testing $status email...';
    });

    try {
      final success = await EmailServiceDiagnostic.testDoctorVerificationEmail(
        doctorId: 'test-doctor-${DateTime.now().millisecondsSinceEpoch}',
        status: status,
      );
      
      setState(() {
        _status = success 
            ? '✅ $status email test successful'
            : '❌ $status email test failed';
      });
    } catch (e) {
      setState(() {
        _status = '❌ $status email test error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}