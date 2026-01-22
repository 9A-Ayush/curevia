import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment_model.dart';
import '../../services/doctor/doctor_service.dart';
import '../../services/firebase/appointment_service.dart';
import '../../services/notifications/payment_notification_service.dart';
import '../../widgets/common/custom_button.dart';
import 'create_prescription_screen.dart';
import '../debug/doctor_appointment_seeding_screen.dart';
import '../../utils/appointment_diagnostic.dart';

/// Doctor appointments screen for managing appointments
class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends ConsumerState<DoctorAppointmentsScreen>
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
    final user = ref.watch(currentUserModelProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view appointments'),
        ),
      );
    }

    // Watch the stream providers
    final todayAppointmentsAsync = ref.watch(todayDoctorAppointmentsProvider(user.uid));
    final upcomingAppointmentsAsync = ref.watch(upcomingDoctorAppointmentsProvider(user.uid));
    final pastAppointmentsAsync = ref.watch(pastDoctorAppointmentsProvider(user.uid));

    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      body: Column(
        children: [
          // Header with info (similar to user-side design)
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                              'Manage Appointments',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'View and manage your patient consultations',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showFilterDialog,
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        tooltip: 'Filter',
                      ),
                      IconButton(
                        onPressed: _showDebugMenu,
                        icon: const Icon(
                          Icons.bug_report,
                          color: Colors.white,
                        ),
                        tooltip: 'Debug',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(Icons.schedule, 'Real-time Updates'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.video_call, 'Video Consultations'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content area with tabs
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ThemeUtils.getBackgroundColor(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Tab bar with counts
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: ThemeUtils.getTextSecondaryColor(
                        context,
                      ),
                      indicator: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Today'),
                              todayAppointmentsAsync.when(
                                data: (appointments) => appointments.isNotEmpty ? _buildCountBadge(appointments.length) : const SizedBox.shrink(),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Upcoming'),
                              upcomingAppointmentsAsync.when(
                                data: (appointments) => appointments.isNotEmpty ? _buildCountBadge(appointments.length) : const SizedBox.shrink(),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        const Tab(text: 'Past'),
                      ],
                    ),
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAppointmentsTab(todayAppointmentsAsync, 'today'),
                        _buildAppointmentsTab(upcomingAppointmentsAsync, 'upcoming'),
                        _buildAppointmentsTab(pastAppointmentsAsync, 'past'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Appointment'),
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab(AsyncValue<List<AppointmentModel>> appointmentsAsync, String type) {
    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Invalidate the providers to refresh data
            final user = ref.read(currentUserModelProvider);
            if (user != null) {
              ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
              ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
              ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment, type);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(currentUserModelProvider);
                if (user != null) {
                  ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
                  ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
                  ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'today':
        title = 'No appointments today';
        subtitle = 'Enjoy your free time!';
        icon = Icons.calendar_today_outlined;
        break;
      case 'upcoming':
        title = 'No upcoming appointments';
        subtitle = 'Your schedule is clear';
        icon = Icons.schedule_outlined;
        break;
      case 'past':
        title = 'No past appointments';
        subtitle = 'Your appointment history will appear here';
        icon = Icons.history;
        break;
      default:
        title = 'No appointments';
        subtitle = '';
        icon = Icons.calendar_today_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, String type) {
    final isToday = type == 'today';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.borderLight,
          width: isToday ? 2 : 1,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient info and status
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      appointment.patientName
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(appointment.appointmentDate),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _getConsultationIcon(appointment.consultationType),
                            size: 16,
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTypeDisplayText(appointment.consultationType),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),

            if (appointment.symptoms != null &&
                appointment.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Symptoms',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointment.symptoms!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            // Patient info section
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(
                  Icons.person,
                  'Patient ID',
                  appointment.patientId.substring(0, 8),
                ),
                const SizedBox(width: 20),
                _buildInfoItem(
                  Icons.payment,
                  'Fee',
                  appointment.consultationFee != null
                      ? '₹${appointment.consultationFee!.toStringAsFixed(0)}'
                      : 'Not set',
                ),
              ],
            ),

            // Action buttons based on appointment type and status
            if (type == 'today' || type == 'upcoming') ...[
              const SizedBox(height: 20),
              _buildActionButtons(appointment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        displayText = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        displayText = 'Confirmed';
        break;
      case 'in_progress':
      case 'inprogress':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        displayText = 'In Progress';
        break;
      case 'completed':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = ThemeUtils.getSurfaceColor(context);
        textColor = ThemeUtils.getTextSecondaryColor(context);
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppointmentModel appointment) {
    final canStart =
        appointment.status == 'confirmed' || appointment.status == 'pending';
    final canComplete =
        appointment.status == 'in_progress' ||
        appointment.status == 'inprogress';
    final canCancel =
        appointment.status == 'pending' || appointment.status == 'confirmed';
    final canReschedule = 
        appointment.status == 'pending' || appointment.status == 'confirmed';
    final isCompleted = appointment.status == 'completed';

    return Column(
      children: [
        // Main action buttons
        if (canStart || canComplete || canCancel) ...[
          Row(
            children: [
              if (canStart) ...[
                Expanded(
                  child: CustomButton(
                    text: appointment.consultationType == 'video' ? 'Start Video Call' : 'Start Consultation',
                    onPressed: () => appointment.consultationType == 'video' 
                        ? _startVideoCall(appointment)
                        : _updateAppointmentStatus(appointment.id, 'in_progress'),
                    backgroundColor: AppColors.success,
                    textColor: AppColors.textOnPrimary,
                    icon: appointment.consultationType == 'video' ? Icons.videocam : Icons.play_arrow,
                  ),
                ),
              ],
              if (canComplete) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Complete',
                    onPressed: () =>
                        _updateAppointmentStatus(appointment.id, 'completed'),
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.textOnPrimary,
                    icon: Icons.check,
                  ),
                ),
              ],
              if (canCancel && (canStart || canComplete)) const SizedBox(width: 8),
              if (canCancel) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    onPressed: () => _showCancelDialog(appointment),
                    backgroundColor: AppColors.error,
                    textColor: AppColors.textOnPrimary,
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ],
          ),
        ],
        
        // Secondary action buttons (Reschedule, Prescription, Payment)
        if (canReschedule || canComplete || isCompleted) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              // Reschedule button
              if (canReschedule) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRescheduleDialog(appointment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text(
                      'Reschedule',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Prescription button
              if (canComplete || isCompleted) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePrescription(appointment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text(
                      isCompleted ? 'View Prescription' : 'Create Prescription',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
              
              // Payment button
              if (appointment.paymentStatus == 'pay_on_clinic' && isCompleted) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markPaymentReceived(appointment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text(
                      'Mark Paid',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      final success = await DoctorService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment status updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the stream providers
        final user = ref.read(currentUserModelProvider);
        if (user != null) {
          ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
          ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
          ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update appointment status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel the appointment with ${appointment.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointment.id, 'cancelled');
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  /// Start video call for video consultations
  void _startVideoCall(AppointmentModel appointment) async {
    try {
      // Update appointment status to in_progress
      await _updateAppointmentStatus(appointment.id, 'in_progress');
      
      // Navigate to video call screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/video_call',
          arguments: {
            'appointmentId': appointment.id,
            'patientName': appointment.patientName,
            'patientId': appointment.patientId,
            'doctorId': appointment.doctorId,
            'isDoctor': true,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting video call: $e')),
        );
      }
    }
  }

  /// Show reschedule dialog
  void _showRescheduleDialog(AppointmentModel appointment) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reschedule appointment with ${appointment.patientName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'New Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    dateController.text = '${date.day}/${date.month}/${date.year}';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'New Time',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    timeController.text = time.format(context);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dateController.text.isEmpty || timeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select both date and time')),
                );
                return;
              }
              
              Navigator.pop(context);
              await _rescheduleAppointment(
                appointment,
                dateController.text,
                timeController.text,
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  /// Reschedule appointment
  Future<void> _rescheduleAppointment(
    AppointmentModel appointment,
    String newDateString,
    String newTimeString,
  ) async {
    try {
      // Parse the date string (format: dd/mm/yyyy)
      final dateParts = newDateString.split('/');
      final newDate = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
      );

      await AppointmentService.rescheduleAppointment(
        appointmentId: appointment.id,
        newDate: newDate,
        newTimeSlot: newTimeString,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rescheduling appointment: $e')),
        );
      }
    }
  }

  String _getTypeDisplayText(String? type) {
    switch (type?.toLowerCase()) {
      case 'online':
        return 'Online Consultation';
      case 'offline':
        return 'In-Person Visit';
      case 'video':
        return 'Video Call';
      case 'chat':
        return 'Chat Consultation';
      default:
        return 'Consultation';
    }
  }

  IconData _getConsultationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'online':
      case 'video':
        return Icons.video_call;
      case 'offline':
        return Icons.local_hospital;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.medical_services;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ThemeUtils.getTextSecondaryColor(context),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Appointments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Appointments'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Apply filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_call),
              title: const Text('Video Consultations'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Apply filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital),
              title: const Text('In-Person Visits'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Apply filter
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugMenu() {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text('Check Database'),
              subtitle: const Text('Diagnose appointment data issues'),
              onTap: () {
                Navigator.pop(context);
                _runDatabaseDiagnostic();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Seed Sample Appointments'),
              subtitle: const Text('Create test appointments for development'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorAppointmentSeedingScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Test Payment Notifications'),
              onTap: () {
                Navigator.pop(context);
                _testPaymentNotifications();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh All Data'),
              onTap: () {
                Navigator.pop(context);
                _refreshAllData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Show Debug Info'),
              onTap: () {
                Navigator.pop(context);
                _showDebugInfo();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _testPaymentNotifications() async {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    try {
      await PaymentNotificationService.testPaymentNotifications(
        patientId: 'test_patient_id',
        doctorId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notifications sent! Check your notifications.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshAllData() {
    final user = ref.read(currentUserModelProvider);
    if (user != null) {
      ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
      ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
      ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _runDatabaseDiagnostic() async {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Running diagnostic...'),
          ],
        ),
      ),
    );

    try {
      // Run diagnostic for this doctor
      final doctorResults = await AppointmentDiagnostic.checkDoctorAppointments(user.uid);
      final allResults = await AppointmentDiagnostic.checkAllAppointments();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show results
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Diagnostic Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Appointments:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ${doctorResults['totalAppointments'] ?? 0}'),
                  Text('Today: ${doctorResults['todayAppointments'] ?? 0}'),
                  Text('Upcoming: ${doctorResults['upcomingAppointments'] ?? 0}'),
                  Text('Status: ${doctorResults['statusBreakdown'] ?? {}}'),
                  const SizedBox(height: 16),
                  Text(
                    'System-wide:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Total appointments: ${allResults['totalAppointments'] ?? 0}'),
                  Text('Unique doctors: ${allResults['uniqueDoctors'] ?? 0}'),
                  Text('Unique patients: ${allResults['uniquePatients'] ?? 0}'),
                  const SizedBox(height: 16),
                  if (doctorResults['totalAppointments'] == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'No appointments found for your account. This explains why the appointments screen is empty. You can use the seeding tool to create test appointments.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (doctorResults['totalAppointments'] == 0)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorAppointmentSeedingScreen(),
                      ),
                    );
                  },
                  child: const Text('Create Test Data'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDebugInfo() {
    final user = ref.read(currentUserModelProvider);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Doctor ID: ${user.uid}'),
              Text('Doctor Name: ${user.fullName}'),
              Text('Role: ${user.role}'),
              const SizedBox(height: 16),
              const Text('Stream Providers Status:'),
              Consumer(
                builder: (context, ref, child) {
                  final todayAsync = ref.watch(todayDoctorAppointmentsProvider(user.uid));
                  final upcomingAsync = ref.watch(upcomingDoctorAppointmentsProvider(user.uid));
                  final pastAsync = ref.watch(pastDoctorAppointmentsProvider(user.uid));
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today: ${todayAsync.when(
                        data: (data) => '${data.length} appointments',
                        loading: () => 'Loading...',
                        error: (e, _) => 'Error: $e',
                      )}'),
                      Text('Upcoming: ${upcomingAsync.when(
                        data: (data) => '${data.length} appointments',
                        loading: () => 'Loading...',
                        error: (e, _) => 'Error: $e',
                      )}'),
                      Text('Past: ${pastAsync.when(
                        data: (data) => '${data.length} appointments',
                        loading: () => 'Loading...',
                        error: (e, _) => 'Error: $e',
                      )}'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog() {
    final TextEditingController patientNameController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    String consultationType = 'online';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: patientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    hintText: 'Enter patient name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'Select date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dateController.text = '${date.day}/${date.month}/${date.year}';
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: 'Select time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      timeController.text = time.format(context);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: consultationType,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Type',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                    DropdownMenuItem(value: 'offline', child: Text('In-Person')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => consultationType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (patientNameController.text.isNotEmpty &&
                    dateController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  Navigator.pop(context);
                  // TODO: Implement appointment creation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment creation feature coming soon'),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle prescription creation/viewing
  void _handlePrescription(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePrescriptionScreen(
          appointment: appointment,
        ),
      ),
    ).then((_) {
      // Refresh the stream providers after prescription is created
      final user = ref.read(currentUserModelProvider);
      if (user != null) {
        ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
        ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
        ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
      }
    });
  }

  /// Mark payment as received for pay-on-clinic appointments
  Future<void> _markPaymentReceived(AppointmentModel appointment) async {
    try {
      // Show payment method selection dialog
      final paymentMethod = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text('Cash'),
                onTap: () => Navigator.pop(context, 'cash'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Card'),
                onTap: () => Navigator.pop(context, 'card'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('UPI'),
                onTap: () => Navigator.pop(context, 'upi'),
              ),
            ],
          ),
        ),
      );

      if (paymentMethod != null) {
        await AppointmentService.markPaymentReceived(
          appointmentId: appointment.id,
          paymentMethod: paymentMethod,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment marked as received'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Send payment notification to patient
        _sendPaymentNotification(appointment, paymentMethod);

        // Refresh the stream providers
        final user = ref.read(currentUserModelProvider);
        if (user != null) {
          ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
          ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
          ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Send payment notification to patient
  Future<void> _sendPaymentNotification(
    AppointmentModel appointment,
    String paymentMethod,
  ) async {
    try {
      // Send notification to patient
      await PaymentNotificationService.sendPaymentSuccessToPatient(
        patientId: appointment.patientId,
        appointmentId: appointment.id,
        amount: appointment.consultationFee ?? 0,
        paymentMethod: paymentMethod,
        doctorName: appointment.doctorName,
      );

      // Send notification to doctor
      await PaymentNotificationService.sendPaymentReceivedToDoctor(
        doctorId: appointment.doctorId,
        appointmentId: appointment.id,
        amount: appointment.consultationFee ?? 0,
        paymentMethod: paymentMethod,
        patientName: appointment.patientName,
      );

      print('✅ Payment notifications sent successfully');
      
      // Refresh the stream providers
      final user = ref.read(currentUserModelProvider);
      if (user != null) {
        ref.invalidate(todayDoctorAppointmentsProvider(user.uid));
        ref.invalidate(upcomingDoctorAppointmentsProvider(user.uid));
        ref.invalidate(pastDoctorAppointmentsProvider(user.uid));
      }
    } catch (e) {
      print('⚠️ Error sending payment notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}