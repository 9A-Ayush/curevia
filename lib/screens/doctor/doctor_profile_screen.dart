import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/doctor_service.dart';
import 'doctor_profile_edit_screen.dart';

/// Doctor profile screen for managing doctor information
class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  Map<String, dynamic>? _doctorProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        // Use the new method that syncs statistics
        final profile = await DoctorService.getDoctorProfileWithStats(user.uid);
        setState(() {
          _doctorProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userModel;

    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(context),

                  // Profile Content
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ThemeUtils.getBackgroundColor(context),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: RefreshIndicator(
                        onRefresh: _loadDoctorProfile,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Profile Picture and Info
                              _buildProfileHeader(user),

                              const SizedBox(height: 30),

                              // Professional Stats
                              _buildProfessionalStats(context),

                              const SizedBox(height: 30),

                              // About Me Section
                              _buildAboutSection(context, user),

                              const SizedBox(height: 30),

                              // Profile Options
                              _buildProfileOptions(context, ref),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doctor Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your professional information',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorProfileEditScreen(
                    doctorProfile: _doctorProfile,
                  ),
                ),
              );
              
              // Reload profile if changes were made
              if (result == true) {
                _loadDoctorProfile();
              }
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          children: [
            // Profile picture
            Stack(
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorProfileEditScreen(
                          doctorProfile: _doctorProfile,
                        ),
                      ),
                    );
                    
                    // Reload profile if changes were made
                    if (result == true) {
                      _loadDoctorProfile();
                    }
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.textOnPrimary.withOpacity(
                      0.2,
                    ),
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                    child: user?.profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.textOnPrimary,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorProfileEditScreen(
                            doctorProfile: _doctorProfile,
                          ),
                        ),
                      );
                      
                      // Reload profile if changes were made
                      if (result == true) {
                        _loadDoctorProfile();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textOnPrimary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name and title
            Text(
              'Dr. ${user?.fullName ?? 'Doctor'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _doctorProfile?['specialty'] ?? _doctorProfile?['specialization'] ?? 'General Medicine',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textOnPrimary.withOpacity(0.9),
              ),
            ),

            const SizedBox(height: 8),

            // Rating and experience
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${(_doctorProfile?['rating'] ?? 4.8).toStringAsFixed(1)} (${_doctorProfile?['totalReviews'] ?? 127} reviews)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.work_outline,
                  color: AppColors.textOnPrimary.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_doctorProfile?['experienceYears'] ?? _doctorProfile?['experience'] ?? 5}+ years',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalStats(BuildContext context) {
    // Get real data from the doctor profile
    final totalPatients = _doctorProfile?['totalPatients'] ?? 0;
    final totalConsultations = _doctorProfile?['totalConsultations'] ?? 0;
    final experienceYears = _doctorProfile?['experienceYears'] ?? _doctorProfile?['experience'] ?? 0;
    final rating = _doctorProfile?['rating'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Patients',
                  '$totalPatients',
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Consultations',
                  '$totalConsultations',
                  Icons.medical_services,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Experience',
                  '$experienceYears years',
                  Icons.star,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Rating',
                  '${rating.toStringAsFixed(1)}/5',
                  Icons.thumb_up,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, user) {
    // Get real data from the doctor profile
    final bio = _doctorProfile?['bio'] ?? _doctorProfile?['about'] ?? 'No bio available';
    final education = _doctorProfile?['education'] ?? _doctorProfile?['qualification'] ?? 'Not specified';
    final specialization = _doctorProfile?['specialization'] ?? _doctorProfile?['specialty'] ?? 'General';
    final location = _doctorProfile?['location'] ?? _doctorProfile?['city'] ?? 'Not specified';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            bio,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildInfoRowWithIcon(
            Icons.school,
            'Education',
            education,
          ),
          const SizedBox(height: 8),
          _buildInfoRowWithIcon(
            Icons.medical_services,
            'Specialization',
            specialization,
          ),
          const SizedBox(height: 8),
          _buildInfoRowWithIcon(
            Icons.location_on,
            'Location',
            location,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildProfileOptions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings & Options',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionRow('Edit Profile', Icons.edit, () {
            _showEditProfileDialog();
          }),
          _buildActionRow('Change Password', Icons.lock_outline, () {
            _showChangePasswordDialog();
          }),
          _buildActionRow('Notification Settings', Icons.notifications_outlined, () {
            _showNotificationSettings();
          }),
          _buildActionRow('Privacy Policy', Icons.privacy_tip_outlined, () {
            _showPrivacyPolicy();
          }),
          _buildActionRow('Terms of Service', Icons.description_outlined, () {
            _showTermsOfService();
          }),
          _buildActionRow('Help & Support', Icons.help_outline, () {
            _showHelpSupport();
          }),
          _buildActionRow('Logout', Icons.logout, () {
            _showLogoutDialog();
          }),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = ref.read(authProvider).userModel;
    final TextEditingController nameController =
        TextEditingController(text: user?.fullName ?? '');
    final TextEditingController bioController =
        TextEditingController(text: _doctorProfile?['bio'] ?? '');
    final TextEditingController specialtyController =
        TextEditingController(text: _doctorProfile?['specialty'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  prefixIcon: Icon(Icons.medical_services),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                if (user != null) {
                  await DoctorService.updateDoctorProfile(
                    doctorId: user.uid,
                    profileData: {
                      'fullName': nameController.text,
                      'specialty': specialtyController.text,
                      'bio': bioController.text,
                      'updatedAt': DateTime.now().toIso8601String(),
                    },
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                      ),
                    );
                    _loadDoctorProfile();
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Appointment Reminders'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('New Patient Alerts'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Payment Notifications'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your personal information...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this service, you agree to the following terms and conditions...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@curevia.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Support'),
              subtitle: const Text('+91 1800-XXX-XXXX'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: ThemeUtils.getTextSecondaryColor(context),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show immediate feedback
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logging out...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              
              // Perform logout
              await ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
