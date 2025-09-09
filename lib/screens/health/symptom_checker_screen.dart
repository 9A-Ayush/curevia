import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/ai/symptom_analysis_service.dart';
import '../../models/symptom_analysis_model.dart';

/// Symptom checker screen
class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() =>
      _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final List<String> _selectedSymptoms = [];
  final List<File> _uploadedImages = [];
  int _currentStep = 0;
  String _selectedGender = 'Male';
  String? _selectedDuration;
  String? _selectedSeverity;
  bool _isAnalyzing = false;
  SymptomAnalysisResult? _analysisResult;

  final List<SymptomCategory> _symptomCategories = [
    SymptomCategory(
      name: 'General',
      symptoms: [
        'Fever',
        'Fatigue',
        'Headache',
        'Nausea',
        'Dizziness',
        'Loss of appetite',
      ],
    ),
    SymptomCategory(
      name: 'Respiratory',
      symptoms: [
        'Cough',
        'Shortness of breath',
        'Chest pain',
        'Sore throat',
        'Runny nose',
      ],
    ),
    SymptomCategory(
      name: 'Digestive',
      symptoms: [
        'Stomach pain',
        'Diarrhea',
        'Constipation',
        'Vomiting',
        'Heartburn',
      ],
    ),
    SymptomCategory(
      name: 'Musculoskeletal',
      symptoms: [
        'Joint pain',
        'Muscle pain',
        'Back pain',
        'Neck pain',
        'Stiffness',
      ],
    ),
    SymptomCategory(
      name: 'Skin',
      symptoms: ['Rash', 'Itching', 'Dry skin', 'Swelling', 'Bruising'],
    ),
  ];

  @override
  void dispose() {
    _symptomsController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ThemeUtils.isDarkMode(context)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ThemeUtils.getPrimaryColor(context),
                            ThemeUtils.getPrimaryColor(
                              context,
                            ).withValues(alpha: 0.8),
                          ],
                        )
                      : AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: ThemeUtils.getTextOnPrimaryColor(
                              context,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medical_services,
                            color: ThemeUtils.getTextOnPrimaryColor(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Symptom Checker',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: ThemeUtils.getTextOnPrimaryColor(
                                        context,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Get preliminary health insights',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: ThemeUtils.getTextOnPrimaryColor(
                                        context,
                                      ).withValues(alpha: 0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeUtils.isDarkMode(context)
                            ? ThemeUtils.getWarningColor(
                                context,
                              ).withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ThemeUtils.isDarkMode(context)
                              ? ThemeUtils.getWarningColor(
                                  context,
                                ).withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: ThemeUtils.getTextOnPrimaryColor(context),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is not a substitute for professional medical advice',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ThemeUtils.getTextOnPrimaryColor(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _currentStep
                                ? ThemeUtils.getPrimaryColor(context)
                                : ThemeUtils.isDarkMode(context)
                                ? Colors.grey.shade700
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),

              // Content
              Expanded(child: _buildStepContent()),

              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: CustomButton(
                          text: 'Previous',
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                            });
                          },
                          backgroundColor: AppColors.surfaceVariant,
                          textColor: AppColors.textPrimary,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: _currentStep == 2 ? 'Get Results' : 'Next',
                        onPressed: _canProceed() ? _handleNext : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Loading overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing your symptoms...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildSymptomSelection();
      case 1:
        return _buildAdditionalInfo();
      case 2:
        return _buildResults();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSymptomSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your symptoms',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose all symptoms you are currently experiencing',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Selected symptoms
          if (_selectedSymptoms.isNotEmpty) ...[
            Text(
              'Selected Symptoms (${_selectedSymptoms.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSymptoms.map((symptom) {
                return Chip(
                  label: Text(symptom),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _selectedSymptoms.remove(symptom);
                    });
                  },
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: AppColors.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Symptom categories
          for (final category in _symptomCategories) ...[
            Text(
              category.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide more details about your symptoms',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Basic Information
          _buildBasicInfoSection(),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _symptomsController,
            label: 'Describe your symptoms',
            hintText: 'When did they start? How severe are they? Any triggers?',
            maxLines: 5,
          ),
          const SizedBox(height: 24),

          // Quick questions
          _buildQuickQuestion(
            'How long have you had these symptoms?',
            ['Less than 24 hours', '1-3 days', '4-7 days', 'More than a week'],
            _selectedDuration,
            (value) {
              setState(() {
                _selectedDuration = value;
              });
            },
          ),
          const SizedBox(height: 16),

          _buildQuickQuestion(
            'How would you rate the severity?',
            ['Mild', 'Moderate', 'Severe', 'Very severe'],
            _selectedSeverity,
            (value) {
              setState(() {
                _selectedSeverity = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Image Upload Section
          _buildImageUploadSection(),
        ],
      ),
    );
  }

  Widget _buildQuickQuestion(
    String question,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _ageController,
                label: 'Age',
                hintText: 'Enter your age',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Images (Optional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload photos of affected areas, rashes, or any visible symptoms',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (_uploadedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _uploadedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
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
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _uploadedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildResults() {
    if (_analysisResult == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Analysis results will appear here',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final result = _analysisResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Analysis Results',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Confidence: ${result.confidence}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Possible Conditions
          if (result.possibleConditions.isNotEmpty) ...[
            _buildResultCard(
              'Possible Conditions',
              result.possibleConditions
                  .map(
                    (condition) =>
                        '${condition.name} (${condition.probability} probability)',
                  )
                  .toList(),
              Icons.medical_services,
              AppColors.info,
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (result.recommendations.isNotEmpty) ...[
            _buildResultCard(
              'Recommended Actions',
              result.recommendations,
              Icons.healing,
              AppColors.success,
            ),
            const SizedBox(height: 16),
          ],

          // Urgent Signs
          if (result.urgentSigns.isNotEmpty) ...[
            _buildResultCard(
              'When to Seek Immediate Care',
              result.urgentSigns,
              Icons.emergency,
              AppColors.error,
            ),
            const SizedBox(height: 16),
          ],

          // Suggested Specialist
          if (result.suggestedSpecialist.isNotEmpty) ...[
            _buildResultCard(
              'Suggested Specialist',
              ['Consult a ${result.suggestedSpecialist}'],
              Icons.person_search,
              AppColors.primary,
            ),
            const SizedBox(height: 24),
          ],

          // Action Buttons
          CustomButton(
            text: 'Book Consultation with ${result.suggestedSpecialist}',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to doctor booking with specialty filter
            },
            width: double.infinity,
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: 'Start New Analysis',
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _selectedSymptoms.clear();
                _symptomsController.clear();
                _ageController.clear();
                _uploadedImages.clear();
                _selectedDuration = null;
                _selectedSeverity = null;
                _analysisResult = null;
              });
            },
            backgroundColor: AppColors.surfaceVariant,
            textColor: AppColors.textPrimary,
            width: double.infinity,
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Important Disclaimer',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result.disclaimer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedSymptoms.isNotEmpty;
      case 1:
        return true; // Can proceed even without additional info
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() async {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Perform AI analysis
      await _performAnalysis();
    }
  }

  Future<void> _performAnalysis() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final age = int.tryParse(_ageController.text) ?? 25;

      final result = await SymptomAnalysisService.analyzeSymptoms(
        symptoms: _selectedSymptoms,
        description: _symptomsController.text.trim(),
        age: age,
        gender: _selectedGender,
        images: _uploadedImages.isNotEmpty ? _uploadedImages : null,
        duration: _selectedDuration,
        severity: _selectedSeverity,
      );

      // Store result for display
      _analysisResult = result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}

class SymptomCategory {
  final String name;
  final List<String> symptoms;

  SymptomCategory({required this.name, required this.symptoms});
}
