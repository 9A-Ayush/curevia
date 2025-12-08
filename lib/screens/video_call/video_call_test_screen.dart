import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'video_call_screen.dart';

/// Test screen for video calling feature
class VideoCallTestScreen extends StatefulWidget {
  const VideoCallTestScreen({super.key});

  @override
  State<VideoCallTestScreen> createState() => _VideoCallTestScreenState();
}

class _VideoCallTestScreenState extends State<VideoCallTestScreen> {
  final TextEditingController _channelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default values
    _channelController.text = 'test-channel-${DateTime.now().millisecondsSinceEpoch}';
    _nameController.text = 'User ${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _channelController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startVideoCall() {
    if (_channelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a channel name')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelName: _channelController.text,
          token: '', // Empty for testing without token
          uid: 0, // 0 for auto-generated UID
          patientName: _nameController.text.isNotEmpty 
              ? _nameController.text 
              : 'Test User',
        ),
      ),
    ).then((result) {
      if (result != null && result is Map) {
        final duration = result['duration'] as int;
        final completed = result['completed'] as bool;
        
        if (completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Call ended. Duration: ${_formatDuration(duration)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Video Call'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Video Call Test',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Use the same channel name on 2 devices to connect\n'
                    '• Make sure camera and microphone permissions are granted\n'
                    '• Test on real devices (not emulators)\n'
                    '• This uses test mode (no token required)',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Channel name input
            CustomTextField(
              controller: _channelController,
              labelText: 'Channel Name',
              hintText: 'Enter channel name',
              prefixIcon: Icons.tag,
            ),

            const SizedBox(height: 16),

            // User name input
            CustomTextField(
              controller: _nameController,
              labelText: 'Your Name',
              hintText: 'Enter your name',
              prefixIcon: Icons.person,
            ),

            const SizedBox(height: 32),

            // Start call button
            CustomButton(
              text: 'Start Video Call',
              onPressed: _startVideoCall,
              icon: Icons.video_call,
              backgroundColor: AppColors.primary,
              textColor: AppColors.textOnPrimary,
            ),

            const SizedBox(height: 16),

            // Generate new channel button
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _channelController.text = 
                      'test-channel-${DateTime.now().millisecondsSinceEpoch}';
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Generate New Channel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            Container(
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
                    'How to Test:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    '1',
                    'Copy the channel name',
                  ),
                  _buildInstructionStep(
                    '2',
                    'Open this screen on another device',
                  ),
                  _buildInstructionStep(
                    '3',
                    'Paste the same channel name',
                  ),
                  _buildInstructionStep(
                    '4',
                    'Click "Start Video Call" on both devices',
                  ),
                  _buildInstructionStep(
                    '5',
                    'Wait a few seconds to connect',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Agora credentials info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agora Configured',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'App ID: 4b3b532c937c4879b23ac5c34bdf85d5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
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

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
