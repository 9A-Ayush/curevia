import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/quick_actions_grid.dart';
import '../../widgets/home/upcoming_appointments.dart';
import '../../widgets/home/health_tips_carousel.dart';
import '../../widgets/home/health_metrics_card.dart';
import '../../widgets/home/nearby_doctors.dart';
import '../../widgets/home/recent_activity.dart' as widgets;
import '../../screens/consultation/video_consultation_screen.dart';
import '../../screens/patient/find_doctors_screen.dart';
import '../../screens/emergency/emergency_screen.dart';

/// Home screen - main dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load home data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadHomeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserModelProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header with greeting and notifications
              SliverToBoxAdapter(
                child: HomeHeader(
                  userName: _getUserDisplayName(userModel),
                  userRole: userModel?.role ?? AppConstants.patientRole,
                ),
              ),

              // Quick Actions Grid
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: QuickActionsGrid(),
                ),
              ),

              // Emergency Banner (if needed)
              SliverToBoxAdapter(child: _buildEmergencyBanner()),

              // Health Metrics Card (with real backend data)
              const SliverToBoxAdapter(child: HealthMetricsCard()),

              // Upcoming Appointments
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: UpcomingAppointments(),
                ),
              ),

              // Health Tips Carousel
              const SliverToBoxAdapter(child: HealthTipsCarousel()),

              // Nearby Doctors
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: NearbyDoctors(),
                ),
              ),

              // Recent Activity
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: widgets.RecentActivity(),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showQuickBooking(context);
        },
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        icon: const Icon(Icons.add),
        label: const Text('Book Now'),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(homeProvider.notifier).refreshData();
  }

  /// Get user display name with fallback to Firebase displayName
  String _getUserDisplayName(UserModel? userModel) {
    // If userModel has a non-empty fullName, use it
    if (userModel != null && userModel.fullName.isNotEmpty) {
      return userModel.fullName;
    }

    // Fallback to Firebase user displayName
    final firebaseUser = ref.read(currentUserProvider);
    if (firebaseUser?.displayName?.isNotEmpty == true) {
      // If we have Firebase displayName but empty fullName, trigger a fix
      if (userModel != null) {
        _fixUserNameInBackground(userModel, firebaseUser!.displayName!);
      }
      return firebaseUser!.displayName!;
    }

    // Final fallback
    return 'User';
  }

  /// Fix user name in background without blocking UI
  void _fixUserNameInBackground(UserModel userModel, String displayName) {
    Future.microtask(() async {
      try {
        await ref
            .read(authProvider.notifier)
            .updateUserProfile(
              additionalData: {
                'fullName': displayName,
                'updatedAt': DateTime.now(),
              },
            );
      } catch (e) {
        // Silently handle error - this is a background fix
      }
    });
  }

  Widget _buildEmergencyBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.error, Color(0xFFFF6B6B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: AppColors.textOnPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Get immediate medical help',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: 'Call ${AppConstants.emergencyNumber}',
            onPressed: () => _makeEmergencyCall(AppConstants.emergencyNumber),
            backgroundColor: AppColors.textOnPrimary,
            textColor: AppColors.error,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ],
      ),
    );
  }



  void _showQuickBooking(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
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
                    'Quick Booking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildQuickBookingOption(
                    icon: Icons.video_call,
                    title: 'Video Consultation',
                    subtitle: 'Connect with doctors online',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VideoConsultationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickBookingOption(
                    icon: Icons.location_on,
                    title: 'In-Person Visit',
                    subtitle: 'Book appointment at clinic',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindDoctorsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickBookingOption(
                    icon: Icons.emergency,
                    title: 'Emergency Consultation',
                    subtitle: 'Immediate medical attention',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyScreen(),
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

  Widget _buildQuickBookingOption({
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

  /// Make emergency call
  Future<void> _makeEmergencyCall(String number) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone dialer for $number'),
              backgroundColor: ThemeUtils.getErrorColor(context),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
          ),
        );
      }
    }
  }
}
