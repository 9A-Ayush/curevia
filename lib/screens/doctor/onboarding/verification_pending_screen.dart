import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../utils/responsive_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import 'doctor_onboarding_screen.dart';

/// Verification pending screen shown after profile submission
class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _verificationStatus;
  bool _isLoading = true;
  bool _hasSubmittedForVerification = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadVerificationStatus();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        final status = await DoctorOnboardingService.getDoctorVerificationStatus(user.uid);
        setState(() {
          _verificationStatus = status;
          _hasSubmittedForVerification = status != null && status.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading status: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _applyForVerification() async {
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DoctorOnboardingScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeUtils.getBackgroundColor(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                ThemeUtils.getSecondaryColor(context).withOpacity(0.05),
                ThemeUtils.getBackgroundColor(context),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeUtils.getPrimaryColor(context),
                        ThemeUtils.getSecondaryColor(context),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeUtils.getOnPrimaryColor(context),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading verification status...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final status = _verificationStatus?['status'] ?? 'not_submitted';
    final reason = _verificationStatus?['reason'];

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
              ThemeUtils.getSecondaryColor(context).withOpacity(0.05),
              ThemeUtils.getBackgroundColor(context),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Animated Status Icon
                    _buildAnimatedStatusIcon(status),

                    const SizedBox(height: 32),

                    // Status Title
                    Text(
                      _getStatusTitle(status),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
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

                    // Status Cards
                    _buildStatusCards(status, reason),

                    const SizedBox(height: 32),

                    // Action Buttons
                    _buildActionButtons(status),

                    const SizedBox(height: 24),

                    // Support Section
                    _buildSupportSection(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatusIcon(String status) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (status == 'pending' || status == 'not_submitted') ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status),
                  _getStatusColor(status).withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 60,
              color: ThemeUtils.getOnPrimaryColor(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCards(String status, String? reason) {
    return Column(
      children: [
        if (status == 'not_submitted') ..._buildNotSubmittedCards(),
        if (status == 'pending') ..._buildPendingCards(),
        if (status == 'rejected' && reason != null) ..._buildRejectedCards(reason),
        if (status == 'verified') ..._buildVerifiedCards(),
      ],
    );
  }

  List<Widget> _buildNotSubmittedCards() {
    return [
      _buildInfoCard(
        icon: Icons.assignment,
        title: 'Complete Your Profile',
        subtitle: 'Fill out all required information to apply for verification',
        color: ThemeUtils.getWarningColor(context),
        delay: 0,
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        icon: Icons.upload_file,
        title: 'Upload Documents',
        subtitle: 'Provide necessary certificates and credentials',
        color: ThemeUtils.getInfoColor(context),
        delay: 200,
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        icon: Icons.verified_user,
        title: 'Get Verified',
        subtitle: 'Submit your profile for professional verification',
        color: ThemeUtils.getSuccessColor(context),
        delay: 400,
      ),
    ];
  }

  List<Widget> _buildPendingCards() {
    return [
      _buildInfoCard(
        icon: Icons.schedule,
        title: 'Review Time',
        subtitle: '24-48 hours',
        color: ThemeUtils.getInfoColor(context),
        delay: 0,
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        icon: Icons.notifications,
        title: 'Notification',
        subtitle: 'You\'ll be notified via email',
        color: ThemeUtils.getSuccessColor(context),
        delay: 200,
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        icon: Icons.verified_user,
        title: 'Verification Process',
        subtitle: 'Our team is reviewing your credentials',
        color: ThemeUtils.getPrimaryColor(context),
        delay: 400,
      ),
    ];
  }

  List<Widget> _buildRejectedCards(String reason) {
    return [
      _buildInfoCard(
        icon: Icons.error_outline,
        title: 'Rejection Reason',
        subtitle: reason,
        color: ThemeUtils.getErrorColor(context),
        delay: 0,
      ),
    ];
  }

  List<Widget> _buildVerifiedCards() {
    return [
      _buildInfoCard(
        icon: Icons.check_circle,
        title: 'Congratulations!',
        subtitle: 'Your profile has been successfully verified',
        color: ThemeUtils.getSuccessColor(context),
        delay: 0,
      ),
    ];
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: ThemeUtils.getShadowColor(context).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeUtils.getTextPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String status) {
    return Column(
      children: [
        if (status == 'not_submitted') ...[
          _buildStyledButton(
            text: 'Apply for Verification',
            icon: Icons.send,
            onPressed: _applyForVerification,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _buildStyledButton(
            text: 'Go to Dashboard',
            icon: Icons.dashboard,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            isPrimary: false,
          ),
        ],
        if (status == 'pending') ...[
          _buildStyledButton(
            text: 'Refresh Status',
            icon: Icons.refresh,
            onPressed: _loadVerificationStatus,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _buildStyledButton(
            text: 'Go to Dashboard',
            icon: Icons.dashboard,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            isPrimary: false,
          ),
        ],
        if (status == 'rejected') ...[
          _buildStyledButton(
            text: 'Edit & Resubmit',
            icon: Icons.edit,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const DoctorOnboardingScreen(),
                ),
              );
            },
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _buildStyledButton(
            text: 'Go to Dashboard',
            icon: Icons.dashboard,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            isPrimary: false,
          ),
        ],
        if (status == 'verified') ...[
          _buildStyledButton(
            text: 'Go to Dashboard',
            icon: Icons.dashboard,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            isPrimary: true,
          ),
        ],
        
        // Add logout button for all statuses
        const SizedBox(height: 20),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildStyledButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  ThemeUtils.getPrimaryColor(context),
                  ThemeUtils.getSecondaryColor(context),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: ThemeUtils.getBorderLightColor(context)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : ThemeUtils.getSurfaceColor(context),
          foregroundColor: isPrimary 
              ? ThemeUtils.getOnPrimaryColor(context) 
              : ThemeUtils.getTextPrimaryColor(context),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeUtils.getInfoColor(context).withOpacity(0.1),
                    ThemeUtils.getInfoColor(context).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeUtils.getInfoColor(context).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ThemeUtils.getInfoColor(context),
                          ThemeUtils.getInfoColor(context).withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ThemeUtils.getInfoColor(context).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Need Help?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our support team if you have any questions about the verification process.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThemeUtils.getInfoColor(context)),
                    ),
                    child: TextButton.icon(
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
                              SnackBar(
                                content: const Text('Could not open email app'),
                                backgroundColor: ThemeUtils.getErrorColor(context),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.email, color: ThemeUtils.getInfoColor(context), size: 20),
                      label: Text(
                        'Contact Support',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ThemeUtils.getInfoColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return ThemeUtils.getSuccessColor(context);
      case 'rejected':
        return ThemeUtils.getErrorColor(context);
      case 'pending':
        return ThemeUtils.getWarningColor(context);
      case 'not_submitted':
      default:
        return ThemeUtils.getInfoColor(context);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'not_submitted':
      default:
        return Icons.assignment_turned_in;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'verified':
        return 'Profile Verified!';
      case 'rejected':
        return 'Verification Rejected';
      case 'pending':
        return 'Verification Pending';
      case 'not_submitted':
      default:
        return 'Apply for Verification';
    }
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeUtils.getErrorColor(context).withOpacity(0.3)),
      ),
      child: TextButton.icon(
        onPressed: _showLogoutDialog,
        icon: Icon(
          Icons.logout,
          color: ThemeUtils.getErrorColor(context),
          size: 20,
        ),
        label: Text(
          'Logout',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ThemeUtils.getErrorColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: ThemeUtils.getErrorColor(context),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You can continue the verification process later.',
          style: TextStyle(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ThemeUtils.getErrorColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ThemeUtils.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    color: ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Perform logout
      await ref.read(authProvider.notifier).signOut();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'verified':
        return 'Your profile has been verified. You can now access all doctor features.';
      case 'rejected':
        return 'Your profile verification was rejected. Please review the reason and resubmit.';
      case 'pending':
        return 'Your profile is under review. We\'ll notify you once the verification is complete.';
      case 'not_submitted':
      default:
        return 'Complete your profile and submit it for verification to access all doctor features.';
    }
  }
}