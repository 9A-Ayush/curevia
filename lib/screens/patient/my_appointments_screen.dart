import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'appointment_detail_screen.dart';

/// My appointments screen for patients
class MyAppointmentsScreen extends ConsumerStatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  ConsumerState<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends ConsumerState<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _loadAppointments() {
    final user = ref.read(currentUserModelProvider);
    if (user != null) {
      ref.read(appointmentsListProvider.notifier).loadUserAppointments(
        userId: user.uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.6),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(['pending', 'confirmed']),
          _buildAppointmentsList(['completed']),
          _buildAppointmentsList(['cancelled']),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<String> statuses) {
    final appointmentsState = ref.watch(appointmentsListProvider);

    if (appointmentsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointmentsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading appointments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              appointmentsState.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Retry',
              onPressed: _loadAppointments,
            ),
          ],
        ),
      );
    }

    final filteredAppointments = appointmentsState.appointments
        .where((apt) => statuses.contains(apt.status))
        .toList();

    filteredAppointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAppointmentCard(appointment),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailScreen(appointment: appointment),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.doctorSpecialty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(appointment.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  appointment.formattedDateTime,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  appointment.consultationType == 'online'
                      ? Icons.video_call
                      : Icons.local_hospital,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.consultationTypeText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (appointment.consultationFee != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    appointment.formattedFee,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        break;
      case 'confirmed':
        color = AppColors.info;
        text = 'Confirmed';
        break;
      case 'completed':
        color = AppColors.success;
        text = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
