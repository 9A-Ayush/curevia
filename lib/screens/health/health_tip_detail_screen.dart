import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/common/custom_button.dart';

/// Health tip detail screen
class HealthTipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tip;

  const HealthTipDetailScreen({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: ResponsiveUtils.centerContent(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildContent(context),
                  _buildBenefits(context),
                  _buildTips(context),
                  _buildRelatedTips(context),
                  _buildActionButtons(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final color = tip['color'] as Color? ?? AppColors.primary;
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          tip['title'] as String? ?? 'Health Tip',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              tip['icon'] as IconData? ?? Icons.health_and_safety,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _shareHealthTip(context),
          icon: const Icon(Icons.share),
        ),
        IconButton(
          onPressed: () => _bookmarkHealthTip(context),
          icon: const Icon(Icons.bookmark_border),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (tip['color'] as Color? ?? AppColors.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tip['category'] as String? ?? 'Health & Wellness',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tip['color'] as Color? ?? AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                size: 16,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              const SizedBox(width: 4),
              Text(
                tip['readTime'] as String? ?? '3 min read',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tip['description'] as String? ??
                'Learn about this important health tip and how it can improve your wellbeing.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final content = tip['fullContent'] as String? ?? _getDefaultContent();
    
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    final benefits = tip['benefits'] as List<String>? ?? _getDefaultBenefits();
    
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Key Benefits',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => _buildBenefitItem(context, benefit)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: (tip['color'] as Color? ?? AppColors.success)
                  .withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: tip['color'] as Color? ?? AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips(BuildContext context) {
    final tips = tip['tips'] as List<String>? ?? _getDefaultTips();
    
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'How to Get Started',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.asMap().entries.map((entry) {
            return _buildTipItem(context, entry.key + 1, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, int number, String tipText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tip['color'] as Color? ?? AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tipText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedTips(BuildContext context) {
    final relatedTips = _getRelatedTips();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.getResponsiveHorizontalPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Related Tips',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: ResponsiveUtils.getResponsiveHorizontalPadding(context),
            itemCount: relatedTips.length,
            itemBuilder: (context, index) {
              final relatedTip = relatedTips[index];
              return _buildRelatedTipCard(context, relatedTip);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedTipCard(BuildContext context, Map<String, dynamic> relatedTip) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HealthTipDetailScreen(tip: relatedTip),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              relatedTip['color'] as Color,
              (relatedTip['color'] as Color).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              relatedTip['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
            const Spacer(),
            Text(
              relatedTip['title'] as String,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Enhanced Set Reminder Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (tip['color'] as Color? ?? AppColors.primary).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomButton(
              text: 'Set Daily Reminder',
              onPressed: () {
                print('Set Reminder button pressed'); // Debug output
                _setReminder(context);
              },
              icon: Icons.notifications_outlined,
              backgroundColor: tip['color'] as Color? ?? AppColors.primary,
              textColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              print('Share button pressed'); // Debug output
              _shareHealthTip(context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share with Friends'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(
                color: tip['color'] as Color? ?? AppColors.primary,
                width: 1.5,
              ),
              foregroundColor: tip['color'] as Color? ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _shareHealthTip(BuildContext context) {
    final title = tip['title'] as String? ?? 'Health Tip';
    final description = tip['description'] as String? ?? '';
    Share.share(
      '$title\n\n$description\n\nShared from Curevia Health App',
      subject: title,
    );
  }

  void _bookmarkHealthTip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health tip bookmarked!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setReminder(BuildContext context) {
    // Add haptic feedback to confirm button press
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: tip['color'] as Color? ?? AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Text('Set Health Reminder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get daily reminders for: "${tip['title']}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (tip['color'] as Color? ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: tip['color'] as Color? ?? AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Daily at 9:00 AM',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              
              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Daily reminder set for "${tip['title']}"',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View Settings',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to notification settings
                      _showNotificationSettings(context);
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Set Reminder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tip['color'] as Color? ?? AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Health Tips Reminders'),
              subtitle: const Text('Daily health tips at 9:00 AM'),
              value: true,
              onChanged: (value) {
                // Handle notification toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                        ? 'Health reminders enabled' 
                        : 'Health reminders disabled',
                    ),
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Appointment Reminders'),
              subtitle: const Text('Upcoming appointment notifications'),
              value: true,
              onChanged: (value) {
                // Handle appointment notifications
              },
            ),
            SwitchListTile(
              title: const Text('Wellness Check-ins'),
              subtitle: const Text('Weekly wellness reminders'),
              value: false,
              onChanged: (value) {
                // Handle wellness notifications
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

  String _getDefaultContent() {
    final title = tip['title'] as String? ?? '';
    if (title.contains('Hydrated')) {
      return 'Staying properly hydrated is essential for maintaining good health. Water plays a crucial role in nearly every bodily function, from regulating body temperature to transporting nutrients and oxygen to cells. Drinking adequate water throughout the day helps maintain energy levels, supports cognitive function, and promotes healthy skin. Most adults should aim for 8-10 glasses of water daily, though individual needs may vary based on activity level, climate, and overall health.';
    } else if (title.contains('Exercise')) {
      return 'Regular physical activity is one of the most important things you can do for your health. Exercise strengthens your heart, improves circulation, helps maintain a healthy weight, and boosts mental health. Just 30 minutes of moderate exercise most days of the week can significantly reduce your risk of chronic diseases, improve sleep quality, and enhance overall quality of life. Find activities you enjoy to make exercise a sustainable part of your routine.';
    } else if (title.contains('Eat')) {
      return 'A balanced diet rich in fruits, vegetables, whole grains, and lean proteins provides your body with essential nutrients for optimal function. Eating a variety of colorful fruits and vegetables ensures you get a wide range of vitamins, minerals, and antioxidants. Limit processed foods, added sugars, and excessive salt. Remember, good nutrition is not about strict limitations but about feeling great, having more energy, and improving your health.';
    } else if (title.contains('Sleep')) {
      return 'Quality sleep is fundamental to good health and wellbeing. During sleep, your body repairs tissues, consolidates memories, and regulates hormones. Adults typically need 7-9 hours of sleep per night. Establish a consistent sleep schedule, create a relaxing bedtime routine, and ensure your bedroom is dark, quiet, and cool. Avoid screens before bedtime and limit caffeine in the afternoon and evening.';
    }
    return 'This health tip provides valuable information to help you maintain and improve your overall wellbeing. Following these guidelines can lead to better health outcomes and improved quality of life.';
  }

  List<String> _getDefaultBenefits() {
    return [
      'Improves overall health and wellbeing',
      'Boosts energy levels throughout the day',
      'Enhances mental clarity and focus',
      'Supports immune system function',
      'Reduces risk of chronic diseases',
    ];
  }

  List<String> _getDefaultTips() {
    return [
      'Start small and build gradually - consistency is more important than intensity',
      'Set realistic goals and track your progress to stay motivated',
      'Make it a daily habit by incorporating it into your routine',
      'Stay patient and remember that lasting change takes time',
    ];
  }

  List<Map<String, dynamic>> _getRelatedTips() {
    return [
      {
        'title': 'Healthy Eating Habits',
        'icon': Icons.restaurant,
        'color': AppColors.warning,
      },
      {
        'title': 'Better Sleep Quality',
        'icon': Icons.bedtime,
        'color': AppColors.secondary,
      },
      {
        'title': 'Stress Management',
        'icon': Icons.self_improvement,
        'color': AppColors.info,
      },
    ];
  }
}
