import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';
import 'verification_pending_screen.dart';

/// Review and submit step in doctor onboarding
class ReviewSubmitStep extends ConsumerStatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onBack;

  const ReviewSubmitStep({
    super.key,
    required this.onboardingData,
    required this.onBack,
  });

  @override
  ConsumerState<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends ConsumerState<ReviewSubmitStep> {
  bool _acceptedTerms = false;
  bool _isLoading = false;

  Future<void> _submitProfile() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Submit for verification
      await DoctorOnboardingService.submitForVerification(user.uid);

      setState(() => _isLoading = false);

      if (mounted) {
        // Navigate to verification pending screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificationPendingScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header
        Text(
          'Review Your Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review all the information before submitting for verification.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
        ),

        const SizedBox(height: 24),

        // Basic Information
        _buildSection(
          'Basic Information',
          Icons.person,
          [
            _buildInfoRow('Name', widget.onboardingData['fullName']),
            _buildInfoRow('Phone', widget.onboardingData['phoneNumber']),
            _buildInfoRow('Email', widget.onboardingData['email']),
            _buildInfoRow('Gender', widget.onboardingData['gender']),
            if (widget.onboardingData['dateOfBirth'] != null)
              _buildInfoRow(
                'Date of Birth',
                _formatDate(widget.onboardingData['dateOfBirth']),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Professional Details
        _buildSection(
          'Professional Details',
          Icons.medical_services,
          [
            _buildInfoRow(
              'License Number',
              widget.onboardingData['medicalLicenseNumber'],
            ),
            _buildInfoRow(
              'Registration Number',
              widget.onboardingData['registrationNumber'],
            ),
            _buildInfoRow('Specialty', widget.onboardingData['specialty']),
            _buildInfoRow(
              'Qualification',
              widget.onboardingData['qualification'],
            ),
            _buildInfoRow(
              'Experience',
              '${widget.onboardingData['experienceYears']} years',
            ),
            if (widget.onboardingData['degrees'] != null)
              _buildInfoRow(
                'Degrees',
                (widget.onboardingData['degrees'] as List).join(', '),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Practice Information
        _buildSection(
          'Practice Information',
          Icons.local_hospital,
          [
            _buildInfoRow('Clinic Name', widget.onboardingData['clinicName']),
            _buildInfoRow('City', widget.onboardingData['city']),
            _buildInfoRow('State', widget.onboardingData['state']),
            _buildInfoRow(
              'Online Fee',
              '₹${widget.onboardingData['consultationFee']}',
            ),
            _buildInfoRow(
              'Offline Fee',
              '₹${widget.onboardingData['offlineConsultationFee']}',
            ),
            if (widget.onboardingData['languages'] != null)
              _buildInfoRow(
                'Languages',
                (widget.onboardingData['languages'] as List).join(', '),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Availability
        _buildSection(
          'Availability',
          Icons.schedule,
          [
            _buildInfoRow(
              'Consultation Duration',
              '${widget.onboardingData['consultationDuration']} minutes',
            ),
            _buildInfoRow(
              'Working Days',
              _getWorkingDays(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Terms and Conditions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThemeUtils.getBorderLightColor(context),
            ),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                title: const Text(
                  'I accept the Terms and Conditions',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'By submitting, you agree to our terms of service and privacy policy.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your profile will be reviewed by our team within 24-48 hours. You will be notified once verified.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: widget.onBack,
                backgroundColor: ThemeUtils.getSurfaceColor(context),
                textColor: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Submit for Verification',
                onPressed: _isLoading ? null : _submitProfile,
                backgroundColor: AppColors.success,
                textColor: Colors.white,
                isLoading: _isLoading,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getWorkingDays() {
    final availability = widget.onboardingData['availability'] as Map?;
    if (availability == null) return 'Not set';

    final workingDays = <String>[];
    final dayNames = {
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
    };

    availability.forEach((day, data) {
      if (data['isAvailable'] == true) {
        workingDays.add(dayNames[day] ?? day);
      }
    });

    return workingDays.isEmpty ? 'Not set' : workingDays.join(', ');
  }
}
