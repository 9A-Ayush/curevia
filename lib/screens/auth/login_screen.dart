import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

import '../../services/auth/two_factor_service.dart';
import '../../services/auth/app_lifecycle_biometric_service.dart';
import '../role_based_navigation.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'two_factor_verification_screen.dart';
import 'role_selection_screen.dart';

/// Login screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isGoogleSignIn = false; // Track if this is a Google sign-in

  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');

      if (savedEmail != null) {
        setState(() {
          _savedEmail = savedEmail;
          _emailController.text = savedEmail;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe && _emailController.text.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', _emailController.text.trim());
      } catch (e) {
        print('Error saving credentials: $e');
      }
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await _saveCredentials();

      await ref
          .read(authProvider.notifier)
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Check for errors
      final error = ref.read(authErrorProvider);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        ref.read(authProvider.notifier).clearError();
      }
    }
  }

  Future<void> _checkTwoFactorAuthentication() async {
    try {
      final isTwoFactorEnabled = await TwoFactorService.isTwoFactorEnabled();

      if (isTwoFactorEnabled && mounted) {
        // Show two-factor verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TwoFactorVerificationScreen(
              onVerificationSuccess: () {
                // Set authentication state for biometric service
                AppLifecycleBiometricService.setAuthenticated(true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleBasedNavigation(),
                  ),
                );
              },
            ),
          ),
        );
      } else if (mounted) {
        // No two-factor authentication, check if we need role selection
        _navigateAfterAuthentication();
      }
    } catch (e) {
      print('Error checking two-factor authentication: $e');
      // Proceed to navigation if there's an error
      if (mounted) {
        _navigateAfterAuthentication();
      }
    }
  }

  void _navigateAfterAuthentication() {
    final userModel = ref.read(authProvider).userModel;
    
    // Check if user needs to select a role (empty or null role)
    if (userModel != null && (userModel.role.isEmpty || userModel.role == '')) {
      // User needs to select a role - navigate to role selection screen
      setState(() {
        _isGoogleSignIn = false; // Reset the flag
      });
      AppLifecycleBiometricService.setAuthenticated(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    } else {
      // User has a role - go to main app
      setState(() {
        _isGoogleSignIn = false; // Reset the flag
      });
      AppLifecycleBiometricService.setAuthenticated(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleBasedNavigation()),
      );
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isGoogleSignIn = true;
    });
    
    await ref.read(authProvider.notifier).signInWithGoogle();

    // Check for errors
    final error = ref.read(authErrorProvider);
    if (error != null && mounted) {
      setState(() {
        _isGoogleSignIn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      ref.read(authProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAuthLoadingProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Navigate to main app when authenticated
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (next && mounted) {
        _checkTwoFactorAuthentication();
      }
    });

    // Also check current state and navigate if already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isAuthenticated && mounted) {
        _checkTwoFactorAuthentication();
      }
    });

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // App Logo and Title
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
                                // Fallback to the old icon if image fails to load
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
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: ThemeUtils.getPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back! Sign in to continue',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(
                                  context,
                                ),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: ThemeUtils.getPrimaryColor(context),
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getPrimaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _handleLogin,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(
                                  context,
                                ),
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ThemeUtils.getPrimaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
