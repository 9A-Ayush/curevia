import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/appointment_model.dart';

/// Doctor consultation screen for video calls and consultations
class DoctorConsultationScreen extends ConsumerStatefulWidget {
  final AppointmentModel? appointment;

  const DoctorConsultationScreen({super.key, this.appointment});

  @override
  ConsumerState<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState
    extends ConsumerState<DoctorConsultationScreen> {
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isCallActive = false;
  bool _isScreenSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Text(
          widget.appointment?.patientName ?? 'Video Consultation',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show consultation info
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main video area
          _buildMainVideoArea(),

          // Patient info overlay
          if (widget.appointment != null) _buildPatientInfoOverlay(),

          // Control buttons
          _buildControlButtons(),

          // Side panel for notes (if needed)
          if (_isCallActive) _buildNotesPanel(),
        ],
      ),
    );
  }

  Widget _buildMainVideoArea() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: _isCallActive
          ? Stack(
              children: [
                // Patient video (main)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Patient video will appear here',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                // Doctor video (small overlay)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _isVideoOn
                        ? const Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.videocam_off,
                              size: 40,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
              ],
            )
          : _buildWaitingArea(),
    );
  }

  Widget _buildWaitingArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Icon(Icons.person, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            widget.appointment?.patientName ?? 'Patient',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Waiting for patient to join...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Start Call',
            onPressed: () {
              setState(() {
                _isCallActive = true;
              });
            },
            backgroundColor: AppColors.success,
            textColor: Colors.white,
            icon: Icons.videocam,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoOverlay() {
    return Positioned(
      top: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.appointment!.patientName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.appointment!.symptoms != null) ...[
              const SizedBox(height: 4),
              Text(
                'Symptoms: ${widget.appointment!.symptoms}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
              });
            },
            backgroundColor: _isMuted ? AppColors.error : Colors.white24,
          ),

          // Video button
          _buildControlButton(
            icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
            onPressed: () {
              setState(() {
                _isVideoOn = !_isVideoOn;
              });
            },
            backgroundColor: !_isVideoOn ? AppColors.error : Colors.white24,
          ),

          // Screen share button
          _buildControlButton(
            icon: _isScreenSharing
                ? Icons.stop_screen_share
                : Icons.screen_share,
            onPressed: () {
              setState(() {
                _isScreenSharing = !_isScreenSharing;
              });
            },
            backgroundColor: _isScreenSharing ? AppColors.info : Colors.white24,
          ),

          // Chat button
          _buildControlButton(
            icon: Icons.chat,
            onPressed: () {
              // TODO: Open chat
            },
            backgroundColor: Colors.white24,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            onPressed: () {
              _showEndCallDialog();
            },
            backgroundColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildNotesPanel() {
    return Positioned(
      right: 0,
      top: 100,
      bottom: 150,
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consultation Notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Add your consultation notes here...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Save Notes',
                    onPressed: () {
                      // TODO: Save consultation notes
                    },
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Consultation'),
        content: const Text('Are you sure you want to end this consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close consultation screen
            },
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}
