import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';

/// Practice information step in doctor onboarding
class PracticeInfoStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const PracticeInfoStep({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  });

  @override
  ConsumerState<PracticeInfoStep> createState() => _PracticeInfoStepState();
}

class _PracticeInfoStepState extends ConsumerState<PracticeInfoStep>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _onlineFeeController = TextEditingController();
  final _offlineFeeController = TextEditingController();

  List<String> _selectedLanguages = [];
  bool _isAvailableOnline = true;
  bool _isAvailableOffline = true;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _commonLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Urdu',
    'Odia',
    'Assamese',
    'Sanskrit',
  ];

  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Puducherry',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Lakshadweep',
    'Andaman and Nicobar Islands',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _onlineFeeController.dispose();
    _offlineFeeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    _clinicNameController.text = widget.initialData['clinicName'] ?? '';
    _clinicAddressController.text = widget.initialData['clinicAddress'] ?? '';
    _cityController.text = widget.initialData['city'] ?? '';
    _stateController.text = widget.initialData['state'] ?? '';
    _pincodeController.text = widget.initialData['pincode'] ?? '';
    _onlineFeeController.text = widget.initialData['onlineFee']?.toString() ?? '';
    _offlineFeeController.text = widget.initialData['offlineFee']?.toString() ?? '';
    _selectedLanguages = List<String>.from(widget.initialData['languages'] ?? []);
    _isAvailableOnline = widget.initialData['isAvailableOnline'] ?? true;
    _isAvailableOffline = widget.initialData['isAvailableOffline'] ?? true;
  }

  void _showStateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: ThemeUtils.getSecondaryColor(context), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Select State',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children: _indianStates.map((state) {
                return ListTile(
                  title: Text(
                    state,
                    style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                  ),
                  onTap: () {
                    setState(() {
                      _stateController.text = state;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagesDialog() {
    final tempLanguages = List<String>.from(_selectedLanguages);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeUtils.getSurfaceColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.language, color: ThemeUtils.getSecondaryColor(context), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Languages',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonLanguages.map((language) {
                  final isSelected = tempLanguages.contains(language);
                  return FilterChip(
                    label: Text(language),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          tempLanguages.add(language);
                        } else {
                          tempLanguages.remove(language);
                        }
                      });
                    },
                    selectedColor: ThemeUtils.getSecondaryColorWithOpacity(context, 0.2),
                    backgroundColor: ThemeUtils.getSurfaceVariantColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? ThemeUtils.getSecondaryColor(context) : ThemeUtils.getTextPrimaryColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? ThemeUtils.getSecondaryColor(context) : ThemeUtils.getBorderLightColor(context),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ThemeUtils.getSecondaryColor(context), ThemeUtils.getSecondaryColor(context).withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedLanguages = tempLanguages;
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  'Done',
                  style: TextStyle(color: ThemeUtils.getOnPrimaryColor(context), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isAvailableOnline && !_isAvailableOffline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one consultation mode'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Prepare data
      final data = {
        'clinicName': _clinicNameController.text.trim(),
        'clinicAddress': _clinicAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'onlineFee': _isAvailableOnline ? int.tryParse(_onlineFeeController.text.trim()) ?? 0 : 0,
        'offlineFee': _isAvailableOffline ? int.tryParse(_offlineFeeController.text.trim()) ?? 0 : 0,
        'languages': _selectedLanguages,
        'isAvailableOnline': _isAvailableOnline,
        'isAvailableOffline': _isAvailableOffline,
      };

      // Save to Firestore
      await DoctorOnboardingService.savePracticeInfo(user.uid, data);

      // Update parent widget
      widget.onDataUpdate(data);

      setState(() => _isLoading = false);

      // Continue to next step
      widget.onContinue();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving information: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
            ThemeUtils.getSecondaryColorWithOpacity(context, 0.05),
            ThemeUtils.getSecondaryColorWithOpacity(context, 0.02),
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
                        'Practice Information',
                        'Setup your clinic and consultation details',
                        Icons.local_hospital,
                        ThemeUtils.getSecondaryColor(context),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Animated Form Fields
              ..._buildAnimatedFormFields(),

              const SizedBox(height: 32),

              // Animated Buttons
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1600),
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
            child: Icon(icon, color: ThemeUtils.getOnPrimaryColor(context), size: 24),
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

  List<Widget> _buildAnimatedFormFields() {
    final fields = [
      _buildAnimatedField(0, _buildClinicNameField()),
      _buildAnimatedField(1, _buildClinicAddressField()),
      _buildAnimatedField(2, _buildCityField()),
      _buildAnimatedField(3, _buildStateField()),
      _buildAnimatedField(4, _buildPincodeField()),
      _buildAnimatedField(5, _buildConsultationModeSection()),
      _buildAnimatedField(6, _buildLanguagesField()),
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

  Widget _buildClinicNameField() {
    return _buildStyledTextField(
      controller: _clinicNameController,
      label: 'Clinic/Hospital Name',
      hint: 'Enter clinic or hospital name',
      icon: Icons.local_hospital,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter clinic/hospital name';
        }
        return null;
      },
    );
  }

  Widget _buildClinicAddressField() {
    return _buildStyledTextField(
      controller: _clinicAddressController,
      label: 'Clinic Address',
      hint: 'Enter complete clinic address',
      icon: Icons.location_on,
      maxLines: 2,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter clinic address';
        }
        return null;
      },
    );
  }

  Widget _buildCityField() {
    return _buildStyledTextField(
      controller: _cityController,
      label: 'City',
      hint: 'Enter city name',
      icon: Icons.location_city,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter city name';
        }
        return null;
      },
    );
  }

  Widget _buildStateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State *',
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _showStateDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                border: Border.all(
                  color: ThemeUtils.isDarkMode(context) 
                      ? AppColors.darkBorderLight 
                      : AppColors.borderLight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on, color: ThemeUtils.getSecondaryColor(context), size: 20),
                  ),
                  Expanded(
                    child: Text(
                      _stateController.text.isEmpty
                          ? 'Select state'
                          : _stateController.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _stateController.text.isNotEmpty
                            ? ThemeUtils.getTextPrimaryColor(context)
                            : ThemeUtils.getTextSecondaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPincodeField() {
    return _buildStyledTextField(
      controller: _pincodeController,
      label: 'Pincode',
      hint: 'Enter pincode',
      icon: Icons.pin_drop,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter pincode';
        }
        if (value.length != 6) {
          return 'Please enter a valid 6-digit pincode';
        }
        return null;
      },
    );
  }

  Widget _buildConsultationModeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.2)),
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
                  color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.video_call, color: ThemeUtils.getSecondaryColor(context), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation Modes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    Text(
                      'Select available consultation types',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Online Consultation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAvailableOnline 
                  ? ThemeUtils.getSecondaryColorWithOpacity(context, 0.1)
                  : ThemeUtils.getSurfaceVariantColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAvailableOnline 
                    ? ThemeUtils.getSecondaryColor(context).withOpacity(0.3)
                    : ThemeUtils.getBorderLightColor(context),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_call,
                      color: _isAvailableOnline ? ThemeUtils.getSecondaryColor(context) : ThemeUtils.getDisabledColor(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Online Consultation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                    Switch(
                      value: _isAvailableOnline,
                      onChanged: (value) => setState(() => _isAvailableOnline = value ?? false),
                      activeColor: AppColors.secondary,
                    ),
                  ],
                ),
                if (_isAvailableOnline) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _onlineFeeController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                    decoration: InputDecoration(
                      labelText: 'Online Consultation Fee (₹)',
                      labelStyle: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
                      hintText: 'Enter fee amount',
                      hintStyle: TextStyle(color: ThemeUtils.getTextHintColor(context)),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getSecondaryColor(context), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getErrorColor(context)),
                      ),
                      filled: true,
                      fillColor: ThemeUtils.getSurfaceColor(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: _isAvailableOnline ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter online consultation fee';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    } : null,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Offline Consultation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAvailableOffline 
                  ? ThemeUtils.getSecondaryColorWithOpacity(context, 0.1)
                  : ThemeUtils.getSurfaceVariantColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAvailableOffline 
                    ? ThemeUtils.getSecondaryColor(context).withOpacity(0.3)
                    : ThemeUtils.getBorderLightColor(context),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: _isAvailableOffline ? ThemeUtils.getSecondaryColor(context) : ThemeUtils.getDisabledColor(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'In-Person Consultation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                    Switch(
                      value: _isAvailableOffline,
                      onChanged: (value) => setState(() => _isAvailableOffline = value ?? false),
                      activeColor: AppColors.secondary,
                    ),
                  ],
                ),
                if (_isAvailableOffline) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _offlineFeeController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                    decoration: InputDecoration(
                      labelText: 'In-Person Consultation Fee (₹)',
                      labelStyle: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
                      hintText: 'Enter fee amount',
                      hintStyle: TextStyle(color: ThemeUtils.getTextHintColor(context)),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getBorderLightColor(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getSecondaryColor(context), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ThemeUtils.getErrorColor(context)),
                      ),
                      filled: true,
                      fillColor: ThemeUtils.getSurfaceColor(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: _isAvailableOffline ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter in-person consultation fee';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    } : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages Spoken',
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
                color: isDarkMode 
                    ? AppColors.darkShadowLight 
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _showLanguagesDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : Colors.white,
                border: Border.all(
                  color: isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.language, color: ThemeUtils.getSecondaryColor(context), size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _selectedLanguages.isEmpty
                              ? 'Select languages you speak'
                              : '${_selectedLanguages.length} languages selected',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _selectedLanguages.isNotEmpty
                                ? ThemeUtils.getTextPrimaryColor(context)
                                : ThemeUtils.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                    ],
                  ),
                  if (_selectedLanguages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedLanguages.map((lang) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLanguages.remove(lang);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    int maxLines = 1,
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
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ThemeUtils.getTextHintColor(context)),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSecondaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ThemeUtils.getSecondaryColor(context), size: 20),
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
                borderSide: BorderSide(color: ThemeUtils.getSecondaryColor(context), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ThemeUtils.getErrorColor(context), width: 2),
              ),
              filled: true,
              fillColor: ThemeUtils.getSurfaceColor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                colors: [ThemeUtils.getSecondaryColor(context), ThemeUtils.getSecondaryColor(context).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getSecondaryColor(context).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(ThemeUtils.getOnPrimaryColor(context)),
                      ),
                    )
                  : Text(
                      'Continue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ThemeUtils.getOnPrimaryColor(context),
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