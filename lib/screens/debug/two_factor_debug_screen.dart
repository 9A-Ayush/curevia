import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/theme_utils.dart';
import '../../services/auth/two_factor_service.dart';

/// Debug screen for two-factor authentication troubleshooting
class TwoFactorDebugScreen extends StatefulWidget {
  const TwoFactorDebugScreen({super.key});

  @override
  State<TwoFactorDebugScreen> createState() => _TwoFactorDebugScreenState();
}

class _TwoFactorDebugScreenState extends State<TwoFactorDebugScreen> {
  final TextEditingController _testCodeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _secret;
  String? _firestoreSecret;
  String? _localSecret;
  List<String>? _backupCodes;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _generatedCodes = {};

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      // Get secret from Firestore
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _firestoreSecret = data['twoFactorSecret'];
          _backupCodes = List<String>.from(data['backupCodes'] ?? []);
        }
      } catch (e) {
        print('Firestore error: $e');
      }

      // Get secret from local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        _localSecret = prefs.getString('two_factor_secret');
      } catch (e) {
        print('Local storage error: $e');
      }

      // Use the available secret
      _secret = _firestoreSecret ?? _localSecret;

      // Generate current codes if we have a secret
      if (_secret != null) {
        _generateCurrentCodes();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _generateCurrentCodes() {
    if (_secret == null) return;

    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Generate codes for current, previous, and next time windows
    final String currentCode = OTP.generateTOTPCodeString(
      _secret!,
      currentTime,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
    );

    final String previousCode = OTP.generateTOTPCodeString(
      _secret!,
      currentTime - 30,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
    );

    final String nextCode = OTP.generateTOTPCodeString(
      _secret!,
      currentTime + 30,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
    );

    setState(() {
      _generatedCodes = {
        'Previous (-30s)': previousCode,
        'Current': currentCode,
        'Next (+30s)': nextCode,
      };
    });
  }

  Future<void> _testCode() async {
    final code = _testCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final isValid = await TwoFactorService.verifyTOTP(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid ? 'Code is VALID ✓' : 'Code is INVALID ✗',
            ),
            backgroundColor: isValid ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Debug'),
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
                  if (_errorMessage != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: 24),
                  ],
                  _buildSecretInfo(),
                  const SizedBox(height: 24),
                  if (_secret != null) ...[
                    _buildGeneratedCodes(),
                    const SizedBox(height: 24),
                    _buildTestSection(),
                    const SizedBox(height: 24),
                  ],
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
                  Icons.security,
                  color: ThemeUtils.getPrimaryColor(context),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Two-Factor Debug',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Diagnose two-factor authentication issues',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secret Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Firestore Secret', _firestoreSecret ?? 'Not found'),
            _buildInfoRow('Local Secret', _localSecret ?? 'Not found'),
            _buildInfoRow('Active Secret', _secret ?? 'None'),
            _buildInfoRow('Backup Codes', '${_backupCodes?.length ?? 0} codes'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedCodes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated Codes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                IconButton(
                  onPressed: _generateCurrentCodes,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh codes',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._generatedCodes.entries.map((entry) => 
              _buildCodeRow(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeRow(String label, String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurfaceVariantColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy code',
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _testCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeUtils.getPrimaryColor(context),
                  foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
                ),
                child: const Text('Test Code'),
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
              'Troubleshooting Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTip('1. Check if your phone\'s time is synchronized'),
            _buildTip('2. Try using the generated codes above'),
            _buildTip('3. Ensure your authenticator app is using the correct secret'),
            _buildTip('4. Try codes from previous/next time windows'),
            _buildTip('5. Use backup codes if TOTP codes don\'t work'),
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

  @override
  void dispose() {
    _testCodeController.dispose();
    super.dispose();
  }
}
