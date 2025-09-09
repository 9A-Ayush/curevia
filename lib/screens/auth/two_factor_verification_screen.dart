import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/auth/two_factor_service.dart';

/// Two-factor authentication verification screen
class TwoFactorVerificationScreen extends ConsumerStatefulWidget {
  final VoidCallback onVerificationSuccess;
  
  const TwoFactorVerificationScreen({
    super.key,
    required this.onVerificationSuccess,
  });

  @override
  ConsumerState<TwoFactorVerificationScreen> createState() => 
      _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState 
    extends ConsumerState<TwoFactorVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _backupCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _showBackupCodeInput = false;
  int _backupCodesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBackupCodesCount();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _backupCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBackupCodesCount() async {
    try {
      final count = await TwoFactorService.getBackupCodesCount();
      setState(() => _backupCodesCount = count);
    } catch (e) {
      print('Error loading backup codes count: $e');
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('Please enter a 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await TwoFactorService.verifyTOTP(code);
      
      if (isValid) {
        widget.onVerificationSuccess();
      } else {
        _showError('Invalid code. Please try again.');
      }
    } catch (e) {
      _showError('Verification failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyBackupCode() async {
    final code = _backupCodeController.text.trim();
    if (code.length != 8) {
      _showError('Please enter an 8-digit backup code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await TwoFactorService.verifyBackupCode(code);
      
      if (isValid) {
        // Show warning about backup code usage
        _showBackupCodeUsedDialog();
      } else {
        _showError('Invalid backup code. Please try again.');
      }
    } catch (e) {
      _showError('Verification failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showBackupCodeUsedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Backup Code Used'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have successfully logged in using a backup code.'),
            const SizedBox(height: 16),
            Text(
              'Remaining backup codes: ${_backupCodesCount - 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_backupCodesCount - 1 <= 2)
              const Text(
                'Warning: You have few backup codes left. Consider regenerating new ones.',
                style: TextStyle(color: AppColors.warning),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onVerificationSuccess();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.security,
                size: 40,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Enter Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _showBackupCodeInput
                  ? 'Enter your 8-digit backup code'
                  : 'Enter the 6-digit code from your authenticator app',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Code input
            if (!_showBackupCodeInput) ...[
              CustomTextField(
                controller: _codeController,
                label: 'Verification Code',
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) => _verifyCode(),
              ),
              
              const SizedBox(height: 24),
              
              CustomButton(
                text: 'Verify',
                onPressed: _verifyCode,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ] else ...[
              CustomTextField(
                controller: _backupCodeController,
                label: 'Backup Code',
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) => _verifyBackupCode(),
              ),
              
              const SizedBox(height: 24),
              
              CustomButton(
                text: 'Verify Backup Code',
                onPressed: _verifyBackupCode,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Toggle between code types
            TextButton(
              onPressed: () {
                setState(() {
                  _showBackupCodeInput = !_showBackupCodeInput;
                  _codeController.clear();
                  _backupCodeController.clear();
                });
              },
              child: Text(
                _showBackupCodeInput
                    ? 'Use authenticator code instead'
                    : 'Use backup code instead',
                style: TextStyle(
                  color: ThemeUtils.getPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            if (_showBackupCodeInput && _backupCodesCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeUtils.getWarningColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ThemeUtils.getWarningColor(context).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ThemeUtils.getWarningColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have $_backupCodesCount backup codes remaining. Each code can only be used once.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.isDarkMode(context)
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Having trouble?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Make sure your device time is correct\n• The code changes every 30 seconds\n• Use backup codes if you lost your device\n• Contact support if you need help',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
