import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../providers/symptom_checker_provider.dart';
import '../../../models/symptom_checker_models.dart';
import 'symptom_checker_processing_screen.dart';

/// Multi-step symptom input screen
class SymptomCheckerInputScreen extends ConsumerStatefulWidget {
  const SymptomCheckerInputScreen({super.key});

  @override
  ConsumerState<SymptomCheckerInputScreen> createState() =>
      _SymptomCheckerInputScreenState();
}

class _SymptomCheckerInputScreenState
    extends ConsumerState<SymptomCheckerInputScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final List<String> _selectedSymptoms = [];
  final List<File> _selectedImages = [];
  String _selectedGender = 'Male';
  SymptomDuration? _selectedDuration;
  int _severityLevel = 5;
  String? _selectedBodyPart;
  final List<String> _medicalHistory = [];

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentStepProvider);

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Symptom Analysis'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
        actions: [
          if (currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildSymptomSelectionStep(),
                _buildDetailsStep(),
                _buildImageUploadStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentStep = ref.watch(currentStepProvider);
    const totalSteps = 4;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              final isCompleted = index < currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? ThemeUtils.getPrimaryColor(context)
                        : ThemeUtils.getBorderLightColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide some basic information to help with the analysis.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 32),

          // Age input
          CustomTextField(
            controller: _ageController,
            label: 'Age',
            hintText: 'Enter your age',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.cake_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Age is required';
              final age = int.tryParse(value);
              if (age == null || age < 1 || age > 120) {
                return 'Please enter a valid age';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Gender selection
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Male', 'Female', 'Other'].map((gender) {
              final isSelected = _selectedGender == gender;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = gender),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeUtils.getPrimaryColor(context)
                          : ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? ThemeUtils.getPrimaryColor(context)
                            : ThemeUtils.getBorderLightColor(context),
                      ),
                    ),
                    child: Text(
                      gender,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? ThemeUtils.getTextOnPrimaryColor(context)
                            : ThemeUtils.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Description
          CustomTextField(
            controller: _descriptionController,
            label: 'Describe Your Symptoms',
            hintText: 'Please describe what you\'re experiencing in detail...',
            maxLines: 4,
            minLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe your symptoms';
              }
              if (value.trim().length < 10) {
                return 'Please provide more detail about your symptoms';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomSelectionStep() {
    final symptomCategories = ref.watch(symptomCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Symptoms',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the symptoms that match what you\'re experiencing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 24),

          // Selected symptoms count
          if (_selectedSymptoms.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedSymptoms.length} symptoms selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Symptom categories
          ...symptomCategories.map((category) {
            return _buildSymptomCategory(category);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSymptomCategory(SymptomCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: category.symptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSymptoms.remove(symptom);
                  } else {
                    _selectedSymptoms.add(symptom);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ThemeUtils.getPrimaryColor(context)
                      : ThemeUtils.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? ThemeUtils.getPrimaryColor(context)
                        : ThemeUtils.getBorderLightColor(context),
                  ),
                ),
                child: Text(
                  symptom,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? ThemeUtils.getTextOnPrimaryColor(context)
                        : ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand your symptoms better.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 32),

          // Duration
          Text(
            'How long have you had these symptoms?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SymptomDuration.values.map((duration) {
              final isSelected = _selectedDuration == duration;
              return GestureDetector(
                onTap: () => setState(() => _selectedDuration = duration),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThemeUtils.getPrimaryColor(context)
                        : ThemeUtils.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? ThemeUtils.getPrimaryColor(context)
                          : ThemeUtils.getBorderLightColor(context),
                    ),
                  ),
                  child: Text(
                    duration.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? ThemeUtils.getTextOnPrimaryColor(context)
                          : ThemeUtils.getTextPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Severity
          Text(
            'How severe are your symptoms? (1 = Mild, 10 = Severe)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Mild',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _severityLevel.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _severityLevel.toString(),
                  activeColor: ThemeUtils.getPrimaryColor(context),
                  onChanged: (value) {
                    setState(() => _severityLevel = value.round());
                  },
                ),
              ),
              Text(
                'Severe',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'Severity: $_severityLevel/10',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Body part
          Text(
            'Which part of your body is affected?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          _buildBodyPartSelector(),
        ],
      ),
    );
  }

  Widget _buildBodyPartSelector() {
    final bodyParts = ref.watch(bodyPartsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bodyParts.map((bodyPart) {
        final isSelected = _selectedBodyPart == bodyPart.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedBodyPart = bodyPart.name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? ThemeUtils.getPrimaryColor(context)
                  : ThemeUtils.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? ThemeUtils.getPrimaryColor(context)
                    : ThemeUtils.getBorderLightColor(context),
              ),
            ),
            child: Text(
              bodyPart.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? ThemeUtils.getTextOnPrimaryColor(context)
                    : ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageUploadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Images (Optional)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload photos of visible symptoms like rashes, wounds, or swelling.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 32),

          // Upload buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Take Photo',
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icons.camera_alt_outlined,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Choose from Gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icons.photo_library_outlined,
                  isOutlined: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Selected images
          if (_selectedImages.isNotEmpty) ...[
            Text(
              'Selected Images (${_selectedImages.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 32),

          // Privacy note
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
                const Icon(
                  Icons.security_outlined,
                  color: AppColors.info,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your images are processed securely and are not stored permanently.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final currentStep = ref.watch(currentStepProvider);
    final isLastStep = currentStep == 3;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: CustomButton(
                text: 'Previous',
                onPressed: _previousStep,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: currentStep > 0 ? 1 : 2,
            child: CustomButton(
              text: isLastStep ? 'Analyze Symptoms' : 'Next',
              onPressed: isLastStep ? _analyzeSymptoms : _nextStep,
              backgroundColor: ThemeUtils.getPrimaryColor(context),
              textColor: ThemeUtils.getTextOnPrimaryColor(context),
              icon: isLastStep ? Icons.psychology_outlined : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      ref.read(symptomCheckerProvider.notifier).nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    ref.read(symptomCheckerProvider.notifier).previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    final currentStep = ref.read(currentStepProvider);

    switch (currentStep) {
      case 0: // Basic info
        if (_ageController.text.isEmpty) {
          _showError('Please enter your age');
          return false;
        }
        if (_descriptionController.text.trim().length < 10) {
          _showError('Please provide more detail about your symptoms');
          return false;
        }
        return true;
      case 1: // Symptom selection
        if (_selectedSymptoms.isEmpty) {
          _showError('Please select at least one symptom');
          return false;
        }
        return true;
      case 2: // Details
        return true; // Optional fields
      case 3: // Images
        return true; // Optional
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _analyzeSymptoms() {
    if (!_validateCurrentStep()) return;

    final request = SymptomAnalysisRequest(
      textDescription: _descriptionController.text.trim(),
      selectedSymptoms: _selectedSymptoms,
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      duration: _selectedDuration?.displayName,
      severityLevel: _severityLevel,
      bodyPart: _selectedBodyPart,
      images: _selectedImages.isNotEmpty ? _selectedImages : null,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SymptomCheckerProcessingScreen(request: request),
      ),
    );
  }
}