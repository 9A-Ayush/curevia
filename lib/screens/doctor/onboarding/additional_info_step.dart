import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';

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

class _AdditionalInfoStepState extends ConsumerState<AdditionalInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _aboutController = TextEditingController();
  final _awardsController = TextEditingController();
  final _membershipsController = TextEditingController();

  List<String> _services = [];
  List<String> _conditionsTreated = [];
  bool _isLoading = false;

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

  @override
  void dispose() {
    _aboutController.dispose();
    _awardsController.dispose();
    _membershipsController.dispose();
    super.dispose();
  }

  void _showServicesDialog() {
    final tempServices = List<String>.from(_services);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeUtils.getSurfaceColor(context),
          title: Text(
            'Select Services',
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
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
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    backgroundColor: ThemeUtils.getSurfaceColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : ThemeUtils.getTextPrimaryColor(context),
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
            TextButton(
              onPressed: () {
                setState(() {
                  _services = tempServices;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Done',
                style: TextStyle(color: AppColors.primary),
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
          title: Text(
            'Select Conditions Treated',
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
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
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    backgroundColor: ThemeUtils.getSurfaceColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : ThemeUtils.getTextPrimaryColor(context),
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
            TextButton(
              onPressed: () {
                setState(() {
                  _conditionsTreated = tempConditions;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Done',
                style: TextStyle(color: AppColors.primary),
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
          // About/Bio
          Text(
            'About You *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _aboutController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Write a brief description about yourself, your expertise, and approach to patient care...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please write about yourself';
              }
              if (value.trim().length < 50) {
                return 'Please write at least 50 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Services Offered
          Text(
            'Services Offered',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showServicesDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _services.isEmpty
                              ? 'Select services you offer'
                              : '${_services.length} services selected',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: _services.isNotEmpty
                                    ? ThemeUtils.getTextPrimaryColor(context)
                                    : ThemeUtils.getTextSecondaryColor(context),
                              ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  if (_services.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _services
                          .map(
                            (service) => Chip(
                              label: Text(service),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _services.remove(service);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Conditions Treated
          Text(
            'Conditions Treated',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showConditionsDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.healing,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _conditionsTreated.isEmpty
                              ? 'Select conditions you treat'
                              : '${_conditionsTreated.length} conditions selected',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: _conditionsTreated.isNotEmpty
                                    ? ThemeUtils.getTextPrimaryColor(context)
                                    : ThemeUtils.getTextSecondaryColor(context),
                              ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  if (_conditionsTreated.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _conditionsTreated
                          .map(
                            (condition) => Chip(
                              label: Text(condition),
                              backgroundColor:
                                  AppColors.info.withValues(alpha: 0.1),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _conditionsTreated.remove(condition);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Awards & Recognitions (Optional)
          Text(
            'Awards & Recognitions (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _awardsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter each award on a new line',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Memberships (Optional)
          Text(
            'Professional Memberships (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _membershipsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter each membership on a new line',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
