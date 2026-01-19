import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../services/firebase/appointment_service.dart';
import '../../services/firebase/doctor_service.dart';
import '../../services/maps_service.dart';
import '../../services/whatsapp_service.dart';
import '../../services/secure_medical_sharing_service.dart';
import '../patient/find_doctors_screen.dart';
import '../patient/reschedule_appointment_screen.dart';
import '../../screens/emergency/emergency_screen.dart';
import 'medical_record_selection_screen.dart';
import '../doctor/secure_medical_records_viewer.dart';

/// Fast providers for past and cancelled appointments using stream with client-side filtering
/// These providers use the existing appointmentsStreamProvider with client-side filtering
/// to avoid complex Firestore composite index requirements and improve performance

final pastAppointmentsProvider = StreamProvider.family.autoDispose<List<AppointmentModel>, String>((ref, userId) {
  final stopwatch = Stopwatch()..start();
  return AppointmentService.getAppointmentsStream(
    userId: userId,
    status: null, // Get all appointments and filter client-side for better performance
  ).map((appointments) {
    final filtered = appointments
        .where((appointment) => appointment.status == 'completed')
        .toList();
    stopwatch.stop();
    print('Past appointments loaded in ${stopwatch.elapsedMilliseconds}ms (${filtered.length} items)');
    return filtered;
  });
});

final cancelledAppointmentsProvider = StreamProvider.family.autoDispose<List<AppointmentModel>, String>((ref, userId) {
  final stopwatch = Stopwatch()..start();
  return AppointmentService.getAppointmentsStream(
    userId: userId,
    status: null, // Get all appointments and filter client-side for better performance
  ).map((appointments) {
    final filtered = appointments
        .where((appointment) => appointment.status == 'cancelled')
        .toList();
    stopwatch.stop();
    print('Cancelled appointments loaded in ${stopwatch.elapsedMilliseconds}ms (${filtered.length} items)');
    return filtered;
  });
});

