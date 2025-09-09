import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../services/auth/biometric_service.dart';

/// Debug screen for biometric authentication troubleshooting
class BiometricDebugScreen extends StatefulWidget {
  const BiometricDebugScreen({super.key});

  @override
  State<BiometricDebugScreen> createState() => _BiometricDebugScreenState();
}

class _BiometricDebugScreenState extends State<BiometricDebugScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool? _isDeviceSupported;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check device support
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      // Check if biometrics can be checked
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _isDeviceSupported = isDeviceSupported;
        _canCheckBiometrics = canCheckBiometrics;
        _availableBiometrics = availableBiometrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthentication() async {
    try {
      setState(() => _isLoading = true);

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Test fingerprint authentication',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              didAuthenticate
                  ? 'Authentication successful!'
                  : 'Authentication failed',
            ),
            backgroundColor: didAuthenticate
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.code} - ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Debug'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDiagnosticResults(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildTroubleshootingTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: ThemeUtils.getPrimaryColor(context),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Biometric Diagnostics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This screen helps diagnose fingerprint sensor issues',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              _buildResultItem(
                'Error',
                _errorMessage!,
                Icons.error,
                AppColors.error,
              ),
            ] else ...[
              _buildResultItem(
                'Device Supported',
                _isDeviceSupported?.toString() ?? 'Unknown',
                _isDeviceSupported == true ? Icons.check_circle : Icons.cancel,
                _isDeviceSupported == true
                    ? AppColors.success
                    : AppColors.error,
              ),

              _buildResultItem(
                'Can Check Biometrics',
                _canCheckBiometrics?.toString() ?? 'Unknown',
                _canCheckBiometrics == true ? Icons.check_circle : Icons.cancel,
                _canCheckBiometrics == true
                    ? AppColors.success
                    : AppColors.error,
              ),

              _buildResultItem(
                'Available Biometrics',
                _availableBiometrics?.map((e) => e.name).join(', ') ?? 'None',
                _availableBiometrics?.isNotEmpty == true
                    ? Icons.check_circle
                    : Icons.cancel,
                _availableBiometrics?.isNotEmpty == true
                    ? AppColors.success
                    : AppColors.warning,
              ),

              _buildResultItem(
                'Fingerprint Available',
                _availableBiometrics
                        ?.contains(BiometricType.fingerprint)
                        .toString() ??
                    'Unknown',
                _availableBiometrics?.contains(BiometricType.fingerprint) ==
                        true
                    ? Icons.check_circle
                    : Icons.cancel,
                _availableBiometrics?.contains(BiometricType.fingerprint) ==
                        true
                    ? AppColors.success
                    : AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Diagnostics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeUtils.getPrimaryColor(context),
                  foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _availableBiometrics?.isNotEmpty == true
                    ? _testAuthentication
                    : null,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Test Authentication'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Troubleshooting Steps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),

            _buildTip('1. Go to Settings → Security → Fingerprint'),
            _buildTip('2. Add at least one fingerprint if none exist'),
            _buildTip('3. Test fingerprint with device lock screen'),
            _buildTip('4. Clean the fingerprint sensor with a soft cloth'),
            _buildTip('5. Restart the app and try again'),
            _buildTip('6. Check if other apps can use fingerprint'),
            _buildTip('7. Restart your phone if issues persist'),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If "Device Supported" shows false, your device may not have a fingerprint sensor.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
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

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: ThemeUtils.getTextSecondaryColor(context),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
