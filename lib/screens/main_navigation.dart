import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:curevia/providers/auth_provider.dart';
import 'package:curevia/providers/navigation_provider.dart';
import 'package:curevia/providers/rating_provider.dart';
import 'package:curevia/utils/theme_utils.dart';
import 'home/home_screen.dart';
import 'consultation/video_consultation_screen.dart';
import 'appointment/appointments_screen.dart';
import 'health/health_screen.dart';
import 'profile/profile_screen.dart';

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Main navigation screen with bottom navigation bar and swipe support
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeAnimation;
  DateTime? _lastBackPressed;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const VideoConsultationScreen(),
    provider.ChangeNotifierProvider(
      create: (context) => RatingProvider(),
      child: const AppointmentsScreen(),
    ),
    const HealthScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.video_call_outlined,
      activeIcon: Icons.video_call,
      label: 'Video Call',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Appointments',
    ),
    NavigationItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Health',
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

  void _navigateToPage(int index) {
    if (index >= 0 && index < _screens.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(navigationProvider.notifier).setCurrentIndex(index);
      
      // Trigger swipe animation for visual feedback
      _swipeAnimationController.forward().then((_) {
        _swipeAnimationController.reverse();
      });
    }
  }

  void _onPageChanged(int index) {
    ref.read(navigationProvider.notifier).setCurrentIndex(index);
    
    // Haptic feedback for page changes
    HapticFeedback.lightImpact();
  }

  Future<bool> _onWillPop() async {
    final currentIndex = ref.read(currentTabIndexProvider);
    
    // If not on home tab, go to home first
    if (currentIndex != 0) {
      _navigateToPage(0);
      return false;
    }
    
    // Double tap to exit logic
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
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
      return false;
    }
    
    // Exit the app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentIndex = ref.watch(currentTabIndexProvider);

    if (!isAuthenticated) {
      // Navigate back to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            boxShadow: [
              BoxShadow(
                color: ThemeUtils.getShadowLightColor(context),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeUtils.getPrimaryColor(context).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                key: ValueKey(isSelected),
                                color: isSelected
                                    ? ThemeUtils.getPrimaryColor(context)
                                    : ThemeUtils.getTextSecondaryColor(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: isSelected
                                    ? ThemeUtils.getPrimaryColor(context)
                                    : ThemeUtils.getTextSecondaryColor(context),
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              child: Text(
                                item.label,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}