import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../utils/responsive_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';

/// Verification pending screen shown after profile submission
class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen> {
  Map<String, dynamic>? _verificationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        final status =
            await DoctorOnboardingService.getDoctorVerificationStatus(
          user.uid,
        );
        setState(() {
          _verificationStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading verification status...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final status = _verificationStatus?['status'] ?? 'pending';
    final reason = _verificationStatus?['reason'];

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: SafeArea(
        child: ResponsiveUtils.centerContent(
          context: context,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Status Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    size: 60,
                    color: _getStatusColor(status),
                  ),
                ),

                const SizedBox(height: 32),

                // Status Title
                Text(
                  _getStatusTitle(status),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Status Description
                Text(
                  _getStatusDescription(status),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeUtils.getBorderLightColor(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (status == 'pending') ...[
                        _buildInfoItem(
                          Icons.schedule,
                          'Estimated Time',
                          '24-48 hours',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          Icons.email,
                          'Notification',
                          'You will be notified via email',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          Icons.verified_user,
                          'Verification Process',
                          'Our team is reviewing your credentials',
                        ),
                      ],
                      if (status == 'rejected' && reason != null) ...[
                        _buildInfoItem(
                          Icons.error_outline,
                          'Rejection Reason',
                          reason,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                if (status == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadVerificationStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/doctor/profile');
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                if (status == 'rejected') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate back to onboarding for editing
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit & Resubmit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Support Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.support_agent, color: AppColors.info, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Need Help?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contact our support team if you have any questions about the verification process.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'support@curevia.com',
                            query: 'subject=Doctor Verification Support&body=Hello, I need help with my verification.',
                          );
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open email app')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.email),
                        label: const Text('Contact Support'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'verified':
        return 'Profile Verified!';
      case 'rejected':
        return 'Verification Rejected';
      case 'pending':
      default:
        return 'Verification Pending';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'verified':
        return 'Your profile has been verified. You can now access all doctor features.';
      case 'rejected':
        return 'Your profile verification was rejected. Please review the reason and resubmit.';
      case 'pending':
      default:
        return 'Your profile is under review. We\'ll notify you once the verification is complete.';
    }
  }
}
