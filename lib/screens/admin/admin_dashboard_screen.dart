import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin/admin_theme_settings_widget.dart';
import '../../widgets/common/notification_badge.dart';
import 'doctor_verification_screen.dart';
import 'users_management_screen.dart';
import 'appointments_management_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, int> _stats = {};
  String _adminName = 'Admin';
  String _greeting = 'Good Day';
  late PageController _pageController;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _setGreeting();
    _loadAdminData();
    _loadStats();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      _greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      _greeting = 'Good Evening';
    } else {
      _greeting = 'Good Night';
    }
  }

  Future<void> _loadAdminData() async {
    try {
      final user = ref.read(authProvider).firebaseUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && mounted) {
          setState(() {
            _adminName = doc.data()?['fullName'] ?? 'Admin';
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      int pendingCount = 0;
      int doctorsCount = 0;
      int patientsCount = 0;
      int appointmentsCount = 0;

      try {
        final pendingVerifications = await firestore
            .collection('doctor_verifications')
            .where('status', isEqualTo: 'pending')
            .get();
        pendingCount = pendingVerifications.docs.length;
      } catch (e) {
        // Collection might not exist
      }

      try {
        final totalDoctors = await firestore.collection('doctors').get();
        doctorsCount = totalDoctors.docs.length;
      } catch (e) {
        // Collection might not exist
      }

      try {
        final totalPatients = await firestore
            .collection('users')
            .where('role', isEqualTo: 'patient')
            .get();
        patientsCount = totalPatients.docs.length;
      } catch (e) {
        // Collection might not exist
      }

      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final todayAppointments = await firestore
            .collection('appointments')
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        appointmentsCount = todayAppointments.docs.length;
      } catch (e) {
        // Collection might not exist
      }
      
      if (mounted) {
        setState(() {
          _stats = {
            'pendingVerifications': pendingCount,
            'totalDoctors': doctorsCount,
            'totalPatients': patientsCount,
            'todayAppointments': appointmentsCount,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: ThemeUtils.getBackgroundColor(context),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _selectedIndex = index);
          },
          children: [
            // Dashboard (index 0)
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadStats,
                color: ThemeUtils.getPrimaryColor(context),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildQuickActions(),
                      _buildOverviewSection(),
                    ],
                  ),
                ),
              ),
            ),
            // Other screens with app bar
            _buildScreenWithAppBar(const DoctorVerificationScreen(), 'Doctor Verifications'),
            _buildScreenWithAppBar(const UsersManagementScreen(), 'Users Management'),
            _buildScreenWithAppBar(const AppointmentsManagementScreen(), 'Appointments Management'),
            _buildScreenWithAppBar(const AnalyticsScreen(), 'Analytics'),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // If not on the main dashboard, go back to dashboard first
    if (_selectedIndex != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    // Double-tap to exit logic
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit admin panel'),
          duration: const Duration(seconds: 2),
          backgroundColor: ThemeUtils.getPrimaryColor(context),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    }
    
    // Show exit confirmation dialog
    return await _showExitConfirmation();
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app,
              color: ThemeUtils.getPrimaryColor(context),
            ),
            const SizedBox(width: 12),
            Text(
              'Exit Admin Panel',
              style: TextStyle(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to exit the admin panel?',
          style: TextStyle(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeUtils.getPrimaryColor(context),
              foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeUtils.isDarkMode(context)
            ? AppColors.darkPrimaryGradient
            : AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: TextStyle(
                      color: ThemeUtils.getTextOnPrimaryColor(context).withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _adminName,
                    style: TextStyle(
                      color: ThemeUtils.getTextOnPrimaryColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadStats,
                    icon: Icon(
                      Icons.refresh, 
                      color: ThemeUtils.getTextOnPrimaryColor(context),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: ThemeUtils.getTextOnPrimaryColor(context),
                    ),
                    color: ThemeUtils.getSurfaceColor(context),
                    onSelected: (value) {
                      if (value == 'theme') {
                        _showThemeSettings();
                      } else if (value == 'logout') {
                        _showLogoutDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'theme',
                        child: Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: ThemeUtils.getTextPrimaryColor(context),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Theme Settings',
                              style: TextStyle(
                                color: ThemeUtils.getTextPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: ThemeUtils.getTextPrimaryColor(context),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: ThemeUtils.getTextPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeUtils.getTextOnPrimaryColor(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings, 
                  color: ThemeUtils.getTextOnPrimaryColor(context), 
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: ThemeUtils.getTextOnPrimaryColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your healthcare platform',
                        style: TextStyle(
                          color: ThemeUtils.getTextOnPrimaryColor(context).withOpacity(0.9),
                          fontSize: 12,
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
    );
  }

  Widget _buildQuickActions() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: ThemeUtils.getTextPrimaryColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Single row of compact action cards
          if (isMobile)
            // Scrollable row for mobile
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: _buildCompactActionCard(
                      icon: Icons.verified_user_outlined,
                      label: 'Verify',
                      color: AppColors.warning,
                      onTap: () => _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      badge: _stats['pendingVerifications'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: _buildCompactActionCard(
                      icon: Icons.people_outline,
                      label: 'Users',
                      color: AppColors.info,
                      onTap: () => _pageController.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: _buildCompactActionCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Bookings',
                      color: AppColors.secondary,
                      onTap: () => _pageController.animateToPage(
                        3,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: _buildCompactActionCard(
                      icon: Icons.analytics_outlined,
                      label: 'Stats',
                      color: AppColors.success,
                      onTap: () => _pageController.animateToPage(
                        4,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Fixed row for larger screens
            Row(
              children: [
                Expanded(
                  child: _buildCompactActionCard(
                    icon: Icons.verified_user_outlined,
                    label: 'Verify',
                    color: AppColors.warning,
                    onTap: () => _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    badge: _stats['pendingVerifications'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactActionCard(
                    icon: Icons.people_outline,
                    label: 'Users',
                    color: AppColors.info,
                    onTap: () => _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactActionCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bookings',
                    color: AppColors.secondary,
                    onTap: () => _pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactActionCard(
                    icon: Icons.analytics_outlined,
                    label: 'Stats',
                    color: AppColors.success,
                    onTap: () => _pageController.animateToPage(
                      4,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withOpacity(0.05),
        child: Container(
          height: 70, // Fixed compact height
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThemeUtils.getBorderLightColor(context),
            ),
            boxShadow: [
              BoxShadow(
                color: ThemeUtils.getShadowLightColor(context),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
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
                    child: Text(
                      label,
                      style: TextStyle(
                        color: ThemeUtils.getTextPrimaryColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (badge != null && badge > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge.toString(),
                      style: TextStyle(
                        color: ThemeUtils.getTextOnPrimaryColor(context),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              color: ThemeUtils.getTextPrimaryColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: ThemeUtils.getPrimaryColor(context),
                ),
              ),
            )
          else ...[
            _buildStatCard(
              title: 'Pending Verifications',
              value: _stats['pendingVerifications']?.toString() ?? '0',
              icon: Icons.pending_actions,
              color: AppColors.warning,
              onTap: () => _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Total Doctors',
              value: _stats['totalDoctors']?.toString() ?? '0',
              icon: Icons.medical_services,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Total Patients',
              value: _stats['totalPatients']?.toString() ?? '0',
              icon: Icons.people,
              color: AppColors.info,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: "Today's Appointments",
              value: _stats['todayAppointments']?.toString() ?? '0',
              icon: Icons.calendar_today,
              color: AppColors.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThemeUtils.getBorderLightColor(context),
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeUtils.getShadowLightColor(context),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: ThemeUtils.getTextSecondaryColor(context),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: ThemeUtils.getTextSecondaryColor(context),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenWithAppBar(Widget screen, String title) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: ThemeUtils.getTextOnPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeUtils.getTextOnPrimaryColor(context),
          ),
          onPressed: () {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ThemeUtils.getTextOnPrimaryColor(context),
            ),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: screen,
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      backgroundColor: ThemeUtils.getSurfaceColor(context),
      indicatorColor: ThemeUtils.getPrimaryColor(context).withOpacity(0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(
            Icons.dashboard_outlined, 
            color: _selectedIndex == 0 
                ? ThemeUtils.getPrimaryColor(context)
                : ThemeUtils.getTextSecondaryColor(context),
          ),
          selectedIcon: Icon(
            Icons.dashboard,
            color: ThemeUtils.getPrimaryColor(context),
          ),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: (_stats['pendingVerifications'] ?? 0) > 0,
            label: Text((_stats['pendingVerifications'] ?? 0).toString()),
            child: Icon(
              Icons.verified_user_outlined, 
              color: _selectedIndex == 1 
                  ? ThemeUtils.getPrimaryColor(context)
                  : ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          selectedIcon: Badge(
            isLabelVisible: (_stats['pendingVerifications'] ?? 0) > 0,
            label: Text((_stats['pendingVerifications'] ?? 0).toString()),
            child: Icon(
              Icons.verified_user,
              color: ThemeUtils.getPrimaryColor(context),
            ),
          ),
          label: 'Verify',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.people_outline, 
            color: _selectedIndex == 2 
                ? ThemeUtils.getPrimaryColor(context)
                : ThemeUtils.getTextSecondaryColor(context),
          ),
          selectedIcon: Icon(
            Icons.people,
            color: ThemeUtils.getPrimaryColor(context),
          ),
          label: 'Users',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.calendar_today_outlined, 
            color: _selectedIndex == 3 
                ? ThemeUtils.getPrimaryColor(context)
                : ThemeUtils.getTextSecondaryColor(context),
          ),
          selectedIcon: Icon(
            Icons.calendar_today,
            color: ThemeUtils.getPrimaryColor(context),
          ),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.analytics_outlined, 
            color: _selectedIndex == 4 
                ? ThemeUtils.getPrimaryColor(context)
                : ThemeUtils.getTextSecondaryColor(context),
          ),
          selectedIcon: Icon(
            Icons.analytics,
            color: ThemeUtils.getPrimaryColor(context),
          ),
          label: 'Stats',
        ),
      ],
    );
  }

  void _showThemeSettings() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Theme Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AdminThemeSettingsWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Show immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging out...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Perform logout
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
