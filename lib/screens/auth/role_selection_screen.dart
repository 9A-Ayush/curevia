import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_overlay.dart';
import '../role_based_navigation.dart';

/// Role selection screen for new Google sign-in users
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRole = AppConstants.patientRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleRoleSelection() async {
    // Update user role in Firestore
    await ref.read(authProvider.notifier).updateUserRole(_selectedRole);

    // Check for errors
    final error = ref.read(authErrorProvider);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      ref.read(authProvider.notifier).clearError();
    } else if (mounted) {
      // Role updated successfully, navigate to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RoleBasedNavigation(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAuthLoadingProvider);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Header with App Icon
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.asset(
                                    'assets/icons/curevia_icon.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: ThemeUtils.getPrimaryColor(context),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: const Icon(
                                          Icons.local_hospital,
                                          size: 50,
                                          color: AppColors.textOnPrimary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Welcome to ${AppConstants.appName}!',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: ThemeUtils.getPrimaryColor(context),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'To provide you with the best experience, please tell us your role',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Role Selection Cards
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'I am a',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ThemeUtils.getTextPrimaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Patient Role Card
                              _buildRoleCard(
                                role: AppConstants.patientRole,
                                title: 'Patient',
                                description: 'I want to book appointments, consult doctors, and manage my health',
                                icon: Icons.person,
                                color: const Color(0xFF4CAF50),
                              ),

                              const SizedBox(height: 20),

                              // Doctor Role Card
                              _buildRoleCard(
                                role: AppConstants.doctorRole,
                                title: 'Doctor',
                                description: 'I want to manage appointments, consult patients, and provide healthcare',
                                icon: Icons.medical_services,
                                color: const Color(0xFF2196F3),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Continue Button
                        CustomButton(
                          text: 'Continue',
                          onPressed: _handleRoleSelection,
                          isLoading: isLoading,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1)
              : ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? color
                : ThemeUtils.getBorderLightColor(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Role Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? color
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected 
                    ? Colors.white
                    : color,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Role Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? color
                          : ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? color
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? color
                      : ThemeUtils.getBorderLightColor(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}