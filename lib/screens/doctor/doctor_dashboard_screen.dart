import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/appointment_model.dart';
import '../../services/doctor/doctor_service.dart';
import '../../providers/doctor_navigation_provider.dart';
import 'doctor_consultation_screen.dart';
import 'doctor_schedule_screen.dart';

/// Doctor dashboard screen with overview and quick actions
class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  Map<String, int> _stats = {};
  List<AppointmentModel> _todayAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        final futures = await Future.wait([
          DoctorService.getDoctorStats(user.uid),
          DoctorService.getTodayAppointments(user.uid),
        ]);

        setState(() {
          _stats = futures[0] as Map<String, int>;
          _todayAppointments = futures[1] as List<AppointmentModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userModel;

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.textOnPrimary
                                  .withValues(alpha: 0.2),
                              backgroundImage: user?.profileImageUrl != null
                                  ? NetworkImage(user!.profileImageUrl!)
                                  : null,
                              child: user?.profileImageUrl == null
                                  ? Icon(
                                      Icons.person,
                                      color: AppColors.textOnPrimary,
                                      size: 30,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textOnPrimary
                                              .withValues(alpha: 0.9),
                                        ),
                                  ),
                                  Text(
                                    'Dr. ${user?.fullName.split(' ').first ?? 'Doctor'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.textOnPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    _getCurrentTimeGreeting(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textOnPrimary
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _showNotificationsDialog();
                              },
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dashboard Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick stats
                    _buildStatsSection(),

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActionsSection(),

                    const SizedBox(height: 24),

                    // Today's appointments
                    _buildTodayAppointmentsSection(),

                    const SizedBox(height: 24),

                    // Recent activity
                    _buildRecentActivitySection(),

                    const SizedBox(height: 24),

                    // Performance insights
                    _buildPerformanceInsights(),

                    const SizedBox(
                      height: 100,
                    ), // Bottom padding for navigation
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Appointments',
                _stats['todayAppointments']?.toString() ?? '0',
                Icons.calendar_today,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Patients',
                _stats['totalPatients']?.toString() ?? '0',
                Icons.people,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Consultations',
                _stats['completedConsultations']?.toString() ?? '0',
                Icons.video_call,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Revenue',
                '₹${_stats['monthlyRevenue']?.toString() ?? '0'}',
                Icons.currency_rupee,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Start Consultation',
                onPressed: () {
                  _navigateToConsultation();
                },
                backgroundColor: AppColors.primary,
                textColor: AppColors.textOnPrimary,
                icon: Icons.video_call,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'View Schedule',
                onPressed: () {
                  _navigateToSchedule();
                },
                backgroundColor: AppColors.secondary,
                textColor: AppColors.textOnPrimary,
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Patient Records',
                onPressed: () {
                  _navigateToPatients();
                },
                backgroundColor: AppColors.info,
                textColor: AppColors.textOnPrimary,
                icon: Icons.folder_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Prescriptions',
                onPressed: () {
                  _navigateToPrescriptions();
                },
                backgroundColor: AppColors.success,
                textColor: AppColors.textOnPrimary,
                icon: Icons.receipt_long,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Appointments',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                _navigateToAppointments();
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_todayAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'No appointments today',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enjoy your free time!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayAppointments.length > 3
                ? 3
                : _todayAppointments.length,
            itemBuilder: (context, index) {
              final appointment = _todayAppointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          appointment.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatTime(appointment.appointmentDate)} • ${_getTypeDisplayText(appointment.consultationType)}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusDisplayText(appointment.status),
            style: TextStyle(
              color: _getStatusColor(appointment.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          _showAppointmentDetails(appointment);
        },
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'New patient registration',
                'John Doe registered for consultation',
                '2 hours ago',
                Icons.person_add,
              ),
              const Divider(),
              _buildActivityItem(
                'Consultation completed',
                'Video call with Sarah Smith',
                '4 hours ago',
                Icons.video_call,
              ),
              const Divider(),
              _buildActivityItem(
                'Prescription sent',
                'Prescription for Michael Johnson',
                '6 hours ago',
                Icons.receipt_long,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'in_progress':
      case 'inprogress':
        return AppColors.info;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
      case 'inprogress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status;
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getCurrentTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! Ready for today\'s consultations?';
    } else if (hour < 17) {
      return 'Good afternoon! How\'s your day going?';
    } else {
      return 'Good evening! Wrapping up for the day?';
    }
  }

  Widget _buildPerformanceInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Insights',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      'Patient Satisfaction',
                      '4.8/5.0',
                      Icons.star,
                      AppColors.warning,
                      '+0.2 from last month',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      'Response Time',
                      '< 5 min',
                      Icons.timer,
                      AppColors.success,
                      'Excellent',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      'Consultation Rate',
                      '95%',
                      Icons.trending_up,
                      AppColors.info,
                      '+5% this week',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      'Follow-ups',
                      '12',
                      Icons.repeat,
                      AppColors.primary,
                      'Pending',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationItem(
                'New appointment request',
                'John Doe requested an appointment for tomorrow',
                '2 minutes ago',
                Icons.calendar_today,
              ),
              const Divider(),
              _buildNotificationItem(
                'Consultation completed',
                'Video call with Sarah Smith completed',
                '1 hour ago',
                Icons.video_call,
              ),
              const Divider(),
              _buildNotificationItem(
                'Payment received',
                'Payment of ₹500 received from Michael Johnson',
                '3 hours ago',
                Icons.payment,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to all notifications
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _navigateToConsultation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorConsultationScreen()),
    );
  }

  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorScheduleScreen()),
    );
  }

  void _navigateToPatients() {
    ref.read(doctorNavigationProvider.notifier).goToPatients();
  }

  void _navigateToPrescriptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescriptions'),
        content: const Text('Prescription management feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToAppointments() {
    ref.read(doctorNavigationProvider.notifier).goToAppointments();
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ThemeUtils.getBackgroundColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeUtils.getTextSecondaryColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_formatTime(appointment.appointmentDate)} • ${_getTypeDisplayText(appointment.consultationType)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(appointment.status),
                  ],
                ),
              ),

              const Divider(),

              // Appointment details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (appointment.symptoms != null &&
                        appointment.symptoms!.isNotEmpty) ...[
                      _buildDetailSection('Symptoms', appointment.symptoms!),
                      const SizedBox(height: 16),
                    ],

                    _buildDetailSection(
                      'Appointment Time',
                      _formatTime(appointment.appointmentDate),
                    ),
                    const SizedBox(height: 16),

                    _buildDetailSection(
                      'Consultation Type',
                      _getTypeDisplayText(appointment.consultationType),
                    ),
                    const SizedBox(height: 16),

                    _buildDetailSection(
                      'Status',
                      _getStatusDisplayText(appointment.status),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Start Consultation',
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DoctorConsultationScreen(
                                        appointment: appointment,
                                      ),
                                ),
                              );
                            },
                            backgroundColor: AppColors.primary,
                            textColor: AppColors.textOnPrimary,
                            icon: Icons.video_call,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Reschedule',
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Implement reschedule
                            },
                            backgroundColor: AppColors.warning,
                            textColor: AppColors.textOnPrimary,
                            icon: Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
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
}
