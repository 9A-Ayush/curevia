import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/video_consulting_service.dart';
import '../video_call/video_call_screen.dart';

/// Video call waiting room screen
class VideoCallWaitingScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const VideoCallWaitingScreen({super.key, required this.appointment});

  @override
  ConsumerState<VideoCallWaitingScreen> createState() => _VideoCallWaitingScreenState();
}

class _VideoCallWaitingScreenState extends ConsumerState<VideoCallWaitingScreen> {
  bool _isConnecting = false;
  Timer? _countdownTimer;
  int _secondsUntilStart = 0;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilStart();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _calculateTimeUntilStart() {
    final now = DateTime.now();
    final appointmentTime = widget.appointment.appointmentDate;
    
    if (appointmentTime.isAfter(now)) {
      _secondsUntilStart = appointmentTime.difference(now).inSeconds;
      
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsUntilStart > 0) {
            _secondsUntilStart--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  String _formatCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canJoin = _secondsUntilStart <= 300; // Can join 5 minutes before

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Consultation'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Doctor Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person, size: 60, color: AppColors.primary),
            ),
            
            const SizedBox(height: 20),
            
            // Doctor Name
            Text(
              widget.appointment.doctorName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Specialty
            Text(
              widget.appointment.doctorSpecialty,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Appointment Time
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.appointment.formattedDateTime,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_secondsUntilStart > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Starts in',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCountdown(_secondsUntilStart),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            _buildInstructions(),
            
            const SizedBox(height: 32),
            
            // Join Button
            if (canJoin)
              CustomButton(
                text: _isConnecting ? 'Connecting...' : 'Join Video Call',
                icon: Icons.video_call,
                onPressed: _isConnecting ? null : _joinCall,
                isLoading: _isConnecting,
                backgroundColor: AppColors.secondary,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can join the call 5 minutes before the scheduled time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                        ),
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

  Widget _buildInstructions() {
    return Container(
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
            'Before you join:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('Ensure you have a stable internet connection'),
          _buildInstructionItem('Find a quiet, well-lit place'),
          _buildInstructionItem('Keep your medical records ready'),
          _buildInstructionItem('Test your camera and microphone'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinCall() async {
    setState(() => _isConnecting = true);

    try {
      // Create or get video call session
      final videoCall = await VideoConsultingService.createVideoCallSession(
        widget.appointment.id,
      );

      if (videoCall == null) {
        throw Exception('Failed to create video call session');
      }

      if (!mounted) return;

      // Navigate to video call screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: videoCall.roomId,
            token: videoCall.accessToken ?? '',
            uid: DateTime.now().millisecondsSinceEpoch % 100000,
            doctorName: widget.appointment.doctorName,
            patientName: widget.appointment.patientName,
          ),
        ),
      );

      if (!mounted) return;

      // Handle call completion
      if (result != null && result['completed'] == true) {
        Navigator.pop(context); // Go back to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
}
