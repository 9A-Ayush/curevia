import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/doctor/appointment_seeding_service.dart';
import '../../services/doctor/real_appointment_creator.dart';
import '../../widgets/common/custom_button.dart';

/// Debug screen for seeding doctor appointments
class DoctorAppointmentSeedingScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentSeedingScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentSeedingScreen> createState() => _DoctorAppointmentSeedingScreenState();
}

class _DoctorAppointmentSeedingScreenState extends ConsumerState<DoctorAppointmentSeedingScreen> {
  bool _isLoading = false;
  Map<String, int> _appointmentStats = {};
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAppointmentStats();
  }

  Future<void> _loadAppointmentStats() async {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await AppointmentSeedingService.getAppointmentStats(
        doctorId: user.uid,
      );
      
      setState(() {
        _appointmentStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading stats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _seedAppointments() async {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Seeding sample appointments...';
    });

    try {
      await AppointmentSeedingService.seedSampleAppointments(
        doctorId: user.uid,
        doctorName: user.fullName,
        doctorSpecialty: user.additionalInfo?['specialty'] ?? 'General Medicine',
      );
      
      setState(() {
        _statusMessage = '✅ Successfully seeded sample appointments!';
        _isLoading = false;
      });
      
      // Reload stats
      await _loadAppointmentStats();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error seeding appointments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createRealAppointments() async {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating real appointments with actual patients...';
    });

    try {
      final appointmentIds = await RealAppointmentCreator.createRealisticAppointments(
        doctorId: user.uid,
        doctorName: user.fullName,
        doctorSpecialty: user.additionalInfo?['specialty'] ?? 'General Medicine',
      );
      
      setState(() {
        _statusMessage = '✅ Successfully created ${appointmentIds.length} real appointments!';
        _isLoading = false;
      });
      
      // Reload stats
      await _loadAppointmentStats();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error creating real appointments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAppointments() async {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sample Appointments'),
        content: const Text(
          'Are you sure you want to clear all sample appointments? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing sample appointments...';
    });

    try {
      await AppointmentSeedingService.clearSampleAppointments(
        doctorId: user.uid,
      );
      
      setState(() {
        _statusMessage = '✅ Successfully cleared sample appointments!';
        _isLoading = false;
      });
      
      // Reload stats
      await _loadAppointmentStats();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error clearing appointments: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider);
    
    if (user?.role != 'doctor') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: ThemeUtils.getPrimaryColor(context),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'This screen is only available for doctors.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Seeding'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeUtils.getPrimaryColor(context).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: ThemeUtils.getPrimaryColor(context),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Debug: Appointment Seeding',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeUtils.getPrimaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create sample appointments for testing the doctor interface.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Stats
            if (_appointmentStats.isNotEmpty) ...[
              Text(
                'Current Appointment Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeUtils.getBorderLightColor(context),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Total Appointments', _appointmentStats['total'] ?? 0, Icons.calendar_today),
                    const Divider(height: 20),
                    _buildStatRow('Confirmed', _appointmentStats['confirmed'] ?? 0, Icons.check_circle, Colors.blue),
                    _buildStatRow('Completed', _appointmentStats['completed'] ?? 0, Icons.done_all, Colors.green),
                    _buildStatRow('Cancelled', _appointmentStats['cancelled'] ?? 0, Icons.cancel, Colors.red),
                    _buildStatRow('Pending', _appointmentStats['pending'] ?? 0, Icons.pending, Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Status Message
            if (_statusMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.startsWith('✅') 
                      ? Colors.green.withOpacity(0.1)
                      : _statusMessage.startsWith('❌')
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusMessage.startsWith('✅') 
                        ? Colors.green.withOpacity(0.3)
                        : _statusMessage.startsWith('❌')
                            ? Colors.red.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _statusMessage.startsWith('✅') 
                        ? Colors.green[700]
                        : _statusMessage.startsWith('❌')
                            ? Colors.red[700]
                            : Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Actions
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Seed Appointments Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Create Real Appointments',
                onPressed: _isLoading ? null : _createRealAppointments,
                backgroundColor: Colors.blue,
                icon: Icons.add_business,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 12),

            // Seed Test Data Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Seed Test Appointments (Sample)',
                onPressed: _isLoading ? null : _seedAppointments,
                backgroundColor: Colors.green,
                icon: Icons.add_circle,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 12),

            // Clear Appointments Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Clear Sample Appointments',
                onPressed: _isLoading ? null : _clearAppointments,
                backgroundColor: Colors.red,
                icon: Icons.delete_sweep,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 12),

            // Refresh Stats Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Refresh Statistics',
                onPressed: _isLoading ? null : _loadAppointmentStats,
                backgroundColor: Colors.blue,
                icon: Icons.refresh,
                isLoading: _isLoading,
              ),
            ),

            const SizedBox(height: 24),

            // Data Type Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Real vs Test Appointments',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🔵 Real Appointments:\n'
                    '• Creates actual patient accounts in Firebase\n'
                    '• Uses realistic patient data and scenarios\n'
                    '• Integrates with all app features (notifications, payments, etc.)\n'
                    '• 5 appointments: 2 today, 2 tomorrow, 1 day after\n'
                    '• Patients: Sarah Johnson, Michael Chen, Emily Rodriguez, etc.\n\n'
                    '🟢 Test Appointments (Sample):\n'
                    '• Simple test data for quick testing\n'
                    '• Fake patient names (John Doe, Jane Smith)\n'
                    '• 5 appointments across different time periods\n'
                    '• Good for UI testing and development',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recommendation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.recommend,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For testing the doctor interface with real-time Firebase data, use "Create Real Appointments". This will give you the most realistic experience and test all app features properly.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? ThemeUtils.getTextSecondaryColor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? ThemeUtils.getPrimaryColor(context)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? ThemeUtils.getPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}