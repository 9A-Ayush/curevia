import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadAdminData();
    _loadStats();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
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
    if (_selectedIndex != 0) {
      return _buildOtherScreens();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _adminName,
                    style: const TextStyle(
                      color: Colors.white,
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
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your healthcare platform',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                icon: Icons.verified_user,
                label: 'Verifications',
                color: const Color(0xFFFF9800),
                onTap: () => setState(() => _selectedIndex = 1),
                badge: _stats['pendingVerifications'],
              ),
              _buildQuickActionCard(
                icon: Icons.people,
                label: 'Users',
                color: const Color(0xFF2196F3),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _buildQuickActionCard(
                icon: Icons.calendar_today,
                label: 'Appointments',
                color: const Color(0xFF9C27B0),
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _buildQuickActionCard(
                icon: Icons.bar_chart,
                label: 'Analytics',
                color: const Color(0xFF4CAF50),
                onTap: () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
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
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildStatCard(
              title: 'Pending Verifications',
              value: _stats['pendingVerifications']?.toString() ?? '0',
              icon: Icons.pending_actions,
              color: const Color(0xFFFF9800),
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Total Doctors',
              value: _stats['totalDoctors']?.toString() ?? '0',
              icon: Icons.medical_services,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Total Patients',
              value: _stats['totalPatients']?.toString() ?? '0',
              icon: Icons.people,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: "Today's Appointments",
              value: _stats['todayAppointments']?.toString() ?? '0',
              icon: Icons.calendar_today,
              color: const Color(0xFF9C27B0),
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
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      backgroundColor: const Color(0xFF2A2A2A),
      indicatorColor: const Color(0xFF4CAF50),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.dashboard, color: _selectedIndex == 0 ? Colors.white : Colors.white54),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: (_stats['pendingVerifications'] ?? 0) > 0,
            label: Text((_stats['pendingVerifications'] ?? 0).toString()),
            child: Icon(Icons.verified_user, color: _selectedIndex == 1 ? Colors.white : Colors.white54),
          ),
          label: 'Verifications',
        ),
        NavigationDestination(
          icon: Icon(Icons.people, color: _selectedIndex == 2 ? Colors.white : Colors.white54),
          label: 'Users',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today, color: _selectedIndex == 3 ? Colors.white : Colors.white54),
          label: 'Appointments',
        ),
      ],
    );
  }

  Widget _buildOtherScreens() {
    Widget screen;
    switch (_selectedIndex) {
      case 1:
        screen = const DoctorVerificationScreen();
        break;
      case 2:
        screen = const UsersManagementScreen();
        break;
      case 3:
        screen = const AppointmentsManagementScreen();
        break;
      case 4:
        screen = const AnalyticsScreen();
        break;
      default:
        screen = const SizedBox();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedIndex = 0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: screen,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Doctor Verifications';
      case 2:
        return 'Users Management';
      case 3:
        return 'Appointments';
      case 4:
        return 'Analytics';
      default:
        return 'Admin Dashboard';
    }
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
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
