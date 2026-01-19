import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';

/// Additional information step in doctor onboarding
class AdditionalInfoStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const AdditionalInfoStep({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  });

  @override
  ConsumerState<AdditionalInfoStep> createState() =>
      _AdditionalInfoStepState();
}

class _AdditionalInfoStepState extends ConsumerState<AdditionalInfoStep>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _aboutController = TextEditingController();
  final _awardsController = TextEditingController();
  final _membershipsController = TextEditingController();

  List<String> _services = [];
  List<String> _conditionsTreated = [];
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _commonServices = [
    'General Consultation',
    'Health Checkup',
    'Vaccination',
    'Diagnostic Services',
    'Emergency Care',
    'Home Visit',
    'Telemedicine',
    'Prescription Refill',
    'Health Counseling',
    'Chronic Disease Management',
  ];

  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Thyroid Disorders',
    'Heart Disease',
    'Arthritis',
    'Skin Conditions',
    'Digestive Issues',
    'Respiratory Problems',
    'Mental Health',
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
    _aboutController.dispose();
    _awardsController.dispose();
    _membershipsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    _aboutController.text = widget.initialData['about'] ?? '';
    _services = List<String>.from(widget.initialData['services'] ?? []);
    _conditionsTreated =
        List<String>.from(widget.initialData['conditionsTreated'] ?? []);
    
    final awards = widget.initialData['awards'] as List<String>?;
    if (awards != null && awards.isNotEmpty) {
      _awardsController.text = awards.join('\n');
    }
    
    final memberships = widget.initialData['memberships'] as List<String>?;
    if (memberships != null && memberships.isNotEmpty) {
      _membershipsController.text = memberships.join('\n');
    }
  }

  void _showServicesDialog() {
    final tempServices = List<String>.from(_services);

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
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.medical_services, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Services',
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
                children: _commonServices.map((service) {
                  final isSelected = tempServices.contains(service);
                  return FilterChip(
                    label: Text(service),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          tempServices.add(service);
                        } else {
                          tempServices.remove(service);
                        }
                      });
                    },
                    selectedColor: AppColors.info.withOpacity(0.2),
                    backgroundColor: ThemeUtils.getSurfaceVariantColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.info : ThemeUtils.getTextPrimaryColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.info : ThemeUtils.getBorderLightColor(context),
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
                  colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _services = tempServices;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionsDialog() {
    final tempConditions = List<String>.from(_conditionsTreated);

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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.healing, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Conditions Treated',
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
                children: _commonConditions.map((condition) {
                  final isSelected = tempConditions.contains(condition);
                  return FilterChip(
                    label: Text(condition),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          tempConditions.add(condition);
                        } else {
                          tempConditions.remove(condition);
                        }
                      });
                    },
                    selectedColor: AppColors.success.withOpacity(0.2),
                    backgroundColor: ThemeUtils.getSurfaceVariantColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.success : ThemeUtils.getTextPrimaryColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.success : ThemeUtils.getBorderLightColor(context),
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
                  colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _conditionsTreated = tempConditions;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Parse awards and memberships
      final awards = _awardsController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final memberships = _membershipsController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      // Prepare data
      final data = {
        'about': _aboutController.text.trim(),
        'services': _services,
        'conditionsTreated': _conditionsTreated,
        'awards': awards,
        'memberships': memberships,
      };

      // Save to Firestore
      await DoctorOnboardingService.saveAdditionalInfo(user.uid, data);

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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.05),
            AppColors.info.withOpacity(0.02),
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
                        'Additional Information',
                        'Complete your professional profile',
                        Icons.person_add,
                        AppColors.info,
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
            color: Colors.black.withOpacity(0.05),
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

  List<Widget> _buildAnimatedFormFields() {
    final fields = [
      _buildAnimatedField(0, _buildAboutField()),
      _buildAnimatedField(1, _buildServicesField()),
      _buildAnimatedField(2, _buildConditionsField()),
      _buildAnimatedField(3, _buildAwardsField()),
      _buildAnimatedField(4, _buildMembershipsField()),
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
              padding: const EdgeInsets.only(bottom: 24),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutField() {
    return _buildStyledTextField(
      controller: _aboutController,
      label: 'About You',
      hint: 'Write a brief description about yourself, your expertise, and approach to patient care...',
      icon: Icons.person,
      maxLines: 5,
      maxLength: 500,
      isRequired: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please write about yourself';
        }
        if (value.trim().length < 50) {
          return 'Please write at least 50 characters';
        }
        return null;
      },
    );
  }

  Widget _buildServicesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Services Offered',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Optional',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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
            onTap: _showServicesDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
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
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medical_services, color: AppColors.info, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _services.isEmpty
                              ? 'Select services you offer'
                              : '${_services.length} services selected',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _services.isNotEmpty
                                ? ThemeUtils.getTextPrimaryColor(context)
                                : ThemeUtils.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.info),
                    ],
                  ),
                  if (_services.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _services
                          .map(
                            (service) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.info.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    service,
                                    style: TextStyle(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _services.remove(service);
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
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

  Widget _buildConditionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Conditions Treated',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
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
            onTap: _showConditionsDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
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
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.healing, color: AppColors.success, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _conditionsTreated.isEmpty
                              ? 'Select conditions you treat'
                              : '${_conditionsTreated.length} conditions selected',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _conditionsTreated.isNotEmpty
                                ? ThemeUtils.getTextPrimaryColor(context)
                                : ThemeUtils.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.success),
                    ],
                  ),
                  if (_conditionsTreated.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _conditionsTreated
                          .map(
                            (condition) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.success.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    condition,
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _conditionsTreated.remove(condition);
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
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

  Widget _buildAwardsField() {
    return _buildStyledTextField(
      controller: _awardsController,
      label: 'Awards & Recognitions',
      hint: 'Enter each award on a new line',
      icon: Icons.emoji_events,
      maxLines: 3,
      isRequired: false,
    );
  }

  Widget _buildMembershipsField() {
    return _buildStyledTextField(
      controller: _membershipsController,
      label: 'Professional Memberships',
      hint: 'Enter each membership on a new line',
      icon: Icons.card_membership,
      maxLines: 3,
      isRequired: false,
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isRequired ? '$label *' : label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            if (!isRequired) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Optional',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.info, size: 20),
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
                borderSide: BorderSide(color: AppColors.info, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.error, width: 2),
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
                colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withOpacity(0.3),
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