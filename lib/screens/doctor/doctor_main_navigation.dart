import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/navigation/custom_bottom_navigation_bar.dart';
import '../../providers/doctor_navigation_provider.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_analytics_screen.dart';
import 'doctor_profile_screen.dart';

/// Main navigation for doctor interface
class DoctorMainNavigation extends ConsumerStatefulWidget {
  const DoctorMainNavigation({super.key});

  @override
  ConsumerState<DoctorMainNavigation> createState() =>
      _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends ConsumerState<DoctorMainNavigation> {
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
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(doctorNavigationProvider);

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(doctorNavigationProvider.notifier).setTabIndex(index);
        },
        items: _navigationItems,
      ),
    );
  }
}
