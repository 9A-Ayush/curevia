import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/biometric_service.dart';

/// Privacy and security settings screen
class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  bool _biometricEnabled = false;
  bool _dataSharing = true;
  bool _analyticsEnabled = true;
  bool _marketingEmails = false;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final biometricEnabled = await BiometricService.isBiometricEnabled();

      setState(() {
        _biometricEnabled = biometricEnabled;
      });
    } catch (e) {
      print('Error loading security settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(context),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeUtils.getBackgroundColor(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSecuritySection(),
                      const SizedBox(height: 30),
                      _buildPrivacySection(),
                      const SizedBox(height: 30),
                      _buildDataSection(),
                      const SizedBox(height: 30),
                      _buildAccountSection(),
                    ],
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & Security',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your privacy and security settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Security',
      icon: Icons.security,
      children: [
        _buildSwitchTile(
          title: 'Biometric Authentication',
          subtitle: 'Use fingerprint or face ID to unlock the app',
          value: _biometricEnabled,
          onChanged: _toggleBiometric,
          icon: Icons.fingerprint,
        ),
        _buildActionTile(
          title: 'Change Password',
          subtitle: 'Update your account password',
          icon: Icons.lock_outline,
          onTap: () => _showChangePasswordDialog(),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Privacy',
      icon: Icons.privacy_tip,
      children: [
        _buildSwitchTile(
          title: 'Data Sharing',
          subtitle: 'Share anonymized data to improve our services',
          value: _dataSharing,
          onChanged: (value) async {
            setState(() => _dataSharing = value);
            await _savePrivacySettings();
          },
          icon: Icons.share,
        ),
        _buildSwitchTile(
          title: 'Analytics',
          subtitle: 'Help us improve the app with usage analytics',
          value: _analyticsEnabled,
          onChanged: (value) async {
            setState(() => _analyticsEnabled = value);
            await _savePrivacySettings();
          },
          icon: Icons.analytics,
        ),
        _buildActionTile(
          title: 'Download My Data',
          subtitle: 'Get a copy of your personal data',
          icon: Icons.download,
          onTap: () => _showDownloadDataDialog(),
        ),
        _buildActionTile(
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          icon: Icons.policy,
          onTap: () => _showPrivacyPolicy(),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          title: 'Push Notifications',
          subtitle: 'Receive notifications about appointments and health tips',
          value: _pushNotifications,
          onChanged: (value) async {
            setState(() => _pushNotifications = value);
            await _savePrivacySettings();
          },
          icon: Icons.notifications_active,
        ),
        _buildSwitchTile(
          title: 'Marketing Emails',
          subtitle: 'Receive promotional emails and health newsletters',
          value: _marketingEmails,
          onChanged: (value) async {
            setState(() => _marketingEmails = value);
            await _savePrivacySettings();
          },
          icon: Icons.email,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      icon: Icons.account_circle,
      children: [
        _buildActionTile(
          title: 'Deactivate Account',
          subtitle: 'Temporarily disable your account',
          icon: Icons.pause_circle_outline,
          onTap: () => _showDeactivateAccountDialog(),
          isDestructive: true,
        ),
        _buildActionTile(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account and all data',
          icon: Icons.delete_forever,
          onTap: () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: ThemeUtils.getPrimaryColor(context),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: ThemeUtils.getTextSecondaryColor(context)),
        activeColor: ThemeUtils.getPrimaryColor(context),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? AppColors.error : null),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
        ),
        leading: Icon(
          icon,
          color: isDestructive
              ? AppColors.error
              : ThemeUtils.getTextSecondaryColor(context),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: ThemeUtils.getTextSecondaryColor(context),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 6 characters'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          final credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPasswordController.text,
                          );
                          await user.reauthenticateWithCredential(credential);
                          await user.updatePassword(newPasswordController.text);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDataDialog() {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Download My Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We will prepare a copy of your data including:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text('• Personal profile information'),
              const Text('• Medical records and reports'),
              const Text('• Family member information'),
              const Text('• Appointment history'),
              const Text('• Privacy and security settings'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The download link will be sent to your registered email address.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        await _requestDataDownload();

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Data export request submitted. You will receive an email with the download link within 24 hours.',
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to request data export: $e',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request Download'),
            ),
          ],
        ),
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
            'Curevia Privacy Policy\n\n'
            'We are committed to protecting your privacy and personal health information. '
            'Your medical data is encrypted and stored securely. We do not share your '
            'personal information with third parties without your explicit consent.\n\n'
            'For the complete privacy policy, please visit our website.',
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

  void _showDeactivateAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
          'Are you sure you want to deactivate your account? You can reactivate it anytime by logging in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deactivation will be available soon'),
                ),
              );
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('Delete Account'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone!',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deleting your account will permanently remove:\n'
                  '• All your medical records\n'
                  '• Family member information\n'
                  '• Appointment history\n'
                  '• All personal data',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Enter your password to confirm',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your password'),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        await _deleteAccount(passwordController.text);

                        if (mounted) {
                          Navigator.pop(context);
                          // Navigate to login screen
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete account: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  /// Delete user account
  Future<void> _deleteAccount(String password) async {
    try {
      final user = ref.read(authProvider).firebaseUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate user with password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete account using auth provider
      await ref.read(authProvider.notifier).deleteAccount();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Toggle biometric authentication
  Future<void> _toggleBiometric(bool enabled) async {
    try {
      if (enabled) {
        // Check if biometric authentication is available
        final isAvailable = await BiometricService.isAvailable();
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric authentication is not available on this device',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Get available biometric types to show user what's available
        final availableBiometrics =
            await BiometricService.getAvailableBiometrics();
        final biometricNames =
            await BiometricService.getAvailableBiometricNames();

        if (availableBiometrics.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No biometric authentication methods are enrolled on this device. Please set up fingerprint, face unlock, or other biometric authentication in your device settings.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Enable biometric authentication
        final success = await BiometricService.enableBiometric();
        if (success) {
          setState(() => _biometricEnabled = true);
          if (mounted) {
            final availableTypes = biometricNames.isNotEmpty
                ? biometricNames.join(', ')
                : 'biometric authentication';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$availableTypes enabled successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else {
        // Disable biometric authentication
        await BiometricService.disableBiometric();
        setState(() => _biometricEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication disabled'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }



  /// Request data download
  Future<void> _requestDataDownload() async {
    try {
      final user = ref.read(authProvider).firebaseUser;
      if (user == null) throw Exception('No user logged in');

      // Simulate data export request
      // In a real implementation, this would trigger a backend process
      // to collect user data and send an email with download link
      await Future.delayed(const Duration(seconds: 2));

      // For now, just simulate success
      // In production, this would make an API call to request data export
    } catch (e) {
      throw Exception('Failed to request data export: $e');
    }
  }

  /// Save privacy settings
  Future<void> _savePrivacySettings() async {
    try {
      final user = ref.read(authProvider).firebaseUser;
      if (user == null) return;

      // Save privacy settings to user preferences
      // This would typically be saved to Firestore or user preferences
      final settings = {
        'dataSharing': _dataSharing,
        'analyticsEnabled': _analyticsEnabled,
        'marketingEmails': _marketingEmails,
        'pushNotifications': _pushNotifications,
        'biometricEnabled': _biometricEnabled,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // In a real implementation, save to Firestore
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(user.uid)
      //     .update({'privacySettings': settings});

      print('Privacy settings saved: $settings');
    } catch (e) {
      throw Exception('Failed to save privacy settings: $e');
    }
  }
}
