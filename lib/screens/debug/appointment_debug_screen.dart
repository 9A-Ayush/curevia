import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/appointment_diagnostic.dart';

/// Debug screen for appointment data issues
class AppointmentDebugScreen extends StatefulWidget {
  const AppointmentDebugScreen({super.key});

  @override
  State<AppointmentDebugScreen> createState() => _AppointmentDebugScreenState();
}

class _AppointmentDebugScreenState extends State<AppointmentDebugScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosticResults;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Debug'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Data Diagnostic',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This tool helps diagnose and fix appointment data issues, particularly missing or invalid doctorId values.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runDiagnostic,
                  icon: const Icon(Icons.search),
                  label: const Text('Run Diagnostic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runDiagnosticAndFix,
                  icon: const Icon(Icons.build),
                  label: const Text('Diagnostic + Auto Fix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _clearResults,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running diagnostic...'),
                  ],
                ),
              ),
            
            // Error Display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            
            // Results Display
            if (_diagnosticResults != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildResultsDisplay(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsDisplay() {
    final results = _diagnosticResults!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    'Diagnostic Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Issues', '${results['totalIssues'] ?? 0}'),
              _buildSummaryRow('Missing Doctor ID', '${results['missingDoctorId'] ?? 0}'),
              _buildSummaryRow('Invalid Doctor ID', '${results['invalidDoctorId'] ?? 0}'),
              if (results['fixedCount'] != null)
                _buildSummaryRow('Fixed Issues', '${results['fixedCount']}', 
                  color: AppColors.success),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Missing Doctor ID Issues
        if (results['missingDoctorIdAppointments'] != null && 
            (results['missingDoctorIdAppointments'] as List).isNotEmpty)
          _buildIssueSection(
            'Missing Doctor ID',
            results['missingDoctorIdAppointments'] as List,
            AppColors.error,
          ),
        
        // Invalid Doctor ID Issues
        if (results['invalidDoctorIdAppointments'] != null && 
            (results['invalidDoctorIdAppointments'] as List).isNotEmpty)
          _buildIssueSection(
            'Invalid Doctor ID',
            results['invalidDoctorIdAppointments'] as List,
            AppColors.warning,
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSection(String title, List issues, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '$title (${issues.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...issues.take(5).map((issue) => _buildIssueItem(issue)),
              if (issues.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${issues.length - 5} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIssueItem(Map<String, dynamic> issue) {
    final data = issue['data'] as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${issue['id']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('Patient: ${data['patientName'] ?? 'Unknown'}'),
          Text('Doctor: ${data['doctorName'] ?? 'Unknown'}'),
          if (issue['doctorId'] != null)
            Text('Doctor ID: "${issue['doctorId']}"'),
          Text(
            'Issue: ${issue['issue']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _diagnosticResults = null;
    });

    try {
      final results = await AppointmentDiagnostic.runComprehensiveDiagnostic();
      setState(() {
        _diagnosticResults = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runDiagnosticAndFix() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _diagnosticResults = null;
    });

    try {
      final results = await AppointmentDiagnostic.runComprehensiveDiagnostic();
      setState(() {
        _diagnosticResults = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _diagnosticResults = null;
      _error = null;
    });
  }
}