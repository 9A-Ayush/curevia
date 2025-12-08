import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import 'meditation_screen.dart';

/// Mental Health Screen for wellness support and resources
class MentalHealthScreen extends StatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  State<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends State<MentalHealthScreen> {
  int _selectedMoodIndex = -1;

  final List<MoodOption> _moodOptions = [
    MoodOption('😊', 'Great', AppColors.success),
    MoodOption('🙂', 'Good', AppColors.info),
    MoodOption('😐', 'Okay', AppColors.warning),
    MoodOption('😔', 'Low', AppColors.error),
    MoodOption('😰', 'Anxious', AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Mental Health'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showMoodHistory();
            },
            tooltip: 'Mood History',
          ),
        ],
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology,
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
                            'Mental wellness support',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Track mood, meditate, and find peace',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
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
                    _buildInfoChip(Icons.self_improvement, 'Meditation'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.mood, 'Mood Tracking'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Mood Tracker
                  _buildMoodTracker(),
                  const SizedBox(height: 24),

                  // Quick Resources
                  _buildQuickResources(),
                  const SizedBox(height: 24),

                  // Wellness Tips
                  _buildWellnessTips(),
                  const SizedBox(height: 24),

                  // Emergency Support
                  _buildEmergencySupport(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTracker() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Mood Check-in',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Select how you\'re feeling right now:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moodOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final mood = entry.value;
                final isSelected = _selectedMoodIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMoodIndex = index;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mood "${mood.label}" recorded!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood.color.withValues(alpha: 0.2)
                          : ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? mood.color : AppColors.borderLight,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 2),
                        Text(
                          mood.label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? mood.color
                                    : ThemeUtils.getTextSecondaryColor(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Resources',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildResourceCard(
                'Breathing Exercise',
                Icons.air,
                AppColors.info,
                () {
                  _showBreathingExercise();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResourceCard(
                'Meditation',
                Icons.self_improvement,
                AppColors.success,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeditationScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWellnessTips() {
    final tips = [
      'Take regular breaks throughout your day',
      'Practice gratitude - write down 3 things you\'re thankful for',
      'Stay connected with friends and family',
      'Get enough sleep (7-9 hours per night)',
      'Exercise regularly to boost your mood',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.warning, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Wellness Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildEmergencySupport() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need Immediate Help?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'If you\'re having thoughts of self-harm or suicide, please reach out for help immediately.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildEmergencyContact(
              'National Mental Health Helpline',
              '1800-599-0019',
              Icons.phone,
              AppColors.error,
            ),
            const SizedBox(height: 8),
            _buildEmergencyContact(
              'Suicide Prevention Helpline',
              '9152987821',
              Icons.phone_in_talk,
              AppColors.error,
            ),
            const SizedBox(height: 8),
            _buildEmergencyContact(
              'AASRA (24/7 Support)',
              '9820466726',
              Icons.support_agent,
              AppColors.error,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEmergencyContactsDialog();
                },
                icon: const Icon(Icons.contacts),
                label: const Text('View All Emergency Contacts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(
    String name,
    String number,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _makePhoneCall(number),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    number,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.call, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    try {
      // Remove any spaces or special characters
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Show confirmation dialog
      final shouldCall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Call Emergency Helpline?'),
          content: Text('Do you want to call $phoneNumber?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call'),
            ),
          ],
        ),
      );

      if (shouldCall == true && mounted) {
        // TODO: Implement actual phone call using url_launcher
        // For now, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $phoneNumber...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEmergencyContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error),
            const SizedBox(width: 8),
            const Expanded(child: Text('Emergency Contacts')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogContact('National Mental Health Helpline', '1800-599-0019'),
              _buildDialogContact('Suicide Prevention Helpline', '9152987821'),
              _buildDialogContact('AASRA (24/7 Support)', '9820466726'),
              _buildDialogContact('Vandrevala Foundation', '1860-2662-345'),
              _buildDialogContact('iCall Helpline', '9152987821'),
              _buildDialogContact('Sneha Foundation', '044-24640050'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All helplines are available 24/7 and provide free, confidential support.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildDialogContact(String name, String number) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.phone, color: AppColors.error),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(number),
      trailing: IconButton(
        icon: Icon(Icons.call, color: AppColors.error),
        onPressed: () {
          Navigator.pop(context);
          _makePhoneCall(number);
        },
      ),
    );
  }

  void _showBreathingExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Breathing Exercise'),
        content: const Text(
          '1. Sit comfortably and close your eyes\n'
          '2. Breathe in slowly for 4 counts\n'
          '3. Hold your breath for 4 counts\n'
          '4. Breathe out slowly for 6 counts\n'
          '5. Repeat 5-10 times\n\n'
          'Focus on your breath and let go of any tension.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
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

  void _showMoodHistory() {
    // TODO: Fetch actual mood history from database
    final mockHistory = [
      {'date': 'Today, 10:30 AM', 'mood': '😊', 'label': 'Great'},
      {'date': 'Yesterday, 3:45 PM', 'mood': '🙂', 'label': 'Good'},
      {'date': 'Yesterday, 9:00 AM', 'mood': '😐', 'label': 'Okay'},
      {'date': '2 days ago, 2:15 PM', 'mood': '🙂', 'label': 'Good'},
      {'date': '3 days ago, 11:20 AM', 'mood': '😊', 'label': 'Great'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Mood History'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your mood has been mostly positive this week!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...mockHistory.map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ThemeUtils.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry['mood'] as String,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      entry['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(entry['date'] as String),
                  )),
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
}

class MoodOption {
  final String emoji;
  final String label;
  final Color color;

  MoodOption(this.emoji, this.label, this.color);
}
