import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';

/// Doctor analytics screen for performance insights and reports
class DoctorAnalyticsScreen extends ConsumerStatefulWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  ConsumerState<DoctorAnalyticsScreen> createState() =>
      _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends ConsumerState<DoctorAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

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
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(
                value: 'This Month',
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: 'Last 3 Months',
                child: Text('Last 3 Months'),
              ),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Patients'),
            Tab(text: 'Revenue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPatientsTab(),
          _buildRevenueTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics
          _buildKeyMetrics(),

          const SizedBox(height: 24),

          // Performance chart
          _buildPerformanceChart(),

          const SizedBox(height: 24),

          // Recent trends
          _buildRecentTrends(),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient statistics
          _buildPatientStatistics(),

          const SizedBox(height: 24),

          // Patient demographics
          _buildPatientDemographics(),

          const SizedBox(height: 24),

          // Top conditions
          _buildTopConditions(),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue overview
          _buildRevenueOverview(),

          const SizedBox(height: 24),

          // Revenue breakdown
          _buildRevenueBreakdown(),

          const SizedBox(height: 24),

          // Export options
          _buildExportOptions(),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Consultations',
                '127',
                '+12%',
                Icons.medical_services,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Patient Satisfaction',
                '4.8/5',
                '+0.2',
                Icons.star,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Response Time',
                '3.2 min',
                '-0.8 min',
                Icons.timer,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                '₹63,500',
                '+18%',
                Icons.currency_rupee,
                AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: change.startsWith('+')
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: change.startsWith('+')
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consultation Trends',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Chart will be displayed here'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Trends',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTrendItem(
          'Consultation bookings increased by 15%',
          Icons.trending_up,
          AppColors.success,
        ),
        _buildTrendItem(
          'Average session duration improved',
          Icons.access_time,
          AppColors.info,
        ),
        _buildTrendItem(
          'Patient retention rate at 92%',
          Icons.people,
          AppColors.primary,
        ),
        _buildTrendItem(
          'New patient referrals up 8%',
          Icons.person_add,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildTrendItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Patients', '342', Icons.people),
              ),
              Expanded(
                child: _buildStatItem('New Patients', '28', Icons.person_add),
              ),
              Expanded(child: _buildStatItem('Returning', '314', Icons.repeat)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPatientDemographics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Demographics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDemographicItem('Age 18-30', '35%', 0.35),
          _buildDemographicItem('Age 31-45', '40%', 0.40),
          _buildDemographicItem('Age 46-60', '20%', 0.20),
          _buildDemographicItem('Age 60+', '5%', 0.05),
        ],
      ),
    );
  }

  Widget _buildDemographicItem(String label, String percentage, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                percentage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTopConditions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Common Conditions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildConditionItem('Hypertension', '23%'),
          _buildConditionItem('Diabetes', '18%'),
          _buildConditionItem('Common Cold', '15%'),
          _buildConditionItem('Anxiety', '12%'),
          _buildConditionItem('Back Pain', '10%'),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String condition, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(condition),
          Text(
            percentage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Overview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildRevenueItem(
                  'Total Revenue',
                  '₹63,500',
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildRevenueItem(
                  'Avg per Consultation',
                  '₹500',
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRevenueItem(
                  'Online Consultations',
                  '₹45,000',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildRevenueItem(
                  'In-Person Visits',
                  '₹18,500',
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Revenue chart will be displayed here'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Reports',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Export PDF',
                onPressed: () {
                  // TODO: Export PDF report
                },
                backgroundColor: AppColors.error,
                textColor: Colors.white,
                icon: Icons.picture_as_pdf,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Export Excel',
                onPressed: () {
                  // TODO: Export Excel report
                },
                backgroundColor: AppColors.success,
                textColor: Colors.white,
                icon: Icons.table_chart,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
