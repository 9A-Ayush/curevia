import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// Forgot password screen for password reset
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .sendPasswordResetEmail(email: _emailController.text.trim());

      // Check for errors
      final error = ref.read(authErrorProvider);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        ref.read(authProvider.notifier).clearError();
      } else if (mounted) {
        // Email sent successfully
        setState(() {
          _emailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _handleResendEmail() {
    setState(() {
      _emailSent = false;
    });
    _handleSendResetEmail();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAuthLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon and Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ThemeUtils.getPrimaryColorWithOpacity(
                            context,
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: 40,
                          color: ThemeUtils.getPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _emailSent ? 'Check Your Email' : 'Forgot Password?',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: ThemeUtils.getPrimaryColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _emailSent
                            ? 'We\'ve sent a password reset link to your email address. Please check your inbox and follow the instructions.'
                            : 'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                if (!_emailSent) ...[
                  // Email Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          textInputAction: TextInputAction.done,
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

                        const SizedBox(height: 32),

                        // Send Reset Email Button
                        CustomButton(
                          text: 'Send Reset Link',
                          onPressed: _handleSendResetEmail,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Email Sent Success State
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email Sent Successfully',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check your email: ${_emailController.text}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              ThemeUtils.getTextSecondaryColor(
                                                context,
                                              ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Resend Email Button
                      CustomButton(
                        text: 'Resend Email',
                        onPressed: _handleResendEmail,
                        isOutlined: true,
                      ),

                      const SizedBox(height: 16),

                      // Open Email App Button
                      CustomButton(
                        text: 'Open Email App',
                        onPressed: () {
                          // TODO: Open email app
                        },
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back to Sign In',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Help Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getSurfaceVariantColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Need Help?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you don\'t receive the email within a few minutes, please check your spam folder or contact our support team.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // TODO: Open support
                        },
                        child: Text(
                          'Contact Support',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getPrimaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
