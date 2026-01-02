import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/video_consulting_service.dart';
import '../video_call/video_call_screen.dart';

/// Appointment detail screen for patients
class AppointmentDetailScreen extends ConsumerWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDoctorInfo(context),
            _buildAppointmentInfo(context),
            if (appointment.symptoms != null) _buildSymptoms(context),
            if (appointment.notes != null) _buildNotes(context),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.doctorSpecialty,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Date & Time',
            appointment.formattedDateTime,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            appointment.consultationType == 'online'
                ? Icons.video_call
                : Icons.local_hospital,
            'Type',
            appointment.consultationTypeText,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.info_outline,
            'Status',
            appointment.status.toUpperCase(),
            valueColor: _getStatusColor(appointment.status),
          ),
          if (appointment.consultationFee != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.payment,
              'Consultation Fee',
              appointment.formattedFee,
              valueColor: AppColors.primary,
            ),
          ],
          if (appointment.meetingId != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.meeting_room,
              'Meeting ID',
              appointment.meetingId!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptoms(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Symptoms',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appointment.symptoms!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Additional Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appointment.notes!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Join Video Call button (for online consultations)
          if (appointment.consultationType == 'online' &&
              appointment.status == 'confirmed' &&
              appointment.isToday)
            CustomButton(
              text: 'Join Video Call',
              icon: Icons.video_call,
              onPressed: () => _joinVideoCall(context, ref),
              backgroundColor: AppColors.secondary,
            ),
          
          // Cancel button
          if (appointment.canBeCancelled) ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'Cancel Appointment',
              icon: Icons.cancel,
              onPressed: () => _showCancelDialog(context, ref),
              backgroundColor: AppColors.error,
            ),
          ],
          
          // Reschedule button
          if (appointment.canBeRescheduled) ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'Reschedule',
              icon: Icons.schedule,
              onPressed: () => _showRescheduleDialog(context, ref),
              backgroundColor: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _joinVideoCall(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create or get video call session
      final videoCall = await VideoConsultingService.createVideoCallSession(
        appointment.id,
      );

      // Close loading
      if (context.mounted) Navigator.pop(context);

      if (videoCall == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create video call session'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Navigate to video call screen
      if (context.mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: videoCall.roomId,
              token: videoCall.accessToken ?? '',
              uid: DateTime.now().millisecondsSinceEpoch % 100000,
              doctorName: appointment.doctorName,
              patientName: appointment.patientName,
            ),
          ),
        );

        // Handle call completion
        if (result != null && result['completed'] == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call completed successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserModelProvider);
              if (user != null) {
                await ref.read(appointmentsListProvider.notifier).cancelAppointment(
                  appointmentId: appointment.id,
                  cancellationReason: reasonController.text.trim(),
                  cancelledBy: 'patient',
                );
                
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment cancelled successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text('Rescheduling feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
