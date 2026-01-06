import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../services/meditation_audio_service.dart';
import '../../providers/mood_provider.dart';
import '../../models/mood_model.dart' as mood_model;
import '../../widgets/mood_history_widget.dart';
import '../../utils/firestore_index_helper.dart';
import 'meditation_screen.dart';

/// Mental Health Screen for wellness support and resources
class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen> {
  mood_model.EmotionType? _selectedEmotion;
  final String _userId = 'current_user_id'; // TODO: Get from auth provider

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  /// Load initial mood data
  void _loadInitialData() {
    final moodNotifier = ref.read(moodTrackingProvider.notifier);
    moodNotifier.loadMoodHistory(userId: _userId);
    moodNotifier.loadMoodStatistics(userId: _userId);
    moodNotifier.checkTodaysMoodEntry(_userId);
  }

  // Simplified emotion options (3 emotions)
  final List<EmotionOption> _emotionOptions = [
    EmotionOption(
      type: mood_model.EmotionType.happy,
      emoji: '😊',
      label: 'Great',
      color: const Color(0xFF4CAF50),
    ),
    EmotionOption(
      type: mood_model.EmotionType.normal,
      emoji: '😐',
      label: 'Okay',
      color: const Color(0xFF2196F3),
    ),
    EmotionOption(
      type: mood_model.EmotionType.sad,
      emoji: '🙁',
      label: 'Sad',
      color: const Color(0xFF9C27B0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodTrackingProvider);
    
    // Listen to mood state changes
    ref.listen<MoodTrackingState>(moodTrackingProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(moodTrackingProvider.notifier).clearError();
      }
      
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(moodTrackingProvider.notifier).clearSuccessMessage();
      }
    });
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
                        color: Colors.white.withOpacity(0.2),
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
                                  color: Colors.white.withOpacity(0.9),
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

                  // Emotions Section
                  _buildEmotionsSection(),
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

  /// Build simplified emotions section with 3 emotions
  Widget _buildEmotionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Emotion selection row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _emotionOptions.map((emotion) {
                final isSelected = _selectedEmotion == emotion.type;
                return _buildEmotionButton(emotion, isSelected);
              }).toList(),
            ),
            
            // Supportive message
            if (_selectedEmotion != null) ...[
              const SizedBox(height: 16),
              _buildSupportiveMessage(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build individual emotion button
  Widget _buildEmotionButton(EmotionOption emotion, bool isSelected) {
    final moodColors = EmotionRecommendationEngine.getMoodColors(emotion.type);
    
    return GestureDetector(
      onTap: () => _onEmotionSelected(emotion.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: ResponsiveUtils.getResponsiveValue(
          context: context,
          mobile: 80.0,
          tablet: 90.0,
          desktop: 100.0,
        ),
        height: ResponsiveUtils.getResponsiveValue(
          context: context,
          mobile: 80.0,
          tablet: 90.0,
          desktop: 100.0,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? moodColors.background
              : ThemeUtils.getSurfaceColor(context),
          border: Border.all(
            color: isSelected 
                ? moodColors.primary
                : ThemeUtils.getSurfaceVariantColor(context),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: moodColors.primary.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emotion.emoji,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveValue(
                  context: context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              emotion.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? moodColors.primary
                    : ThemeUtils.getTextSecondaryColor(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: ResponsiveUtils.getResponsiveValue(
                  context: context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build supportive message based on selected emotion
  Widget _buildSupportiveMessage() {
    if (_selectedEmotion == null) return const SizedBox.shrink();
    
    final message = EmotionRecommendationEngine.getSupportiveMessage(_selectedEmotion!);
    final moodColors = EmotionRecommendationEngine.getMoodColors(_selectedEmotion!);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: moodColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: moodColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: moodColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: moodColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle emotion selection with meaningful interactions
  void _onEmotionSelected(mood_model.EmotionType emotion) async {
    setState(() {
      _selectedEmotion = emotion;
    });

    // Haptic feedback for responsive interaction
    HapticFeedback.lightImpact();

    // Save mood entry to database
    final moodNotifier = ref.read(moodTrackingProvider.notifier);
    final entryId = await moodNotifier.saveMoodEntry(
      userId: _userId,
      emotionType: emotion,
      metadata: {
        'source': 'mental_health_screen',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (entryId != null) {
      // Show recommendations after a brief delay
      Timer(const Duration(milliseconds: 800), () {
        _showEmotionRecommendations(emotion);
      });
    }
  }

  /// Show emotion-based recommendations
  void _showEmotionRecommendations(mood_model.EmotionType emotion) {
    final recommendations = EmotionRecommendationEngine.getMeditationRecommendations(emotion);
    final soundRecommendations = EmotionRecommendationEngine.getSoundRecommendations(emotion);
    final moodColors = EmotionRecommendationEngine.getMoodColors(emotion);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: moodColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: moodColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Personalized Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Text(
              'Recommended Meditations:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: moodColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: moodColors.primary),
                  const SizedBox(width: 8),
                  Text(rec, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )),
            
            const SizedBox(height: 16),
            
            Text(
              'Recommended Sounds:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: moodColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...soundRecommendations.map((sound) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.music_note, size: 16, color: moodColors.primary),
                  const SizedBox(width: 8),
                  Text(sound, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: moodColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Got it!'),
              ),
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
                  color: color.withOpacity(0.1),
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
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
        // Launch phone dialer with the number
        final uri = Uri(scheme: 'tel', path: cleanNumber);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not launch phone app'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
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
                  color: AppColors.info.withOpacity(0.1),
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
        title: Row(
          children: [
            Icon(Icons.air, color: AppColors.info, size: 24),
            const SizedBox(width: 8),
            const Text('Breathing Exercise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4-7-8 Breathing Technique',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Sit comfortably and close your eyes\n'
              '2. Breathe in slowly for 4 counts\n'
              '3. Hold your breath for 7 counts\n'
              '4. Breathe out slowly for 8 counts\n'
              '5. Repeat 5-10 times\n',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Focus on your breath and let go of any tension. This technique helps reduce anxiety and promote relaxation.',
                      style: TextStyle(fontSize: 13),
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
            child: Text(
              'Maybe Later',
              style: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to meditation screen and switch to breathing tab
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeditationScreen(initialTabIndex: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text(
              "Let's Go",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mood History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: MoodHistoryWidget(
                    userId: _userId,
                    limit: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emotion option data class
class EmotionOption {
  final mood_model.EmotionType type;
  final String emoji;
  final String label;
  final Color color;

  const EmotionOption({
    required this.type,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

/// Emotion mood colors for UI adaptation
class EmotionMoodColors {
  final Color primary;
  final Color background;
  final Color accent;

  const EmotionMoodColors({
    required this.primary,
    required this.background,
    required this.accent,
  });
}

/// Emotion-based recommendation engine
class EmotionRecommendationEngine {
  /// Get meditation recommendations based on emotion
  static List<String> getMeditationRecommendations(mood_model.EmotionType emotion) {
    switch (emotion) {
      case mood_model.EmotionType.happy:
        return [
          'Gratitude Meditation',
          'Loving Kindness',
          'Mindful Breathing',
        ];
      case mood_model.EmotionType.normal:
        return [
          'Mindful Breathing',
          'Body Scan',
          'Focus Meditation',
        ];
      case mood_model.EmotionType.sad:
        return [
          'Self-Compassion',
          'Loving Kindness',
          'Gentle Breathing',
        ];
    }
  }

  /// Get sound recommendations based on emotion
  static List<String> getSoundRecommendations(mood_model.EmotionType emotion) {
    switch (emotion) {
      case mood_model.EmotionType.happy:
        return [
          'Birds',
          'Ocean Waves',
          'Wind Chimes',
        ];
      case mood_model.EmotionType.normal:
        return [
          'Rain',
          'Forest',
          'White Noise',
        ];
      case mood_model.EmotionType.sad:
        return [
          'Om',
          'Singing Bowls',
          'Piano Meditation',
        ];
    }
  }

  /// Get supportive message based on emotion
  static String getSupportiveMessage(mood_model.EmotionType emotion) {
    switch (emotion) {
      case mood_model.EmotionType.happy:
        return "Wonderful! Let's maintain this positive energy with some uplifting meditation.";
      case mood_model.EmotionType.normal:
        return "Perfect time for mindfulness. Let's find your center with gentle meditation.";
      case mood_model.EmotionType.sad:
        return "It's okay to feel this way. Let's nurture yourself with some compassionate meditation.";
    }
  }

  /// Get UI mood colors based on emotion
  static EmotionMoodColors getMoodColors(mood_model.EmotionType emotion) {
    switch (emotion) {
      case mood_model.EmotionType.happy:
        return EmotionMoodColors(
          primary: const Color(0xFF4CAF50), // Green
          background: const Color(0xFFF1F8E9), // Light green
          accent: const Color(0xFF8BC34A),
        );
      case mood_model.EmotionType.normal:
        return EmotionMoodColors(
          primary: const Color(0xFF2196F3), // Blue
          background: const Color(0xFFE3F2FD), // Light blue
          accent: const Color(0xFF64B5F6),
        );
      case mood_model.EmotionType.sad:
        return EmotionMoodColors(
          primary: const Color(0xFF9C27B0), // Purple
          background: const Color(0xFFF3E5F5), // Light purple
          accent: const Color(0xFFBA68C8),
        );
    }
  }
}
