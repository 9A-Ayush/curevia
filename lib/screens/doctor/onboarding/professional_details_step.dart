import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';

/// Professional details step in doctor onboarding
class ProfessionalDetailsStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const ProfessionalDetailsStep({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  });

  @override
  ConsumerState<ProfessionalDetailsStep> createState() =>
      _ProfessionalDetailsStepState();
}

class _ProfessionalDetailsStepState
    extends ConsumerState<ProfessionalDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _registrationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _councilController = TextEditingController();

  String? _selectedSpecialty;
  List<String> _selectedSubSpecialties = [];
  List<String> _degrees = [];
  File? _certificateFile;
  String? _certificateUrl;
  bool _isLoading = false;

  final List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Gynecologist',
    'Orthopedic',
    'Neurologist',
    'Psychiatrist',
    'ENT Specialist',
    'Ophthalmologist',
    'Dentist',
    'Urologist',
    'Gastroenterologist',
    'Pulmonologist',
    'Endocrinologist',
    'Nephrologist',
    'Oncologist',
    'Radiologist',
    'Anesthesiologist',
    'Pathologist',
  ];

  final List<String> _commonDegrees = [
    'MBBS',
    'MD',
    'MS',
    'DNB',
    'DM',
    'MCh',
    'BDS',
    'MDS',
    'BAMS',
    'BHMS',
    'BUMS',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _licenseController.text = widget.initialData['medicalLicenseNumber'] ?? '';
    _registrationController.text =
        widget.initialData['registrationNumber'] ?? '';
    _qualificationController.text = widget.initialData['qualification'] ?? '';
    _experienceController.text =
        widget.initialData['experienceYears']?.toString() ?? '';
    _councilController.text = widget.initialData['medicalCouncil'] ?? '';
    _selectedSpecialty = widget.initialData['specialty'];
    _selectedSubSpecialties =
        List<String>.from(widget.initialData['subSpecialties'] ?? []);
    _degrees = List<String>.from(widget.initialData['degrees'] ?? []);
    _certificateUrl = widget.initialData['certificateUrl'];
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _registrationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _councilController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _certificateFile = File(pickedFile.path);
      });
    }
  }

  void _showSpecialtyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        title: Text(
          'Select Specialty',
          style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _specialties.length,
            itemBuilder: (context, index) {
              final specialty = _specialties[index];
              return ListTile(
                title: Text(
                  specialty,
                  style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                ),
                onTap: () {
                  setState(() {
                    _selectedSpecialty = specialty;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDegreesDialog() {
    final tempDegrees = List<String>.from(_degrees);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeUtils.getSurfaceColor(context),
          title: Text(
            'Select Degrees',
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  children: _commonDegrees.map((degree) {
                    final isSelected = tempDegrees.contains(degree);
                    return FilterChip(
                      label: Text(degree),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            tempDegrees.add(degree);
                          } else {
                            tempDegrees.remove(degree);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      backgroundColor: ThemeUtils.getSurfaceColor(context),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : ThemeUtils.getTextPrimaryColor(context),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                  _degrees = tempDegrees;
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
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

    if (_selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your specialty')),
      );
      return;
    }

    if (_degrees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one degree')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Upload certificate if selected (non-blocking)
      String? certUrl = _certificateUrl;
      if (_certificateFile != null) {
        try {
          certUrl = await DoctorOnboardingService.uploadDoctorDocument(
            user.uid,
            _certificateFile!,
            'registration_certificate',
          );
        } catch (uploadError) {
          // Log error but don't block the flow
          debugPrint('Certificate upload failed: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Certificate upload failed. You can add it later.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          // Continue without certificate
          certUrl = _certificateUrl;
        }
      }

      // Prepare data
      final data = {
        'medicalLicenseNumber': _licenseController.text.trim(),
        'registrationNumber': _registrationController.text.trim(),
        'specialty': _selectedSpecialty,
        'subSpecialties': _selectedSubSpecialties,
        'qualification': _qualificationController.text.trim(),
        'degrees': _degrees,
        'experienceYears': int.parse(_experienceController.text.trim()),
        'medicalCouncil': _councilController.text.trim(),
        if (certUrl != null) 'certificateUrl': certUrl,
      };

      // Save to Firestore
      await DoctorOnboardingService.saveProfessionalDetails(user.uid, data);

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
          // Medical License Number
          Text(
            'Medical License Number *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _licenseController,
            decoration: InputDecoration(
              hintText: 'Enter your medical license number',
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your medical license number';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Registration Number
          Text(
            'Medical Council Registration Number *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _registrationController,
            decoration: InputDecoration(
              hintText: 'Enter registration number',
              prefixIcon: const Icon(Icons.card_membership),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your registration number';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Medical Council
          Text(
            'Medical Council *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _councilController,
            decoration: InputDecoration(
              hintText: 'e.g., Medical Council of India',
              prefixIcon: const Icon(Icons.account_balance),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your medical council';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Specialty
          Text(
            'Specialty *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showSpecialtyDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedSpecialty ?? 'Select your specialty',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _selectedSpecialty != null
                                ? ThemeUtils.getTextPrimaryColor(context)
                                : ThemeUtils.getTextSecondaryColor(context),
                          ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Degrees
          Text(
            'Medical Degrees *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showDegreesDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _degrees.isEmpty
                        ? Text(
                            'Select your degrees',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _degrees
                                .map(
                                  (degree) => Chip(
                                    label: Text(degree),
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _degrees.remove(degree);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Qualification
          Text(
            'Highest Qualification *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _qualificationController,
            decoration: InputDecoration(
              hintText: 'e.g., MD in Internal Medicine',
              prefixIcon: const Icon(Icons.workspace_premium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your qualification';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Years of Experience
          Text(
            'Years of Experience *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter years of experience',
              prefixIcon: const Icon(Icons.work),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your years of experience';
              }
              final years = int.tryParse(value);
              if (years == null || years < 0) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Upload Certificate
          Text(
            'Registration Certificate',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickCertificate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
                color: ThemeUtils.getSurfaceColor(context),
              ),
              child: Row(
                children: [
                  Icon(
                    _certificateFile != null || _certificateUrl != null
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color: _certificateFile != null || _certificateUrl != null
                        ? AppColors.success
                        : ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _certificateFile != null
                          ? 'Certificate selected'
                          : _certificateUrl != null
                              ? 'Certificate uploaded'
                              : 'Upload registration certificate',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
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
