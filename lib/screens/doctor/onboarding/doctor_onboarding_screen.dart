import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import 'professional_details_step.dart';
import 'practice_info_step.dart';
import 'availability_step.dart';
import 'bank_details_step.dart';
import 'additional_info_step.dart';
import 'review_submit_step.dart';

/// Doctor onboarding screen with 7 steps including verification
class DoctorOnboardingScreen extends ConsumerStatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  ConsumerState<DoctorOnboardingScreen> createState() =>
      _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState
    extends ConsumerState<DoctorOnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 6; // 6 steps + verification pending screen

  // Store data from each step
  Map<String, dynamic> _onboardingData = {};

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _updateData(Map<String, dynamic> data) {
    setState(() {
      _onboardingData = {..._onboardingData, ...data};
    });
  }

  Widget _getCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return ProfessionalDetailsStep(
          onContinue: _nextStep,
          onBack: () {}, // First step, no back
          onDataUpdate: _updateData,
          initialData: _onboardingData,
        );
      case 1:
        return PracticeInfoStep(
          onContinue: _nextStep,
          onBack: _previousStep,
          onDataUpdate: _updateData,
          initialData: _onboardingData,
        );
      case 2:
        return AvailabilityStep(
          onContinue: _nextStep,
          onBack: _previousStep,
          onDataUpdate: _updateData,
          initialData: _onboardingData,
        );
      case 3:
        return BankDetailsStep(
          onContinue: _nextStep,
          onBack: _previousStep,
          onDataUpdate: _updateData,
          initialData: _onboardingData,
        );
      case 4:
        return AdditionalInfoStep(
          onContinue: _nextStep,
          onBack: _previousStep,
          onDataUpdate: _updateData,
          initialData: _onboardingData,
        );
      case 5:
        return ReviewSubmitStep(
          onboardingData: _onboardingData,
          onBack: _previousStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Professional Details';
      case 1:
        return 'Practice Information';
      case 2:
        return 'Availability';
      case 3:
        return 'Bank Details';
      case 4:
        return 'Additional Information';
      case 5:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userModel;

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Doctor Onboarding - Step ${_currentStep + 1}/$_totalSteps'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Step title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _getStepTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Current step content
          Expanded(
            child: _getCurrentStepWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: ThemeUtils.getSurfaceColor(context),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.primary
                              : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.borderLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : ThemeUtils.getTextSecondaryColor(
                                            context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete all steps to submit your profile for verification',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
