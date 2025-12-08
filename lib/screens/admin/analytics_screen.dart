import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      final totalUsers = await firestore.collection('users').count().get();
      final totalDoctors = await firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .count()
          .get();
      final totalPatients = await firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .count()
          .get();
      final verifiedDoctors = await firestore
          .collection('doctors')
          .where('verificationStatus', isEqualTo: 'verified')
          .count()
          .get();
      final pendingVerifications = await firestore
          .collection('doctor_verifications')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final totalAppointments = await firestore
          .collection('appointments')
          .count()
          .get();
      final completedAppointments = await firestore
          .collection('appointments')
          .where('status', isEqualTo: 'completed')
          .count()
          .get();
      final cancelledAppointments = await firestore
          .collection('appointments')
          .where('status', isEqualTo: 'cancelled')
          .count()
          .get();
      final upcomingAppointments = await firestore
          .collection('appointments')
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('appointmentDate', isGreaterThan: Timestamp.fromDate(now))
          .count()
          .get();

      final periodAppointments = await firestore
          .collection('appointments')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .count()
          .get();
      final periodUsers = await firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .count()
          .get();

      final appointmentsSnapshot = await firestore
          .collection('appointments')
          .where('consultationFee', isGreaterThan: 0)
          .get();
      
      double totalRevenue = 0;
      double periodRevenue = 0;
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final fee = (data['consultationFee'] ?? 0).toDouble();
        totalRevenue += fee;
        
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          if (createdAt.isAfter(startDate)) {
            periodRevenue += fee;
          }
        }
      }

      setState(() {
        _analytics = {
          'totalUsers': totalUsers.count ?? 0,
          'totalDoctors': totalDoctors.count ?? 0,
          'totalPatients': totalPatients.count ?? 0,
          'verifiedDoctors': verifiedDoctors.count ?? 0,
          'pendingVerifications': pendingVerifications.count ?? 0,
          'totalAppointments': totalAppointments.count ?? 0,
          'completedAppointments': completedAppointments.count ?? 0,
          'cancelledAppointments': cancelledAppointments.count ?? 0,
          'upcomingAppointments': upcomingAppointments.count ?? 0,
          'periodAppointments': periodAppointments.count ?? 0,
          'periodUsers': periodUsers.count ?? 0,
          'totalRevenue': totalRevenue,
          'periodRevenue': periodRevenue,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            border: Border(
              bottom: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analytics & Reports',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: _loadAnalytics,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodChip('Today', 'today'),
                  _buildPeriodChip('This Week', 'week'),
                  _buildPeriodChip('This Month', 'month'),
                  _buildPeriodChip('This Year', 'year'),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    child: _buildAnalyticsContent(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = value);
        _loadAnalytics();
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : ThemeUtils.getTextPrimaryColor(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: ThemeUtils.getSurfaceColor(context),
    );
  }

  Widget _buildAnalyticsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Users',
                  _analytics['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  AppColors.primary,
                  '+${_analytics['periodUsers'] ?? 0} this period',
                ),
                _buildStatCard(
                  'Total Doctors',
                  _analytics['totalDoctors']?.toString() ?? '0',
                  Icons.medical_services,
                  AppColors.info,
                  '${_analytics['verifiedDoctors'] ?? 0} verified',
                ),
                _buildStatCard(
                  'Total Patients',
                  _analytics['totalPatients']?.toString() ?? '0',
                  Icons.person,
                  AppColors.success,
                  '',
                ),
                _buildStatCard(
                  'Pending Verifications',
                  _analytics['pendingVerifications']?.toString() ?? '0',
                  Icons.pending_actions,
                  AppColors.warning,
                  'Requires action',
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Appointments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Appointments',
                  _analytics['totalAppointments']?.toString() ?? '0',
                  Icons.calendar_month,
                  AppColors.primary,
                  '+${_analytics['periodAppointments'] ?? 0} this period',
                ),
                _buildStatCard(
                  'Completed',
                  _analytics['completedAppointments']?.toString() ?? '0',
                  Icons.check_circle,
                  AppColors.success,
                  '',
                ),
                _buildStatCard(
                  'Upcoming',
                  _analytics['upcomingAppointments']?.toString() ?? '0',
                  Icons.schedule,
                  AppColors.info,
                  '',
                ),
                _buildStatCard(
                  'Cancelled',
                  _analytics['cancelledAppointments']?.toString() ?? '0',
                  Icons.cancel,
                  AppColors.error,
                  '',
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Revenue',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Revenue',
                  '₹${NumberFormat('#,##,###').format(_analytics['totalRevenue'] ?? 0)}',
                  Icons.currency_rupee,
                  AppColors.success,
                  'All time',
                ),
                _buildStatCard(
                  'Period Revenue',
                  '₹${NumberFormat('#,##,###').format(_analytics['periodRevenue'] ?? 0)}',
                  Icons.trending_up,
                  AppColors.primary,
                  _getPeriodLabel(),
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        _buildAppointmentStatusChart(),
        
        const SizedBox(height: 32),
        
        _buildQuickInsights(),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                        fontSize: 11,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusChart() {
    final total = _analytics['totalAppointments'] ?? 1;
    final completed = _analytics['completedAppointments'] ?? 0;
    final upcoming = _analytics['upcomingAppointments'] ?? 0;
    final cancelled = _analytics['cancelledAppointments'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Status Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          
          _buildProgressBar(
            'Completed',
            completed,
            total,
            AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            'Upcoming',
            upcoming,
            total,
            AppColors.info,
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            'Cancelled',
            cancelled,
            total,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    final progress = total > 0 ? value / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$value ($percentage%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    final completionRate = _analytics['totalAppointments'] > 0
        ? ((_analytics['completedAppointments'] ?? 0) / _analytics['totalAppointments'] * 100)
            .toStringAsFixed(1)
        : '0.0';
    final cancellationRate = _analytics['totalAppointments'] > 0
        ? ((_analytics['cancelledAppointments'] ?? 0) / _analytics['totalAppointments'] * 100)
            .toStringAsFixed(1)
        : '0.0';
    final verificationRate = _analytics['totalDoctors'] > 0
        ? ((_analytics['verifiedDoctors'] ?? 0) / _analytics['totalDoctors'] * 100)
            .toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          _buildInsightRow(
            Icons.check_circle,
            'Appointment Completion Rate',
            '$completionRate%',
            AppColors.success,
          ),
          const Divider(height: 24),
          _buildInsightRow(
            Icons.cancel,
            'Appointment Cancellation Rate',
            '$cancellationRate%',
            AppColors.error,
          ),
          const Divider(height: 24),
          _buildInsightRow(
            Icons.verified,
            'Doctor Verification Rate',
            '$verificationRate%',
            AppColors.primary,
          ),
          const Divider(height: 24),
          _buildInsightRow(
            Icons.trending_up,
            'Average Revenue per Appointment',
            '₹${_analytics['totalAppointments'] > 0 ? ((_analytics['totalRevenue'] ?? 0) / _analytics['totalAppointments']).toStringAsFixed(0) : '0'}',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value, Color color) {
    return Row(
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This week';
      case 'month':
        return 'This month';
      case 'year':
        return 'This year';
      default:
        return '';
    }
  }
}
