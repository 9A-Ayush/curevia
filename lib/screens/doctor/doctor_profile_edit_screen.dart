import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/doctor/doctor_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

/// Doctor profile edit screen
class DoctorProfileEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? doctorProfile;

  const DoctorProfileEditScreen({
    super.key,
    this.doctorProfile,
  });

  @override
  ConsumerState<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState
    extends ConsumerState<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _consultationFeeController = TextEditingController();

  bool _isAvailableOnline = true;
  bool _isAvailableOffline = true;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final user = ref.read(authProvider).userModel;
    final profile = widget.doctorProfile;

    _nameController.text = user?.fullName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _specialtyController.text = profile?['specialty'] ?? '';
    _qualificationController.text = profile?['qualification'] ?? '';
    _experienceController.text = profile?['experienceYears']?.toString() ?? '';
    _bioController.text = profile?['bio'] ?? '';
    _clinicNameController.text = profile?['clinicName'] ?? '';
    _clinicAddressController.text = profile?['clinicAddress'] ?? '';
    _cityController.text = profile?['city'] ?? '';
    _consultationFeeController.text = profile?['consultationFee']?.toString() ?? '';
    _isAvailableOnline = profile?['isAvailableOnline'] ?? true;
    _isAvailableOffline = profile?['isAvailableOffline'] ?? true;
    _profileImageUrl = user?.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _cityController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: ThemeUtils.getTextOnPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email should not be editable
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Basic phone number validation
                    final phoneRegex = RegExp(r'^[+]?[0-9]{10,15}$');
                    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Professional Information
              _buildSectionTitle('Professional Information'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _specialtyController,
                label: 'Specialty',
                prefixIcon: Icons.medical_services,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your specialty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _qualificationController,
                label: 'Qualification',
                prefixIcon: Icons.school,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your qualification';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                prefixIcon: Icons.work,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter years of experience';
                  }
                  final years = int.tryParse(value);
                  if (years == null || years < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _consultationFeeController,
                label: 'Consultation Fee (\$)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter consultation fee';
                  }
                  final fee = double.tryParse(value);
                  if (fee == null || fee < 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _bioController,
                label: 'Bio',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brief bio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Clinic Information
              _buildSectionTitle('Clinic Information'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _clinicNameController,
                label: 'Clinic Name',
                prefixIcon: Icons.local_hospital,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _clinicAddressController,
                label: 'Clinic Address',
                prefixIcon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cityController,
                label: 'City',
                prefixIcon: Icons.location_city,
              ),
              const SizedBox(height: 24),

              // Availability Settings
              _buildSectionTitle('Availability Settings'),
              const SizedBox(height: 16),
              _buildAvailabilityToggle(
                'Available for Online Consultations',
                _isAvailableOnline,
                (value) => setState(() => _isAvailableOnline = value),
              ),
              const SizedBox(height: 8),
              _buildAvailabilityToggle(
                'Available for In-Person Consultations',
                _isAvailableOffline,
                (value) => setState(() => _isAvailableOffline = value),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Save Changes',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: _profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: ThemeUtils.getPrimaryColor(context),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _uploadProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeUtils.getPrimaryColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ThemeUtils.getBackgroundColor(context),
                        width: 3,
                      ),
                    ),
                    child: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            color: ThemeUtils.getTextOnPrimaryColor(context),
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change profile picture',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ThemeUtils.getPrimaryColor(context),
      ),
    );
  }

  Widget _buildAvailabilityToggle(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeUtils.getPrimaryColor(context),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfilePicture() async {
    try {
      setState(() => _isUploadingImage = true);

      final imageFile = await ImageUploadService.showImageSourceDialog(context);
      if (imageFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final user = ref.read(authProvider).userModel;
      if (user == null) {
        throw Exception('User not found');
      }

      final imageUrl = await ImageUploadService.uploadProfilePicture(
        imageFile: imageFile,
        userId: user.uid,
      );

      setState(() {
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) {
        throw Exception('User not found');
      }

      // Update user profile data
      await ref.read(authProvider.notifier).updateUserProfile(
        displayName: _nameController.text.trim(),
        photoURL: _profileImageUrl,
        additionalData: {
          'fullName': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim().isEmpty 
              ? null 
              : _phoneController.text.trim(),
          'profileImageUrl': _profileImageUrl,
        },
      );

      // Update doctor profile data
      final doctorProfileData = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        'profileImageUrl': _profileImageUrl,
        'specialty': _specialtyController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'consultationFee': double.tryParse(_consultationFeeController.text.trim()) ?? 0.0,
        'bio': _bioController.text.trim(),
        'clinicName': _clinicNameController.text.trim(),
        'clinicAddress': _clinicAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'isAvailableOnline': _isAvailableOnline,
        'isAvailableOffline': _isAvailableOffline,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update doctor profile data
      await DoctorService.updateDoctorProfile(
        doctorId: user.uid,
        profileData: doctorProfileData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
}