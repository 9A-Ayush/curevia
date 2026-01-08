import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../services/ifsc_service.dart';
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

class _BankDetailsStepState extends ConsumerState<BankDetailsStep>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _upiController = TextEditingController();

  // Bank selection variables
  BankInfo? _selectedBank;
  String? _selectedState;
  String? _selectedDistrict;
  BranchInfo? _selectedBranch;
  
  // Auto-filled fields
  String? _ifscCode;
  String? _bankAddress;
  String? _micrCode;
  String? _bankCode;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingBanks = false;
  bool _isLoadingStates = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingBranches = false;
  bool _isLoadingIFSC = false;

  // Data lists
  List<BankInfo> _banks = [];
  List<String> _states = [];
  List<String> _districts = [];
  List<BranchInfo> _branches = [];

  bool _obscureAccount = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadBanks();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _accountHolderController.dispose();
    _upiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final bankDetails = widget.initialData['bankDetails'] as Map<String, dynamic>?;
    if (bankDetails != null) {
      _accountNumberController.text = bankDetails['accountNumber'] ?? '';
      _confirmAccountController.text = bankDetails['accountNumber'] ?? '';
      _accountHolderController.text = bankDetails['accountHolderName'] ?? '';
      _upiController.text = bankDetails['upiId'] ?? '';
      _ifscCode = bankDetails['ifscCode'];
      _bankAddress = bankDetails['bankAddress'];
      _micrCode = bankDetails['micrCode'];
      _bankCode = bankDetails['bankCode'];
      
      // Try to restore selected values if available
      final bankName = bankDetails['bankName'];
      if (bankName != null) {
        // Will be set after banks are loaded
      }
    }
  }

  Future<void> _loadBanks() async {
    setState(() => _isLoadingBanks = true);
    try {
      final banks = await IFSCService.getBanks();
      setState(() {
        _banks = banks;
        _isLoadingBanks = false;
      });
    } catch (e) {
      setState(() => _isLoadingBanks = false);
      _showErrorSnackBar('Failed to load banks: $e');
    }
  }

  Future<void> _loadStatesForBank(BankInfo bank) async {
    setState(() {
      _isLoadingStates = true;
      _selectedState = null;
      _selectedDistrict = null;
      _selectedBranch = null;
      _states.clear();
      _districts.clear();
      _branches.clear();
      _clearBankDetails();
    });

    try {
      final states = await IFSCService.getStatesForBank(bank.name);
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() => _isLoadingStates = false);
      _showErrorSnackBar('Failed to load states: $e');
    }
  }

  Future<void> _loadDistrictsForState(String state) async {
    if (_selectedBank == null) return;

    setState(() {
      _isLoadingDistricts = true;
      _selectedDistrict = null;
      _selectedBranch = null;
      _districts.clear();
      _branches.clear();
      _clearBankDetails();
    });

    try {
      final districts = await IFSCService.getDistrictsForBankAndState(
        bankName: _selectedBank!.name,
        state: state,
      );
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() => _isLoadingDistricts = false);
      _showErrorSnackBar('Failed to load districts: $e');
    }
  }

  Future<void> _loadBranchesForDistrict(String district) async {
    if (_selectedBank == null || _selectedState == null) return;

    setState(() {
      _isLoadingBranches = true;
      _selectedBranch = null;
      _branches.clear();
      _clearBankDetails();
    });

    try {
      final branches = await IFSCService.getBranches(
        bankName: _selectedBank!.name,
        state: _selectedState!,
        district: district,
      );
      setState(() {
        _branches = branches;
        _isLoadingBranches = false;
      });
    } catch (e) {
      setState(() => _isLoadingBranches = false);
      _showErrorSnackBar('Failed to load branches: $e');
    }
  }

  Future<void> _onBranchSelected(BranchInfo branch) async {
    setState(() {
      _selectedBranch = branch;
      _isLoadingIFSC = true;
    });

    try {
      // Auto-fill details from branch info
      setState(() {
        _ifscCode = branch.ifsc;
        _bankAddress = branch.address;
        _micrCode = branch.micr;
        _bankCode = branch.bankCode;
        _isLoadingIFSC = false;
      });
    } catch (e) {
      setState(() => _isLoadingIFSC = false);
      _showErrorSnackBar('Failed to load IFSC details: $e');
    }
  }

  void _clearBankDetails() {
    setState(() {
      _ifscCode = null;
      _bankAddress = null;
      _micrCode = null;
      _bankCode = null;
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ThemeUtils.getErrorColor(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  bool get _isFormValid {
    return _selectedBank != null &&
        _selectedState != null &&
        _selectedDistrict != null &&
        _selectedBranch != null &&
        _ifscCode != null &&
        _accountNumberController.text.isNotEmpty &&
        _confirmAccountController.text.isNotEmpty &&
        _accountHolderController.text.isNotEmpty &&
        _accountNumberController.text == _confirmAccountController.text;
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isFormValid) {
      _showErrorSnackBar('Please complete all required fields');
      return;
    }

    if (_accountNumberController.text != _confirmAccountController.text) {
      _showErrorSnackBar('Account numbers do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Prepare bank details
      final bankDetails = {
        'accountNumber': _accountNumberController.text.trim(),
        'accountHolderName': _accountHolderController.text.trim(),
        'bankName': _selectedBank!.name,
        'bankCode': _bankCode,
        'branchName': _selectedBranch!.name,
        'ifscCode': _ifscCode,
        'micrCode': _micrCode,
        'bankAddress': _bankAddress,
        'state': _selectedState,
        'district': _selectedDistrict,
        'upiId': _upiController.text.trim(),
      };

      // Prepare data
      final data = {
        'bankDetails': bankDetails,
      };

      // Save to Firestore
      await DoctorOnboardingService.saveBankDetails(user.uid, data);

      // Update parent widget
      widget.onDataUpdate(data);

      setState(() => _isLoading = false);

      // Continue to next step
      widget.onContinue();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Error saving information: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeUtils.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeUtils.getWarningColor(context).withOpacity(0.05),
            ThemeUtils.getWarningColor(context).withOpacity(0.02),
            ThemeUtils.getBackgroundColor(context),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated Header
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildSectionHeader(
                        'Bank Details',
                        'Secure payment information for settlements',
                        Icons.account_balance,
                        ThemeUtils.getWarningColor(context),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Security Info Banner
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: _buildInfoBanner(
                        'Your bank details are securely stored and encrypted. We never share your information with third parties.',
                        Icons.security,
                        ThemeUtils.getInfoColor(context),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Animated Form Fields
              ..._buildAnimatedFormFields(),

              const SizedBox(height: 24),

              // Bank Details Summary
              if (_selectedBranch != null && _ifscCode != null) ...[
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildBankSummaryCard(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Security Note
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildInfoBanner(
                        'Your banking information is encrypted and secure. We use industry-standard security measures.',
                        Icons.verified_user,
                        ThemeUtils.getSuccessColor(context),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Animated Buttons
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: _buildActionButtons(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildInfoBanner(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedFormFields() {
    final fields = [
      _buildAnimatedField(0, _buildAccountHolderField()),
      _buildAnimatedField(1, _buildAccountNumberField()),
      _buildAnimatedField(2, _buildConfirmAccountField()),
      _buildAnimatedField(3, _buildBankDropdown()),
      _buildAnimatedField(4, _buildStateDropdown()),
      _buildAnimatedField(5, _buildDistrictDropdown()),
      _buildAnimatedField(6, _buildBranchDropdown()),
      _buildAnimatedField(7, _buildUpiField()),
    ];

    return fields;
  }

  Widget _buildAnimatedField(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountHolderField() {
    return _buildStyledTextField(
      controller: _accountHolderController,
      label: 'Account Holder Name',
      hint: 'Enter account holder name',
      icon: Icons.person,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter account holder name';
        }
        return null;
      },
    );
  }

  Widget _buildAccountNumberField() {
    return _buildStyledTextField(
      controller: _accountNumberController,
      label: 'Bank Account Number',
      hint: 'Enter account number',
      icon: Icons.account_balance,
      keyboardType: TextInputType.number,
      obscureText: _obscureAccount,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureAccount ? Icons.visibility : Icons.visibility_off,
          color: ThemeUtils.getWarningColor(context),
        ),
        onPressed: () {
          setState(() {
            _obscureAccount = !_obscureAccount;
          });
        },
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
    );
  }

  Widget _buildConfirmAccountField() {
    return _buildStyledTextField(
      controller: _confirmAccountController,
      label: 'Confirm Account Number',
      hint: 'Re-enter account number',
      icon: Icons.account_balance,
      keyboardType: TextInputType.number,
      obscureText: _obscureAccount,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please confirm account number';
        }
        if (value != _accountNumberController.text) {
          return 'Account numbers do not match';
        }
        return null;
      },
    );
  }

  Widget _buildBankDropdown() {
    return _buildStyledDropdown<BankInfo>(
      label: 'Bank Name',
      hint: 'Select your bank',
      icon: Icons.account_balance,
      value: _selectedBank,
      items: _banks,
      isLoading: _isLoadingBanks,
      onChanged: (bank) {
        setState(() {
          _selectedBank = bank;
        });
        if (bank != null) {
          _loadStatesForBank(bank);
        }
      },
      itemBuilder: (bank) => Text(bank.name),
      validator: (value) {
        if (value == null) {
          return 'Please select a bank';
        }
        return null;
      },
    );
  }

  Widget _buildStateDropdown() {
    return _buildStyledDropdown<String>(
      label: 'State',
      hint: 'Select state',
      icon: Icons.location_on,
      value: _selectedState,
      items: _states,
      isLoading: _isLoadingStates,
      enabled: _selectedBank != null && !_isLoadingStates,
      onChanged: (state) {
        setState(() {
          _selectedState = state;
        });
        if (state != null) {
          _loadDistrictsForState(state);
        }
      },
      itemBuilder: (state) => Text(state),
      validator: (value) {
        if (value == null) {
          return 'Please select a state';
        }
        return null;
      },
    );
  }

  Widget _buildDistrictDropdown() {
    return _buildStyledDropdown<String>(
      label: 'District',
      hint: 'Select district',
      icon: Icons.location_city,
      value: _selectedDistrict,
      items: _districts,
      isLoading: _isLoadingDistricts,
      enabled: _selectedState != null && !_isLoadingDistricts,
      onChanged: (district) {
        setState(() {
          _selectedDistrict = district;
        });
        if (district != null) {
          _loadBranchesForDistrict(district);
        }
      },
      itemBuilder: (district) => Text(district),
      validator: (value) {
        if (value == null) {
          return 'Please select a district';
        }
        return null;
      },
    );
  }

  Widget _buildBranchDropdown() {
    return _buildStyledDropdown<BranchInfo>(
      label: 'Branch',
      hint: 'Select branch',
      icon: Icons.business,
      value: _selectedBranch,
      items: _branches,
      isLoading: _isLoadingBranches,
      enabled: _selectedDistrict != null && !_isLoadingBranches,
      onChanged: (branch) {
        if (branch != null) {
          _onBranchSelected(branch);
        }
      },
      itemBuilder: (branch) => Text(branch.name),
      validator: (value) {
        if (value == null) {
          return 'Please select a branch';
        }
        return null;
      },
    );
  }

  Widget _buildUpiField() {
    return _buildStyledTextField(
      controller: _upiController,
      label: 'UPI ID (Optional)',
      hint: 'yourname@upi',
      icon: Icons.payment,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final upiPattern = RegExp(r'^[\w.-]+@[\w.-]+$');
          if (!upiPattern.hasMatch(value)) {
            return 'Please enter a valid UPI ID';
          }
        }
        return null;
      },
    );
  }

  Widget _buildBankSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeUtils.getSuccessColor(context).withOpacity(0.1),
            ThemeUtils.getSuccessColor(context).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getSuccessColor(context).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ThemeUtils.getSuccessColor(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle, color: ThemeUtils.getSuccessColor(context), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bank Details Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ),
              if (_isLoadingIFSC)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Bank', _selectedBank?.name ?? ''),
          _buildSummaryRow('Branch', _selectedBranch?.name ?? ''),
          _buildSummaryRow('IFSC Code', _ifscCode ?? ''),
          if (_micrCode?.isNotEmpty == true)
            _buildSummaryRow('MICR Code', _micrCode ?? ''),
          if (_bankAddress?.isNotEmpty == true)
            _buildSummaryRow('Address', _bankAddress ?? ''),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ThemeUtils.getShadowLightColor(context),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            obscureText: obscureText,
            maxLength: maxLength,
            validator: validator,
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ThemeUtils.getTextHintColor(context)),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeUtils.getWarningColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ThemeUtils.getWarningColor(context), size: 20),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getWarningColor(context), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getErrorColor(context), width: 2),
              ),
              filled: true,
              fillColor: ThemeUtils.getSurfaceColor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: maxLength != null ? '' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
    String? Function(T?)? validator,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ThemeUtils.getShadowLightColor(context),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: itemBuilder(item),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
            validator: validator,
            decoration: InputDecoration(
              hintText: enabled ? hint : 'Please select previous field first',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeUtils.getWarningColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? ThemeUtils.getWarningColor(context) : ThemeUtils.getDisabledColor(context),
                  size: 20,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getWarningColor(context), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getErrorColor(context), width: 2),
              ),
              filled: true,
              fillColor: enabled ? ThemeUtils.getSurfaceColor(context) : ThemeUtils.getDisabledBackgroundColor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: enabled ? ThemeUtils.getWarningColor(context) : ThemeUtils.getDisabledColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
            ),
            child: TextButton(
              onPressed: widget.onBack,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Back',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThemeUtils.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ThemeUtils.getWarningColor(context), ThemeUtils.getWarningColor(context).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getWarningColor(context).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (_isLoading || !_isFormValid) ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}