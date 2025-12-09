import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../widgets/common/custom_button.dart';
import '../appointment/appointment_booking_screen.dart';

/// Doctor detail screen for patients
class DoctorDetailScreen extends ConsumerStatefulWidget {
  final DoctorModel doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen>
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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildDoctorHeader(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface,
              backgroundImage: widget.doctor.profileImageUrl != null
                  ? NetworkImage(widget.doctor.profileImageUrl!)
                  : null,
              child: widget.doctor.profileImageUrl == null
                  ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            widget.doctor.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.doctor.specialty ?? 'General Physician',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.star,
                widget.doctor.rating?.toStringAsFixed(1) ?? '0.0',
                'Rating',
              ),
              _buildStatItem(
                Icons.people,
                '${widget.doctor.totalReviews ?? 0}',
                'Reviews',
              ),
              _buildStatItem(
                Icons.work,
                '${widget.doctor.experienceYears ?? 0}+ yrs',
                'Experience',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Reviews'),
          Tab(text: 'Location'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 300,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(),
          _buildReviewsTab(),
          _buildLocationTab(),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.doctor.about != null) ...[
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.doctor.about!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.doctor.degrees != null &&
              widget.doctor.degrees!.isNotEmpty) ...[
            Text(
              'Qualifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.doctor.degrees!.map((qual) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(qual)),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (widget.doctor.consultationFee != null) ...[
            Text(
              'Consultation Fee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.doctor.consultationFeeText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Center(
      child: Text('Reviews coming soon'),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.doctor.clinicAddress != null) ...[
            Text(
              'Clinic Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.doctor.clinicAddress!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.doctor.isAvailableOnline == true)
              Expanded(
                child: CustomButton(
                  text: 'Video Call',
                  onPressed: () => _bookAppointment('online'),
                  icon: Icons.video_call,
                  backgroundColor: AppColors.secondary,
                ),
              ),
            if (widget.doctor.isAvailableOnline == true)
              const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Book Visit',
                onPressed: () => _bookAppointment('offline'),
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAppointment(String consultationType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingScreen(
          doctor: widget.doctor,
          consultationType: consultationType,
        ),
      ),
    );
  }
}
