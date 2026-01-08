import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../utils/theme_utils.dart';
import '../../utils/validation_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../services/firebase/patient_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _aboutController = TextEditingController();

  // Patient-specific controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _selectedDateOfBirth;
  List<String> _allergies = [];
  List<String> _medicalHistory = [];

  bool _isLoading = false;
  bool _isPatient = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userModel = ref.read(currentUserModelProvider);
    final patientModel = ref.read(currentPatientModelProvider);

    if (userModel != null) {
      _fullNameController.text = userModel.fullName;
      _phoneController.text = userModel.phoneNumber ?? '';
      _emailController.text = userModel.email;
      _aboutController.text = userModel.additionalInfo?['about'] ?? '';
      _isPatient = userModel.role == 'patient';

      if (_isPatient && patientModel != null) {
        _heightController.text = patientModel.height?.toString() ?? '';
        _weightController.text = patientModel.weight?.toString() ?? '';
        _emergencyContactNameController.text =
            patientModel.emergencyContactName ?? '';
        _emergencyContactPhoneController.text =
            patientModel.emergencyContactPhone ?? '';
        _addressController.text = patientModel.address ?? '';
        _cityController.text = patientModel.city ?? '';
        _stateController.text = patientModel.state ?? '';
        _pincodeController.text = patientModel.pincode ?? '';

        _selectedGender = patientModel.gender;
        _selectedBloodGroup = patientModel.bloodGroup;
        _selectedDateOfBirth = patientModel.dateOfBirth;
        _allergies = List<String>.from(patientModel.allergies ?? []);
        _medicalHistory = List<String>.from(patientModel.medicalHistory ?? []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      appBar: AppBar(
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getBackgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 30),
                if (_isPatient) ...[
                  _buildHealthInfoSection(),
                  const SizedBox(height: 30),
                  _buildContactInfoSection(),
                  const SizedBox(height: 30),
                ],
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _fullNameController,
          label: 'Full Name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          prefixIcon: Icons.email_outlined,
          enabled: false, // Email should not be editable
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) => ValidationUtils.validatePhoneNumber(value, isRequired: false),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _aboutController,
          label: 'About Me',
          prefixIcon: Icons.info_outline,
          maxLines: 3,
          hintText: 'Tell us about yourself...',
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Gender',
                value: _selectedGender,
                items: _genderOptions,
                onChanged: (value) => setState(() => _selectedGender = value),
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Blood Group',
                value: _selectedBloodGroup,
                items: _bloodGroupOptions,
                onChanged: (value) =>
                    setState(() => _selectedBloodGroup = value),
                icon: Icons.bloodtype_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateField(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _heightController,
                label: 'Height (cm)',
                prefixIcon: Icons.height,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                prefixIcon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contact & Address',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyContactNameController,
          label: 'Emergency Contact Name',
          prefixIcon: Icons.contact_emergency_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyContactPhoneController,
          label: 'Emergency Contact Phone',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _addressController,
          label: 'Address',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _cityController,
                label: 'City',
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _stateController,
                label: 'State',
                prefixIcon: Icons.map_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _pincodeController,
          label: 'Pincode',
          prefixIcon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ThemeUtils.getPrimaryColor(context)),
        filled: true,
        fillColor: ThemeUtils.getSurfaceVariantColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ThemeUtils.getBorderLightColor(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ThemeUtils.getBorderLightColor(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ThemeUtils.getPrimaryColor(context),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
      ),
      style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
      dropdownColor: ThemeUtils.getSurfaceColor(context),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: ThemeUtils.getTextSecondaryColor(context),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDateOfBirth,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: ThemeUtils.getPrimaryColor(context),
          ),
          filled: true,
          fillColor: ThemeUtils.getSurfaceVariantColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ThemeUtils.getBorderLightColor(context),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ThemeUtils.getBorderLightColor(context),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ThemeUtils.getPrimaryColor(context),
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
        child: Text(
          _selectedDateOfBirth != null
              ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
              : 'Select date of birth',
          style: TextStyle(
            color: _selectedDateOfBirth != null
                ? ThemeUtils.getTextPrimaryColor(context)
                : ThemeUtils.getTextHintColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Save Changes',
        onPressed: _isLoading ? null : _saveProfile,
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDateOfBirth = date);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userModel = ref.read(currentUserModelProvider);
      if (userModel == null) throw Exception('User not found');

      // Update basic user info
      final updatedUserData = {
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'additionalInfo': {
          ...userModel.additionalInfo ?? {},
          'about': _aboutController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await ref
          .read(authProvider.notifier)
          .updateUserProfile(additionalData: updatedUserData);

      // Update patient-specific info if user is a patient
      if (_isPatient) {
        final updatedPatient = PatientModel(
          uid: userModel.uid,
          email: userModel.email,
          fullName: _fullNameController.text.trim(),
          role: userModel.role,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          profileImageUrl: userModel.profileImageUrl,
          createdAt: userModel.createdAt,
          updatedAt: DateTime.now(),
          isActive: userModel.isActive,
          isVerified: userModel.isVerified,
          additionalInfo:
              updatedUserData['additionalInfo'] as Map<String, dynamic>,
          dateOfBirth: _selectedDateOfBirth,
          gender: _selectedGender,
          bloodGroup: _selectedBloodGroup,
          height: _heightController.text.trim().isEmpty
              ? null
              : double.tryParse(_heightController.text.trim()),
          weight: _weightController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightController.text.trim()),
          allergies: _allergies,
          medicalHistory: _medicalHistory,
          emergencyContactName:
              _emergencyContactNameController.text.trim().isEmpty
              ? null
              : _emergencyContactNameController.text.trim(),
          emergencyContactPhone:
              _emergencyContactPhoneController.text.trim().isEmpty
              ? null
              : _emergencyContactPhoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          state: _stateController.text.trim().isEmpty
              ? null
              : _stateController.text.trim(),
          pincode: _pincodeController.text.trim().isEmpty
              ? null
              : _pincodeController.text.trim(),
        );

        await PatientService.updatePatient(updatedPatient);

        // Reload patient data in the provider
        ref.read(patientProvider.notifier).loadPatientData(userModel.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
