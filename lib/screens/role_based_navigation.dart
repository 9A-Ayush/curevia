import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../utils/theme_utils.dart';
import 'main_navigation.dart';
import 'doctor/doctor_main_navigation.dart';
import 'auth/login_screen.dart';

/// Role-based navigation wrapper that routes users to appropriate interface
class RoleBasedNavigation extends ConsumerStatefulWidget {
  const RoleBasedNavigation({super.key});

  @override
  ConsumerState<RoleBasedNavigation> createState() => _RoleBasedNavigationState();
}

class _RoleBasedNavigationState extends ConsumerState<RoleBasedNavigation> {
  bool _hasTimedOut = false;

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
