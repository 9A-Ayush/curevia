import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../utils/theme_utils.dart';
import 'main_navigation.dart';
import 'doctor/doctor_main_navigation.dart';
import 'doctor/onboarding/doctor_onboarding_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'permissions/permission_wrapper.dart';

/// Role-based navigation wrapper that routes users to appropriate interface
class RoleBasedNavigation extends ConsumerStatefulWidget {
  const RoleBasedNavigation({super.key});

  @override
  ConsumerState<RoleBasedNavigation> createState() =>
      _RoleBasedNavigationState();
}

class _RoleBasedNavigationState extends ConsumerState<RoleBasedNavigation> {
  bool _hasTimedOut = false;
  bool _isCheckingDoctorStatus = false;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    // Set a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
      }
    });
  }

  Future<bool> _checkDoctorOnboardingStatus(String doctorId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      
      if (!doc.exists) {
        // Doctor document doesn't exist, needs onboarding
        print('DEBUG: Doctor document does not exist - showing onboarding');
        return false;
      }
      
      final data = doc.data();
      
      // Check if doctor has completed onboarding by verifying essential fields
      // These fields are only set after completing all onboarding steps
      final hasRegistrationNumber = data?['registrationNumber'] != null && 
                                     (data!['registrationNumber'] as String).isNotEmpty;
      final hasSpecialty = data?['specialty'] != null && 
                          (data!['specialty'] as String).isNotEmpty;
      final hasVerificationStatus = data?['verificationStatus'] != null;
      final hasOnboardingCompleted = data?['onboardingCompleted'] == true;
      
      print('DEBUG: hasRegistrationNumber: $hasRegistrationNumber');
      print('DEBUG: hasSpecialty: $hasSpecialty');
      print('DEBUG: hasVerificationStatus: $hasVerificationStatus');
      print('DEBUG: hasOnboardingCompleted: $hasOnboardingCompleted');
      
      // Doctor has completed onboarding if they have:
      // 1. Registration number (from professional details)
      // 2. Specialty (from professional details)
      // 3. Verification status set (from submission)
      // OR explicitly marked as onboarding completed
      final result = (hasRegistrationNumber && hasSpecialty && hasVerificationStatus) || 
             hasOnboardingCompleted;
      
      print('DEBUG: Onboarding completed: $result');
      return result;
    } catch (e) {
      print('Error checking doctor onboarding status: $e');
      return false; // Default to showing onboarding if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show loading while checking authentication (with timeout)
    if (authState.isLoading && !_hasTimedOut) {
      return Scaffold(
        backgroundColor: ThemeUtils.getBackgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If not authenticated, show login
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // If authenticated but no user model after timeout, try to refresh or proceed with default
    if (authState.userModel == null) {
      if (_hasTimedOut) {
        // Timeout reached, try to refresh user data one more time
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(authProvider.notifier).refreshUserData();
        });

        // Show error with retry option
        return Scaffold(
          backgroundColor: ThemeUtils.getBackgroundColor(context),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ThemeUtils.getErrorColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load user profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There was a problem loading your profile data. Please check your internet connection.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasTimedOut = false;
                      });
                      ref.read(authProvider.notifier).refreshUserData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // Proceed to main navigation anyway with default role
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainNavigation(),
                        ),
                      );
                    },
                    child: const Text('Continue Anyway'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Still loading, show loading screen
      return Scaffold(
        backgroundColor: ThemeUtils.getBackgroundColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading user profile...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Route based on user role
    final userRole = authState.userModel!.role;

    // For doctors, check onboarding status first
    if (userRole == AppConstants.doctorRole) {
      return FutureBuilder<bool>(
        future: _checkDoctorOnboardingStatus(authState.userModel!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: ThemeUtils.getBackgroundColor(context),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final hasCompletedOnboarding = snapshot.data ?? false;

          if (!hasCompletedOnboarding) {
            // Show onboarding screen
            return const DoctorOnboardingScreen();
          }

          // Onboarding completed, show main navigation
          return PermissionWrapper(
            userRole: userRole,
            child: const DoctorMainNavigation(),
          );
        },
      );
    }

    // For other roles, route normally with permission check
    switch (userRole) {
      case AppConstants.patientRole:
        return PermissionWrapper(
          userRole: userRole,
          child: const MainNavigation(),
        );
      case AppConstants.adminRole:
        // Admin doesn't need permissions
        return const AdminDashboardScreen();
      default:
        // Unknown role, fallback to patient interface
        return PermissionWrapper(
          userRole: AppConstants.patientRole,
          child: const MainNavigation(),
        );
    }
  }
}
