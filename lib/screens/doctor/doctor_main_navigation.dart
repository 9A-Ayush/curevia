import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/navigation/custom_bottom_navigation_bar.dart';
import '../../providers/doctor_navigation_provider.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_analytics_screen.dart';
import 'doctor_profile_screen.dart';

/// Main navigation for doctor interface with swipe support
class DoctorMainNavigation extends ConsumerStatefulWidget {
  const DoctorMainNavigation({super.key});

  @override
  ConsumerState<DoctorMainNavigation> createState() =>
      _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends ConsumerState<DoctorMainNavigation>
    with TickerProviderStateMixin {
  DateTime? _lastBackPressed;
  late PageController _pageController;
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeAnimation;
  
  final List<Widget> _screens = [
    const DoctorDashboardScreen(),
    const DoctorAppointmentsScreen(),
    const DoctorPatientsScreen(),
    const DoctorAnalyticsScreen(),
    const DoctorProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Appointments',
    ),
    NavigationItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Patients',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analytics',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _swipeAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final currentIndex = ref.read(doctorNavigationProvider);
    
    // If not on dashboard tab, go to dashboard first
    if (currentIndex != 0) {
      _navigateToPage(0);
      return false;
    }
    
    // Double tap to exit logic
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Press back again to exit'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: ThemeUtils.getPrimaryColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    }
    
    // Exit the app
    SystemNavigator.pop();
    return true;
  }

  void _navigateToPage(int index) {
    if (index >= 0 && index < _screens.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(doctorNavigationProvider.notifier).setTabIndex(index);
      
      // Trigger swipe animation for visual feedback
      _swipeAnimationController.forward().then((_) {
        _swipeAnimationController.reverse();
      });
    }
  }

  void _onPageChanged(int index) {
    ref.read(doctorNavigationProvider.notifier).setTabIndex(index);
    
    // Haptic feedback for page changes
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(doctorNavigationProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ThemeUtils.getBackgroundColor(context),
        body: Column(
          children: [
            // Swipe indicator (optional visual feedback)
            AnimatedBuilder(
              animation: _swipeAnimation,
              builder: (context, child) {
                return Container(
                  height: 2,
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: _swipeAnimation.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
            
            // Main content with swipe navigation
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _screens.length,
                itemBuilder: (context, index) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _screens[index],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _navigateToPage,
          items: _navigationItems,
        ),
      ),
    );
  }
}
