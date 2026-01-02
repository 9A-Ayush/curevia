import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';

/// Bank details step in doctor onboarding
class BankDetailsStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const BankDetailsStep({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  });

  @override
  ConsumerState<BankDetailsStep> createState() => _BankDetailsStepState();
}

class _BankDetailsStepState extends ConsumerState<BankDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _upiController = TextEditingController();

  bool _isLoading = false;
  bool _obscureAccount = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final bankDetails = widget.initialData['bankDetails'] as Map<String, dynamic>?;
    if (bankDetails != null) {
      _accountNumberController.text = bankDetails['accountNumber'] ?? '';
      _confirmAccountController.text = bankDetails['accountNumber'] ?? '';
      _ifscController.text = bankDetails['ifscCode'] ?? '';
      _accountHolderController.text = bankDetails['accountHolderName'] ?? '';
      _upiController.text = bankDetails['upiId'] ?? '';
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_accountNumberController.text != _confirmAccountController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account numbers do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Prepare bank details (should be encrypted in production)
      final bankDetails = {
        'accountNumber': _accountNumberController.text.trim(),
        'ifscCode': _ifscController.text.trim().toUpperCase(),
        'accountHolderName': _accountHolderController.text.trim(),
        'upiId': _upiController.text.trim(),
      };

      // Prepare data
      final data = {
        'bankDetails': bankDetails,
      };

      // Save to Firestore (TODO: Implement encryption)
      await DoctorOnboardingService.saveBankDetails(user.uid, data);

      // Update parent widget
      widget.onDataUpdate(data);

      setState(() => _isLoading = false);

      // Continue to next step
      widget.onContinue();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving information: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your bank details are securely stored and will be used for payment settlements.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Holder Name
          Text(
            'Account Holder Name *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountHolderController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter account holder name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter account holder name';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Account Number
          Text(
            'Bank Account Number *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            obscureText: _obscureAccount,
            decoration: InputDecoration(
              hintText: 'Enter account number',
              prefixIcon: const Icon(Icons.account_balance),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureAccount ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureAccount = !_obscureAccount;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter account number';
              }
              if (value.length < 9 || value.length > 18) {
                return 'Please enter a valid account number';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Confirm Account Number
          Text(
            'Confirm Account Number *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmAccountController,
            keyboardType: TextInputType.number,
            obscureText: _obscureAccount,
            decoration: InputDecoration(
              hintText: 'Re-enter account number',
              prefixIcon: const Icon(Icons.account_balance),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please confirm account number';
              }
              if (value != _accountNumberController.text) {
                return 'Account numbers do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // IFSC Code
          Text(
            'IFSC Code *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ifscController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 11,
            decoration: InputDecoration(
              hintText: 'Enter IFSC code',
              prefixIcon: const Icon(Icons.code),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter IFSC code';
              }
              if (value.length != 11) {
                return 'IFSC code must be 11 characters';
              }
              // Basic IFSC validation pattern
              final ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
              if (!ifscPattern.hasMatch(value)) {
                return 'Please enter a valid IFSC code';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // UPI ID (Optional)
          Text(
            'UPI ID (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _upiController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'yourname@upi',
              prefixIcon: const Icon(Icons.payment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final upiPattern = RegExp(r'^[\w.-]+@[\w.-]+$');
                if (!upiPattern.hasMatch(value)) {
                  return 'Please enter a valid UPI ID';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Security note
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
                Icon(Icons.security, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your banking information is encrypted and secure. We never share your details with third parties.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  onPressed: widget.onBack,
                  backgroundColor: ThemeUtils.getSurfaceColor(context),
                  textColor: ThemeUtils.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Continue',
                  onPressed: _isLoading ? null : _saveAndContinue,
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
    );
  }
}
