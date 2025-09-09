import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../screens/consultation/video_consultation_screen.dart';
import '../../screens/doctor/doctor_search_screen.dart';
import '../../screens/health/symptom_checker_screen.dart';
import '../../screens/health/medicine_directory_screen.dart';
import '../../screens/health/home_remedies_screen.dart';
import '../../screens/emergency/emergency_screen.dart';
import '../../screens/appointment/appointments_screen.dart';
import '../../screens/profile/medical_records_screen.dart';
import '../../screens/fitness/fitness_tracker_screen.dart';
import '../../screens/mental_health/mental_health_screen.dart';

/// Quick actions grid for home screen
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickAction(
        icon: Icons.video_call,
        label: 'Video Call',
        color: AppColors.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VideoConsultationScreen(),
            ),
          );
        },
      ),
      QuickAction(
        icon: Icons.location_on,
        label: 'Find Doctors',
        color: AppColors.secondary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DoctorSearchScreen()),
          );
        },
      ),
      QuickAction(
        icon: Icons.medical_services,
        label: 'Symptoms',
        color: AppColors.accent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SymptomCheckerScreen(),
            ),
          );
        },
      ),
      QuickAction(
        icon: Icons.local_pharmacy,
        label: 'Medicines',
        color: AppColors.success,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MedicineDirectoryScreen(),
            ),
          );
        },
      ),
      QuickAction(
        icon: Icons.spa,
        label: 'Remedies',
        color: AppColors.medicineCategory,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeRemediesScreen()),
          );
        },
      ),
      QuickAction(
        icon: Icons.emergency,
        label: 'Emergency',
        color: AppColors.error,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyScreen()),
          );
        },
      ),
      QuickAction(
        icon: Icons.calendar_today,
        label: 'Appointments',
        color: AppColors.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
          );
        },
      ),
      QuickAction(
        icon: Icons.more_horiz,
        label: 'More',
        color: AppColors.textSecondary,
        onTap: () {
          _showMoreOptions(context);
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return QuickActionItem(action: action);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: ThemeUtils.getBorderMediumColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More Options',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMoreOption(
                    context,
                    icon: Icons.health_and_safety,
                    title: 'Medical Records',
                    subtitle: 'Manage your medical records',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicalRecordsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMoreOption(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Fitness Tracker',
                    subtitle: 'Track your daily activities',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FitnessTrackerScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMoreOption(
                    context,
                    icon: Icons.psychology,
                    title: 'Mental Health',
                    subtitle: 'Mental wellness support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MentalHealthScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMoreOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceVariantColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ThemeUtils.getPrimaryColor(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
            ),
            Icon(
              Icons.chevron_right,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action item widget
class QuickActionItem extends StatelessWidget {
  final QuickAction action;

  const QuickActionItem({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ThemeUtils.getShadowLightColor(context),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action model
class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Animated quick action item with hover effect
class AnimatedQuickActionItem extends StatefulWidget {
  final QuickAction action;

  const AnimatedQuickActionItem({super.key, required this.action});

  @override
  State<AnimatedQuickActionItem> createState() =>
      _AnimatedQuickActionItemState();
}

class _AnimatedQuickActionItemState extends State<AnimatedQuickActionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.action.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ThemeUtils.getShadowLightColor(context),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.action.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.action.icon,
                      color: widget.action.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.action.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Expandable quick actions section
class ExpandableQuickActions extends StatefulWidget {
  const ExpandableQuickActions({super.key});

  @override
  State<ExpandableQuickActions> createState() => _ExpandableQuickActionsState();
}

class _ExpandableQuickActionsState extends State<ExpandableQuickActions> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final primaryActions = [
      QuickAction(
        icon: Icons.video_call,
        label: 'Video Call',
        color: AppColors.primary,
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.location_on,
        label: 'Find Doctors',
        color: AppColors.secondary,
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.medical_services,
        label: 'Symptoms',
        color: AppColors.accent,
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.local_pharmacy,
        label: 'Medicines',
        color: AppColors.success,
        onTap: () {},
      ),
    ];

    final secondaryActions = [
      QuickAction(
        icon: Icons.spa,
        label: 'Remedies',
        color: AppColors.medicineCategory,
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.emergency,
        label: 'Emergency',
        color: AppColors.error,
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.calendar_today,
        label: 'Appointments',
        color: AppColors.info,
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.health_and_safety,
        label: 'Health Tips',
        color: AppColors.warning,
        onTap: () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Less' : 'More',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: ThemeUtils.getPrimaryColor(context),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: primaryActions.length,
          itemBuilder: (context, index) {
            final action = primaryActions[index];
            return AnimatedQuickActionItem(action: action);
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? null : 0,
          child: _isExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                      itemCount: secondaryActions.length,
                      itemBuilder: (context, index) {
                        final action = secondaryActions[index];
                        return AnimatedQuickActionItem(action: action);
                      },
                    ),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
