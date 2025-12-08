import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment_model.dart';
import '../../services/doctor/doctor_service.dart';
import '../../widgets/common/custom_button.dart';

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
  List<AppointmentModel> _todayAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        final futures = await Future.wait([
          DoctorService.getDoctorAppointments(
            doctorId: user.uid,
            startDate: today,
            endDate: tomorrow,
          ),
          DoctorService.getDoctorAppointments(
            doctorId: user.uid,
            startDate: tomorrow,
          ),
          DoctorService.getDoctorAppointments(
            doctorId: user.uid,
            endDate: today,
          ),
        ]);

        setState(() {
          _todayAppointments = futures[0];
          _upcomingAppointments = futures[1];
          _pastAppointments = futures[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                                    color: Colors.white.withValues(alpha: 0.9),
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
                  // Tab bar
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Today'),
                              if (_todayAppointments.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_todayAppointments.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Upcoming'),
                              if (_upcomingAppointments.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_upcomingAppointments.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
                        _buildAppointmentsList(_todayAppointments, 'today'),
                        _buildAppointmentsList(
                          _upcomingAppointments,
                          'upcoming',
                        ),
                        _buildAppointmentsList(_pastAppointments, 'past'),
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

  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    String type,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment, type);
        },
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
              ? AppColors.primary.withValues(alpha: 0.3)
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
                        AppColors.primary.withValues(alpha: 0.8),
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
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
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
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        displayText = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        displayText = 'Confirmed';
        break;
      case 'in_progress':
      case 'inprogress':
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        displayText = 'In Progress';
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

    return Row(
      children: [
        if (canStart)
          Expanded(
            child: CustomButton(
              text: 'Start Consultation',
              onPressed: () =>
                  _updateAppointmentStatus(appointment.id, 'in_progress'),
              backgroundColor: AppColors.success,
              textColor: AppColors.textOnPrimary,
              icon: Icons.play_arrow,
            ),
          ),
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
          const SizedBox(width: 8),
        ],
        if (canCancel) ...[
          if (canStart || canComplete) const SizedBox(width: 8),
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
            const SnackBar(content: Text('Appointment status updated')),
          );
        }
        _loadAppointments(); // Refresh the list
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update appointment status'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating appointment: $e')),
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
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
                    DropdownMenuItem(value: 'offline', child: Text('Offline')),
                    DropdownMenuItem(value: 'video', child: Text('Video Call')),
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
            TextButton(
              onPressed: () async {
                if (patientNameController.text.isEmpty ||
                    dateController.text.isEmpty ||
                    timeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final user = ref.read(authProvider).userModel;
                  if (user != null) {
                    await DoctorService.createAppointment(
                      doctorId: user.uid,
                      patientName: patientNameController.text,
                      date: dateController.text,
                      time: timeController.text,
                      consultationType: consultationType,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment created successfully'),
                        ),
                      );
                      _loadAppointments();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating appointment: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConsultationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return Icons.video_call;
      case 'offline':
      case 'in-person':
        return Icons.local_hospital;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.medical_services;
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ThemeUtils.getTextSecondaryColor(context)),
        const SizedBox(width: 4),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
