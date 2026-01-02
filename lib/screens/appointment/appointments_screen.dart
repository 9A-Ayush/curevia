import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../patient/find_doctors_screen.dart';

/// Appointments screen
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
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
                        Icons.calendar_today,
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
                            'Manage your appointments',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'View, schedule and track your medical visits',
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
                    _buildInfoChip(Icons.schedule, 'Easy Scheduling'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.notifications, 'Reminders'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: ThemeUtils.getSurfaceColor(context),
            child: TabBar(
              controller: _tabController,
              labelColor: ThemeUtils.getPrimaryColor(context),
              unselectedLabelColor: ThemeUtils.getTextSecondaryColor(context),
              indicatorColor: ThemeUtils.getPrimaryColor(context),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildPastTab(),
                _buildCancelledTab(),
              ],
            ),
          ),

          // Bottom Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FindDoctorsScreen(
                              consultationType: 'online',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeUtils.getSurfaceVariantColor(context),
                        foregroundColor: ThemeUtils.getTextPrimaryColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: ThemeUtils.getBorderLightColor(context),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.video_call, size: 20),
                      label: const Text(
                        'Video Call',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showQuickBookingOptions();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeUtils.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 60,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No upcoming appointments',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Book your first appointment with a verified doctor',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FindDoctorsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeUtils.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: const Text(
                  'Find Doctors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Show quick booking options
                  _showQuickBookingOptions();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeUtils.getPrimaryColor(context),
                  side: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.video_call),
                label: const Text(
                  'Video Consultation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Prominent Book Appointment Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeUtils.getPrimaryColor(context),
                    ThemeUtils.getPrimaryColor(context).withOpacity(0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showQuickBookingOptions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildPastTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No past appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, size: 80, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No cancelled appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
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

  void _showQuickBookingOptions() {
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: ThemeUtils.getPrimaryColor(context),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Book Your Appointment',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your preferred consultation type',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildBookingOption(
                            icon: Icons.video_call,
                            title: 'Video Consultation',
                            subtitle: 'Connect with doctors online from home',
                            color: AppColors.secondary,
                            badge: 'Popular',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FindDoctorsScreen(
                                    consultationType: 'online',
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildBookingOption(
                            icon: Icons.location_on,
                            title: 'In-Person Visit',
                            subtitle: 'Visit doctor at clinic for physical examination',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FindDoctorsScreen(
                                    consultationType: 'offline',
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildBookingOption(
                            icon: Icons.emergency,
                            title: 'Emergency Consultation',
                            subtitle: 'Immediate medical attention required',
                            color: AppColors.error,
                            badge: '24/7',
                            onTap: () {
                              Navigator.pop(context);
                              // Navigate to emergency screen or show emergency doctors
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FindDoctorsScreen(
                                    consultationType: 'emergency',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: ThemeUtils.getPrimaryColor(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'All consultations are with verified doctors',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ThemeUtils.getPrimaryColor(context),
                                      fontWeight: FontWeight.w500,
                                    ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceVariantColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
          boxShadow: [
            BoxShadow(
              color: ThemeUtils.getShadowLightColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
