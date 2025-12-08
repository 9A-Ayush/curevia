import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_booking_service.dart';
import '../../widgets/common/custom_button.dart';

/// Screen for managing user's appointments
class AppointmentManagementScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const AppointmentManagementScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends ConsumerState<AppointmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  bool _isLoadingUpcoming = true;
  bool _isLoadingPast = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingUpcoming = true;
      _isLoadingPast = true;
    });

    try {
      const userId = 'current_user_id'; // TODO: Get from auth service

      final futures = await Future.wait([
        AppointmentBookingService.getUpcomingAppointments(userId),
        AppointmentBookingService.getAppointmentHistory(userId),
      ]);

      setState(() {
        _upcomingAppointments = futures[0] as List<AppointmentModel>;
        _pastAppointments = (futures[1] as List<AppointmentModel>)
            .where(
              (appointment) =>
                  appointment.appointmentDate.isBefore(DateTime.now()) ||
                  appointment.status == 'completed' ||
                  appointment.status == 'cancelled',
            )
            .toList();
        _isLoadingUpcoming = false;
        _isLoadingPast = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUpcoming = false;
        _isLoadingPast = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await AppointmentBookingService.cancelAppointment(
          appointmentId: appointment.id,
          cancellationReason: 'Cancelled by patient',
          cancelledBy: 'patient',
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully')),
          );
          _loadAppointments(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to cancel appointment')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: widget.showBackButton,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUpcomingTab(), _buildPastTab()],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoadingUpcoming) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        'No upcoming appointments',
        'You don\'t have any upcoming appointments',
        Icons.calendar_today_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _upcomingAppointments[index];
          return _buildAppointmentCard(appointment, isUpcoming: true);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_isLoadingPast) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pastAppointments.isEmpty) {
      return _buildEmptyState(
        'No past appointments',
        'Your appointment history will appear here',
        Icons.history,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pastAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _pastAppointments[index];
          return _buildAppointmentCard(appointment, isUpcoming: false);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment, {
    required bool isUpcoming,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with doctor info and status
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppColors.primary, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        appointment.doctorSpecialty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),

            const SizedBox(height: 16),

            // Appointment details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today,
                    'Date',
                    _formatDate(appointment.appointmentDate),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.access_time,
                    'Time',
                    appointment.timeSlot ?? 'Not specified',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    appointment.consultationType == 'online'
                        ? Icons.video_call
                        : Icons.local_hospital,
                    'Type',
                    appointment.consultationType == 'online'
                        ? 'Video Call'
                        : 'In-Person',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.payment,
                    'Fee',
                    '₹${appointment.consultationFee?.toStringAsFixed(0) ?? '0'}',
                  ),
                ),
              ],
            ),

            // Action buttons for upcoming appointments
            if (isUpcoming &&
                (appointment.status == 'pending' ||
                    appointment.status == 'confirmed')) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (appointment.consultationType == 'online')
                    Expanded(
                      child: CustomButton(
                        text: 'Join Call',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.video_call, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  const Text('Join Video Call'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'You are about to join a video consultation with your doctor.',
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: AppColors.info),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Please ensure you have a stable internet connection.',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // TODO: Implement actual video call integration
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Connecting to video call...'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.video_call),
                                  label: const Text('Join Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        backgroundColor: AppColors.success,
                        textColor: AppColors.textOnPrimary,
                        icon: Icons.video_call,
                      ),
                    ),
                  if (appointment.consultationType == 'online')
                    const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: () => _cancelAppointment(appointment),
                      backgroundColor: AppColors.error,
                      textColor: AppColors.textOnPrimary,
                      icon: Icons.cancel,
                    ),
                  ),
                ],
              ),
            ],

            // Show cancellation reason if cancelled
            if (appointment.status == 'cancelled' &&
                appointment.cancellationReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancelled: ${appointment.cancellationReason}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        displayText = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        displayText = 'Confirmed';
        break;
      case 'completed':
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = AppColors.surface;
        textColor = AppColors.textSecondary;
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (appointmentDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}