/// Appointments screen
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeUtils.getPrimaryColor(context),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage your appointments',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'View, schedule and track your medical visits',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(Icons.schedule, 'Easy Scheduling'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.notifications, 'Reminders'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: ThemeUtils.getSurfaceColor(context),
            child: TabBar(
              controller: _tabController,
              labelColor: ThemeUtils.getPrimaryColor(context),
              unselectedLabelColor: ThemeUtils.getTextSecondaryColor(context),
              indicatorColor: ThemeUtils.getPrimaryColor(context),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildPastTab(),
                _buildCancelledTab(),
              ],
            ),
          ),

          // Bottom Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurfaceColor(context),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getShadowLightColor(context),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showQuickBookingOptions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeUtils.getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final user = ref.watch(currentUserModelProvider);
    
    if (user == null) {
      return const Center(
        child: Text('Please log in to view appointments'),
      );
    }

    // Use the new stream-based upcomingAppointmentsProvider for consistency
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider(user.uid));

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 50,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No upcoming appointments',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Book your first appointment with a verified doctor',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindDoctorsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeUtils.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text(
                      'Find Doctors',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(upcomingAppointmentsProvider(user.uid));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(upcomingAppointmentsProvider(user.uid));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastTab() {
    final user = ref.watch(currentUserModelProvider);
    
    if (user == null) {
      return const Center(
        child: Text('Please log in to view appointments'),
      );
    }

    final appointmentsAsync = ref.watch(pastAppointmentsProvider(user.uid));

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No past appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pastAppointmentsProvider(user.uid));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading past appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(pastAppointmentsProvider(user.uid));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledTab() {
    final user = ref.watch(currentUserModelProvider);
    
    if (user == null) {
      return const Center(
        child: Text('Please log in to view appointments'),
      );
    }

    final appointmentsAsync = ref.watch(cancelledAppointmentsProvider(user.uid));

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 80, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No cancelled appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cancelledAppointmentsProvider(user.uid));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading cancelled appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(cancelledAppointmentsProvider(user.uid));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final isUpcoming = appointment.status == 'confirmed' || appointment.status == 'pending';
    final statusColor = _getStatusColor(appointment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Doctor Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.doctorSpecialty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUpcoming)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAppointmentAction(value, appointment),
                    itemBuilder: (context) {
                      final user = ref.read(currentUserModelProvider);
                      final isDoctorView = user?.role == 'doctor';
                      
                      return [
                        if (!isDoctorView) ...[
                          const PopupMenuItem(
                            value: 'reschedule',
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 18),
                                SizedBox(width: 8),
                                Text('Reschedule'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Cancel', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        if (isDoctorView) ...[
                          const PopupMenuItem(
                            value: 'view_shared_records',
                            child: Row(
                              children: [
                                Icon(Icons.folder_shared, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('View Shared Records', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'complete_appointment',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Mark Complete', style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ];
                    },
                    child: Icon(
                      Icons.more_vert,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Appointment Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceVariantColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(appointment.appointmentDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appointment.timeSlot,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        appointment.consultationType == 'online' ? Icons.video_call : Icons.location_on,
                        size: 16,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${appointment.consultationTypeText} • ${appointment.notes ?? 'No additional notes'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              // Medical Record Sharing Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Share medical records securely with your doctor',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _shareRecords(appointment),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (appointment.consultationType == 'online')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _joinVideoCall(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.video_call, size: 18),
                        label: const Text(
                          'Join Call',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _getDirections(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text(
                          'Directions',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactDoctor(appointment),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeUtils.getPrimaryColor(context),
                        side: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text(
                        'Message',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      return 'In $difference days';
    } else if (difference < -1 && difference >= -7) {
      return '${difference.abs()} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _shareRecords(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalRecordSelectionScreen(
          appointment: appointment,
          onSharingComplete: () {
            // Refresh appointments to show updated sharing status
            final user = ref.read(currentUserModelProvider);
            if (user != null) {
              ref.invalidate(upcomingAppointmentsProvider(user.uid));
            }
          },
        ),
      ),
    ).then((sharingId) {
      if (sharingId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Medical records shared successfully'),
                ),
                TextButton(
                  onPressed: () {
                    // Show sharing details or allow viewing
                    _showSharingDetails(appointment, sharingId);
                  },
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _showSharingDetails(AppointmentModel appointment, String sharingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Records Shared'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your medical records have been securely shared with:'),
            const SizedBox(height: 8),
            Text(
              'Dr. ${appointment.doctorName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${appointment.doctorSpecialty}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Features:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text('• View-only access for doctor'),
                  Text('• No downloads or screenshots allowed'),
                  Text('• Access expires after appointment'),
                  Text('• All access is logged for security'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (ref.read(currentUserModelProvider)?.role == 'doctor')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecureMedicalRecordsViewer(
                      sharingId: sharingId,
                      appointment: appointment,
                    ),
                  ),
                );
              },
              child: const Text('View Records'),
            ),
        ],
      ),
    );
  }

  void _handleAppointmentAction(String action, AppointmentModel appointment) {
    switch (action) {
      case 'reschedule':
        _rescheduleAppointment(appointment);
        break;
      case 'cancel':
        _cancelAppointment(appointment);
        break;
      case 'view_shared_records':
        _viewSharedRecords(appointment);
        break;
      case 'complete_appointment':
        _completeAppointment(appointment);
        break;
    }
  }

  void _viewSharedRecords(AppointmentModel appointment) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final user = ref.read(currentUserModelProvider);
      if (user == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Find sharing session for this appointment
      final sharingSessions = await SecureMedicalSharingService.getDoctorSharingSessions(
        doctorId: user.uid,
        activeOnly: true,
      );

      final appointmentSharing = sharingSessions
          .where((sharing) => sharing.appointmentId == appointment.id)
          .firstOrNull;

      Navigator.pop(context); // Close loading dialog

      if (appointmentSharing == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No medical records have been shared for this appointment'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Navigate to secure viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecureMedicalRecordsViewer(
            sharingId: appointmentSharing.id,
            appointment: appointment,
          ),
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing shared records: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _completeAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: Text('Mark appointment with ${appointment.patientName} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await AppointmentService.updateAppointmentStatus(
                  appointmentId: appointment.id,
                  status: 'completed',
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment marked as completed'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error completing appointment: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleAppointmentScreen(
          appointment: appointment,
        ),
      ),
    ).then((result) {
      // If reschedule was successful, refresh the appointments
      if (result == true) {
        final user = ref.read(currentUserModelProvider);
        if (user != null) {
          // Refresh all appointment providers
          ref.invalidate(upcomingAppointmentsProvider(user.uid));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment rescheduled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    });
  }

  void _cancelAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel your appointment with ${appointment.doctorName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await ref.read(appointmentsListProvider.notifier).cancelAppointment(
                  appointmentId: appointment.id,
                  cancellationReason: 'Cancelled by patient',
                  cancelledBy: 'patient',
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment cancelled'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling appointment: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  void _joinVideoCall(AppointmentModel appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining video call with ${appointment.doctorName}...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _getDirections(AppointmentModel appointment) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Getting directions...'),
            ],
          ),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 2),
        ),
      );

      // Get doctor details to get clinic address
      final doctor = await DoctorService.getDoctorById(appointment.doctorId);
      
      if (doctor == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get doctor information'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Check if clinic address is available
      if (doctor.clinicAddress == null || doctor.clinicAddress!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clinic address not available'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Open Google Maps with directions
      final success = await MapsService.openDirectionsFromCurrentLocation(
        destinationAddress: doctor.fullAddress,
        destinationName: doctor.clinicName,
        destinationLat: doctor.location?.latitude,
        destinationLng: doctor.location?.longitude,
      );

      if (!success && mounted) {
        // Show options dialog if direct opening failed
        _showDirectionsOptions(doctor);
      }

    } catch (e) {
      print('Error getting directions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting directions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _contactDoctor(AppointmentModel appointment) async {
    try {
      // Debug: Print appointment details
      print('🔍 Contacting doctor for appointment:');
      print('  - Appointment ID: ${appointment.id}');
      print('  - Doctor ID: "${appointment.doctorId}"');
      print('  - Doctor Name: ${appointment.doctorName}');
      print('  - Patient Name: ${appointment.patientName}');
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Finding doctor...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );

      DoctorModel? doctor;
      
      // Try to get doctor by ID first
      if (appointment.doctorId.isNotEmpty) {
        print('🔍 Fetching doctor details for ID: ${appointment.doctorId}');
        doctor = await DoctorService.getDoctorById(appointment.doctorId);
      }
      
      // If doctor not found by ID or ID is empty, try to find by name
      if (doctor == null && appointment.doctorName.isNotEmpty) {
        print('🔍 Doctor ID empty or not found, searching by name: ${appointment.doctorName}');
        final doctors = await DoctorService.searchDoctorsByName(appointment.doctorName);
        
        if (doctors.isNotEmpty) {
          // Find exact match first, then partial match
          doctor = doctors.firstWhere(
            (d) => d.fullName.toLowerCase() == appointment.doctorName.toLowerCase(),
            orElse: () => doctors.first,
          );
          print('✅ Found doctor by name: ${doctor.fullName} (ID: ${doctor.uid})');
          
          // Update the appointment with the correct doctorId for future use
          try {
            await AppointmentService.updateAppointment(
              appointmentId: appointment.id,
              updates: {'doctorId': doctor.uid},
            );
            print('✅ Updated appointment with correct doctorId');
          } catch (e) {
            print('⚠️ Could not update appointment with doctorId: $e');
          }
        }
      }
      
      if (doctor == null) {
        print('❌ Could not find doctor');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to find doctor information. Please contact support.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      print('✅ Doctor found: ${doctor.fullName}');
      print('📱 Doctor phone: ${doctor.phoneNumber ?? 'Not available'}');

      // Check if doctor has phone number
      if (doctor.phoneNumber == null || doctor.phoneNumber!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor contact information is not available'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Format appointment time for WhatsApp message
      final appointmentTime = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        int.parse(appointment.timeSlot.split(':')[0]),
        int.parse(appointment.timeSlot.split(':')[1].split(' ')[0]),
      );

      // Try to open WhatsApp
      final success = await WhatsAppService.openDoctorChat(
        doctorName: doctor.fullName,
        doctorPhone: doctor.phoneNumber!,
        patientName: appointment.patientName,
        appointmentDate: _formatDate(appointment.appointmentDate),
        appointmentTime: appointment.timeSlot,
        clinicName: doctor.clinicName,
      );

      if (!success && mounted) {
        // Show contact options dialog if WhatsApp failed
        _showContactOptions(doctor, appointment);
      }

    } catch (e) {
      print('Error contacting doctor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error contacting doctor: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickBookingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                color: ThemeUtils.getBorderMediumColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: ThemeUtils.getPrimaryColor(context),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Book Your Appointment',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your preferred consultation type',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildBookingOption(
                              icon: Icons.video_call,
                              title: 'Video Consultation',
                              subtitle: 'Connect with doctors online from home',
                              color: AppColors.secondary,
                              badge: 'Popular',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FindDoctorsScreen(
                                      consultationType: 'online',
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildBookingOption(
                              icon: Icons.location_on,
                              title: 'In-Person Visit',
                              subtitle: 'Visit doctor at clinic for physical examination',
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FindDoctorsScreen(
                                      consultationType: 'offline',
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildBookingOption(
                              icon: Icons.emergency,
                              title: 'Emergency Consultation',
                              subtitle: 'Immediate medical attention required',
                              color: AppColors.error,
                              badge: '24/7',
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to emergency screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EmergencyScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: ThemeUtils.getPrimaryColor(context),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'All consultations are with verified doctors',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: ThemeUtils.getPrimaryColor(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ThemeUtils.getBorderLightColor(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Doctor Avatar Skeleton
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: ThemeUtils.getBorderLightColor(context),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor name skeleton
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: ThemeUtils.getBorderLightColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Specialty skeleton
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: ThemeUtils.getBorderLightColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Status skeleton
                          Container(
                            height: 20,
                            width: 80,
                            decoration: BoxDecoration(
                              color: ThemeUtils.getBorderLightColor(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details skeleton
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getSurfaceVariantColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: ThemeUtils.getBorderLightColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: ThemeUtils.getBorderLightColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ThemeUtils.getBorderLightColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceVariantColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
          boxShadow: [
            BoxShadow(
              color: ThemeUtils.getShadowLightColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
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
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show directions options dialog
  void _showDirectionsOptions(dynamic doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get Directions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinic: ${doctor.clinicName ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Address: ${doctor.fullAddress}'),
            const SizedBox(height: 16),
            const Text('Choose an option:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MapsService.copyAddressToClipboard(doctor.fullAddress);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address copied to clipboard'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Copy Address'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MapsService.openLocation(
                address: doctor.fullAddress,
                locationName: doctor.clinicName,
                latitude: doctor.location?.latitude,
                longitude: doctor.location?.longitude,
              );
            },
            child: const Text('Open in Maps'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              MapsService.openDirectionsFromCurrentLocation(
                destinationAddress: doctor.fullAddress,
                destinationName: doctor.clinicName,
                destinationLat: doctor.location?.latitude,
                destinationLng: doctor.location?.longitude,
              );
            },
            child: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }

  /// Show contact options dialog
  void _showContactOptions(dynamic doctor, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${doctor.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${WhatsAppService.formatPhoneForDisplay(doctor.phoneNumber)}'),
            const SizedBox(height: 8),
            Text('Clinic: ${doctor.clinicName ?? 'N/A'}'),
            const SizedBox(height: 16),
            const Text('Choose an option:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              WhatsAppService.copyPhoneToClipboard(doctor.phoneNumber);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied to clipboard'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Copy Number'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = ref.read(currentUserModelProvider);
              final patientName = user?.fullName ?? 'Patient';
              
              await WhatsAppService.openGeneralInquiry(
                doctorName: appointment.doctorName,
                doctorPhone: doctor.phoneNumber,
                patientName: patientName,
              );
            },
            child: const Text('WhatsApp'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = ref.read(currentUserModelProvider);
              final patientName = user?.fullName ?? 'Patient';
              final appointmentDate = _formatDate(appointment.appointmentDate);
              
              await WhatsAppService.openDoctorChat(
                doctorName: appointment.doctorName,
                doctorPhone: doctor.phoneNumber,
                patientName: patientName,
                appointmentDate: appointmentDate,
                appointmentTime: appointment.timeSlot,
                clinicName: doctor.clinicName,
              );
            },
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }
}
