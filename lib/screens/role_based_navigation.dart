import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../utils/theme_utils.dart';
import 'main_navigation.dart';
import 'doctor/doctor_main_navigation.dart';
import 'auth/login_screen.dart';

/// Role-based navigation wrapper that routes users to appropriate interface
class RoleBasedNavigation extends ConsumerWidget {
  const RoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading while checking authentication
    if (authState.isLoading) {
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

    // If authenticated but no user model, show loading
    if (authState.userModel == null) {
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
    
    switch (userRole) {
      case AppConstants.doctorRole:
        return const DoctorMainNavigation();
      case AppConstants.patientRole:
        return const MainNavigation();
      case AppConstants.adminRole:
        // TODO: Create admin interface
        return const MainNavigation(); // Fallback to patient interface for now
      default:
        // Unknown role, fallback to patient interface
        return const MainNavigation();
    }
  }
}
