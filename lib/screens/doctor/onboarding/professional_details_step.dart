import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../utils/validation_utils.dart';
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

class _ProfessionalDetailsStepState extends ConsumerState<ProfessionalDetailsStep>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
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
  File? _pdfFile;
  String? _pdfFileName;
  String? _pdfUrl;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _specialties = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
    'Surgery',
    'Gynecology',
    'ENT',
    'Ophthalmology',
    'Anesthesiology',
    'Emergency Medicine',
    'Family Medicine',
  ];

  final List<String> _commonDegrees = [
    'MBBS',
    'MD',
    'MS',
    'DNB',
    'DM',
    'MCh',
    'BAMS',
    'BHMS',
    'BDS',
    'MDS',
    'BUMS',
    'BNYS',
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _registrationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _councilController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    _nameController.text = widget.initialData['name'] ?? '';
    _phoneController.text = widget.initialData['phone'] ?? '';
    _emailController.text = widget.initialData['email'] ?? '';
    _licenseController.text = widget.initialData['licenseNumber'] ?? '';
    _registrationController.text = widget.initialData['registrationNumber'] ?? '';
    _qualificationController.text = widget.initialData['qualification'] ?? '';
    _experienceController.text = widget.initialData['experience']?.toString() ?? '';
    _councilController.text = widget.initialData['medicalCouncil'] ?? '';
    _selectedSpecialty = widget.initialData['specialty'];
    _degrees = List<String>.from(widget.initialData['degrees'] ?? []);
    _certificateUrl = widget.initialData['certificateUrl'];
    _pdfUrl = widget.initialData['pdfUrl'];
    _pdfFileName = widget.initialData['pdfFileName'];
  }

  void _showSpecialtyDialog() {
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
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.medical_services, color: ThemeUtils.getPrimaryColor(context), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Select Specialty',
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
            child: Column(
              children: _specialties.map((specialty) {
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
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showDegreesDialog() {
    final tempDegrees = List<String>.from(_degrees);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final backgroundColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Degrees',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                    selectedColor: primaryColor.withOpacity(0.2),
                    backgroundColor: isDarkMode 
                        ? AppColors.darkSurfaceVariant 
                        : Colors.grey.shade50,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? primaryColor : borderColor,
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
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _degrees = tempDegrees;
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

  Future<void> _pickCertificate() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Verify file exists and is readable
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) { // 5MB limit
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('File size must be less than 5MB'),
                  backgroundColor: ThemeUtils.getErrorColor(context),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
            return;
          }
          
          setState(() {
            _certificateFile = file;
          });
        } else {
          throw Exception('Selected file does not exist');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting certificate: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickPdfDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        
        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          
          // Verify file exists and is readable
          if (await file.exists()) {
            final fileSize = await file.length();
            if (fileSize > 10 * 1024 * 1024) { // 10MB limit for PDFs
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('PDF file size must be less than 10MB'),
                    backgroundColor: ThemeUtils.getErrorColor(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
              return;
            }
            
            setState(() {
              _pdfFile = file;
              _pdfFileName = platformFile.name;
            });
          } else {
            throw Exception('Selected PDF file does not exist');
          }
        } else {
          throw Exception('Could not access the selected PDF file');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting PDF: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecialty == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select your specialty'),
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
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'registrationNumber': _registrationController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'medicalCouncil': _councilController.text.trim(),
        'specialty': _selectedSpecialty,
        'degrees': _degrees,
        'certificateFile': _certificateFile,
        'certificateUrl': _certificateUrl,
        'pdfFile': _pdfFile,
        'pdfFileName': _pdfFileName,
        'pdfUrl': _pdfUrl,
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
            ThemeUtils.getPrimaryColorWithOpacity(context, 0.05),
            ThemeUtils.getPrimaryColorWithOpacity(context, 0.02),
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
                        'Professional Details',
                        'Complete your professional information',
                        Icons.work,
                        ThemeUtils.getPrimaryColor(context),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
            color: isDarkMode 
                ? AppColors.darkShadowLight 
                : Colors.black.withOpacity(0.05),
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
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
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
      _buildAnimatedField(0, _buildNameField()),
      _buildAnimatedField(1, _buildPhoneField()),
      _buildAnimatedField(2, _buildEmailField()),
      _buildAnimatedField(3, _buildLicenseField()),
      _buildAnimatedField(4, _buildRegistrationField()),
      _buildAnimatedField(5, _buildSpecialtyField()),
      _buildAnimatedField(6, _buildDegreesField()),
      _buildAnimatedField(7, _buildQualificationField()),
      _buildAnimatedField(8, _buildExperienceField()),
      _buildAnimatedField(9, _buildCouncilField()),
      _buildAnimatedField(10, _buildCertificateField()),
      _buildAnimatedField(11, _buildPdfField()),
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

  Widget _buildNameField() {
    return _buildStyledTextField(
      controller: _nameController,
      label: 'Full Name',
      hint: 'Enter your full name',
      icon: Icons.person,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return _buildStyledTextField(
      controller: _phoneController,
      label: 'Phone Number',
      hint: 'Enter your phone number',
      icon: Icons.phone,
      keyboardType: TextInputType.phone,
      validator: (value) => ValidationUtils.validatePhoneNumber(value, isRequired: true),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildStyledTextField(
      controller: _emailController,
      label: 'Email Address',
      hint: 'Enter your email address',
      icon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildLicenseField() {
    return _buildStyledTextField(
      controller: _licenseController,
      label: 'Medical License Number',
      hint: 'Enter your medical license number',
      icon: Icons.badge,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your medical license number';
        }
        return null;
      },
    );
  }

  Widget _buildRegistrationField() {
    return _buildStyledTextField(
      controller: _registrationController,
      label: 'Registration Number',
      hint: 'Enter your registration number',
      icon: Icons.confirmation_number,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your registration number';
        }
        return null;
      },
    );
  }

  Widget _buildSpecialtyField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;
    final fillColor = isDarkMode ? AppColors.darkSurfaceVariant : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Medical Specialty *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
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
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Required',
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
                color: isDarkMode 
                    ? AppColors.darkShadowLight 
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _showSpecialtyDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medical_services, color: primaryColor, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      _selectedSpecialty ?? 'Select your specialty',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _selectedSpecialty != null
                            ? textColor
                            : secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: primaryColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDegreesField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;
    final fillColor = isDarkMode ? AppColors.darkSurfaceVariant : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Degrees',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
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
            onTap: _showDegreesDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(color: borderColor),
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
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school, color: primaryColor, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _degrees.isEmpty
                              ? 'Select your degrees'
                              : '${_degrees.length} degrees selected',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _degrees.isNotEmpty
                                ? textColor
                                : secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: primaryColor),
                    ],
                  ),
                  if (_degrees.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _degrees.map((degree) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              degree,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _degrees.remove(degree);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: primaryColor,
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

  Widget _buildQualificationField() {
    return _buildStyledTextField(
      controller: _qualificationController,
      label: 'Additional Qualifications',
      hint: 'Enter additional qualifications',
      icon: Icons.school,
      maxLines: 2,
    );
  }

  Widget _buildExperienceField() {
    return _buildStyledTextField(
      controller: _experienceController,
      label: 'Years of Experience',
      hint: 'Enter years of experience',
      icon: Icons.work_history,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter years of experience';
        }
        if (int.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildCouncilField() {
    return _buildStyledTextField(
      controller: _councilController,
      label: 'Medical Council',
      hint: 'Enter medical council name',
      icon: Icons.account_balance,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter medical council name';
        }
        return null;
      },
    );
  }

  Widget _buildCertificateField() {
    return _buildFileField(
      label: 'Medical Certificate',
      hint: 'Upload medical certificate',
      icon: _certificateFile != null || _certificateUrl != null
          ? Icons.check_circle
          : Icons.upload_file,
      color: _certificateFile != null || _certificateUrl != null
          ? AppColors.success
          : AppColors.primary,
      text: _certificateFile != null
          ? 'Certificate selected'
          : _certificateUrl != null
              ? 'Certificate uploaded'
              : 'Upload medical certificate',
      onTap: _pickCertificate,
    );
  }

  Widget _buildPdfField() {
    return _buildFileField(
      label: 'Additional Documents (PDF)',
      hint: 'Upload PDF documents',
      icon: _pdfFile != null || _pdfUrl != null
          ? Icons.check_circle
          : Icons.picture_as_pdf,
      color: _pdfFile != null || _pdfUrl != null
          ? AppColors.success
          : AppColors.primary,
      text: _pdfFile != null
          ? 'PDF selected: ${_pdfFileName ?? 'Unknown'}'
          : _pdfUrl != null
              ? 'PDF uploaded: ${_pdfFileName ?? 'Document'}'
              : 'Upload PDF documents',
      onTap: _pickPdfDocument,
    );
  }

  Widget _buildFileField({
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;
    final fillColor = isDarkMode ? AppColors.darkSurfaceVariant : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.upload, color: color),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;
    final fillColor = isDarkMode ? AppColors.darkSurfaceVariant : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
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
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            maxLines: maxLines,
            validator: validator,
            inputFormatters: inputFormatters,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDarkMode ? AppColors.darkTextHint : AppColors.textHint,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDarkMode ? AppColors.darkError : AppColors.error, 
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
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
                  color: textColor,
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
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
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