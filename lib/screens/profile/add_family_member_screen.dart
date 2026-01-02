import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_member_provider.dart';
import '../../models/family_member_model.dart';

/// Add/Edit family member screen
class AddFamilyMemberScreen extends ConsumerStatefulWidget {
  final FamilyMemberModel? familyMember; // null for add, non-null for edit

  const AddFamilyMemberScreen({
    super.key,
    this.familyMember,
  });

  @override
  ConsumerState<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends ConsumerState<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedRelationship = 'Father';
  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'A+';
  DateTime? _selectedDateOfBirth;
  List<String> _allergies = [];
  List<String> _medicalConditions = [];
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _relationships = [
    'Father', 'Mother', 'Son', 'Daughter', 'Brother', 'Sister',
    'Husband', 'Wife', 'Grandfather', 'Grandmother', 'Uncle', 'Aunt',
    'Cousin', 'Other'
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.familyMember != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final member = widget.familyMember!;
    _nameController.text = member.name;
    _selectedRelationship = member.relationship;
    _phoneController.text = member.phoneNumber ?? '';
    _emailController.text = member.email ?? '';
    _selectedDateOfBirth = member.dateOfBirth;
    _selectedBloodGroup = member.bloodGroup ?? 'A+';
    _selectedGender = member.gender ?? 'Male';
    _allergies = List.from(member.allergies);
    _medicalConditions = List.from(member.medicalConditions);
    _emergencyContactController.text = member.emergencyContact ?? '';
    _notesController.text = member.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.familyMember != null;
    
    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(context, isEditing),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeUtils.getBackgroundColor(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isEditing ? 'Edit Family Member' : 'Add Family Member',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image Section
            _buildImageSection(),
            const SizedBox(height: 24),

            // Basic Information
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Relationship',
              value: _selectedRelationship,
              items: _relationships,
              onChanged: (value) => setState(() => _selectedRelationship = value!),
              icon: Icons.family_restroom,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'Gender',
                    value: _selectedGender,
                    items: _genders,
                    onChanged: (value) => setState(() => _selectedGender = value!),
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Information
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _emailController,
              label: 'Email Address',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _emergencyContactController,
              label: 'Emergency Contact',
              prefixIcon: Icons.emergency,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Medical Information
            _buildSectionTitle('Medical Information'),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Blood Group',
              value: _selectedBloodGroup,
              items: _bloodGroups,
              onChanged: (value) => setState(() => _selectedBloodGroup = value!),
              icon: Icons.bloodtype,
            ),
            const SizedBox(height: 16),

            _buildChipField(
              label: 'Allergies',
              items: _allergies,
              onAdd: _addAllergy,
              onRemove: (allergy) => setState(() => _allergies.remove(allergy)),
              icon: Icons.warning,
            ),
            const SizedBox(height: 16),

            _buildChipField(
              label: 'Medical Conditions',
              items: _medicalConditions,
              onAdd: _addMedicalCondition,
              onRemove: (condition) => setState(() => _medicalConditions.remove(condition)),
              icon: Icons.medical_information,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _notesController,
              label: 'Additional Notes',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save Button
            CustomButton(
              text: widget.familyMember != null ? 'Update Member' : 'Add Member',
              onPressed: _saveFamilyMember,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeUtils.getSurfaceVariantColor(context),
                border: Border.all(
                  color: ThemeUtils.getPrimaryColor(context),
                  width: 3,
                ),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    )
                  : Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: ThemeUtils.getPrimaryColor(context),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to add photo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDateOfBirth != null
                    ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                    : 'Date of Birth',
                style: TextStyle(
                  color: _selectedDateOfBirth != null
                      ? ThemeUtils.getTextPrimaryColor(context)
                      : ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipField({
    required String label,
    required List<String> items,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: ThemeUtils.getTextSecondaryColor(context)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onAdd,
              icon: Icon(
                Icons.add,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Chip(
              label: Text(item),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => onRemove(item),
              backgroundColor: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
              deleteIconColor: ThemeUtils.getPrimaryColor(context),
            )).toList(),
          ),
        ],
      ],
    );
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _addAllergy() {
    _showAddItemDialog(
      title: 'Add Allergy',
      hint: 'Enter allergy name',
      onAdd: (value) {
        if (!_allergies.contains(value)) {
          setState(() => _allergies.add(value));
        }
      },
    );
  }

  void _addMedicalCondition() {
    _showAddItemDialog(
      title: 'Add Medical Condition',
      hint: 'Enter medical condition',
      onAdd: (value) {
        if (!_medicalConditions.contains(value)) {
          setState(() => _medicalConditions.add(value));
        }
      },
    );
  }

  void _showAddItemDialog({
    required String title,
    required String hint,
    required ValueChanged<String> onAdd,
  }) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                onAdd(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveFamilyMember() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).userModel;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.familyMember != null) {
        // Update existing member
        await ref.read(familyMemberProvider.notifier).updateFamilyMember(
          userId: user.uid,
          memberId: widget.familyMember!.id,
          name: _nameController.text.trim(),
          relationship: _selectedRelationship,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          dateOfBirth: _selectedDateOfBirth,
          bloodGroup: _selectedBloodGroup,
          gender: _selectedGender,
          allergies: _allergies,
          medicalConditions: _medicalConditions,
          emergencyContact: _emergencyContactController.text.trim().isEmpty ? null : _emergencyContactController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        // Add new member
        await ref.read(familyMemberProvider.notifier).addFamilyMember(
          userId: user.uid,
          name: _nameController.text.trim(),
          relationship: _selectedRelationship,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          dateOfBirth: _selectedDateOfBirth,
          bloodGroup: _selectedBloodGroup,
          gender: _selectedGender,
          allergies: _allergies,
          medicalConditions: _medicalConditions,
          emergencyContact: _emergencyContactController.text.trim().isEmpty ? null : _emergencyContactController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.familyMember != null 
                ? 'Family member updated successfully' 
                : 'Family member added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
