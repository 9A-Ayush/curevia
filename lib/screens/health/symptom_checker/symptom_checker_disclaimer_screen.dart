import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../providers/symptom_checker_provider.dart';
import 'symptom_checker_input_screen.dart';

/// Disclaimer screen with legal and medical disclaimers
class SymptomCheckerDisclaimerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerDisclaimerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerDisclaimerScreen> createState() =>
      _SymptomCheckerDisclaimerScreenState();
}

class _SymptomCheckerDisclaimerScreenState
    extends ConsumerState<SymptomCheckerDisclaimerScreen> {
  bool _hasReadDisclaimer = false;
  bool _acceptsTerms = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Important Information'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning icon and title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.warning_amber_outlined,
                            color: AppColors.warning,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Medical Disclaimer',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ThemeUtils.getTextPrimaryColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Main disclaimer
                    _buildDisclaimerSection(
                      context,
                      'Not a Substitute for Professional Medical Advice',
                      'This symptom checker is an AI-powered tool designed to provide preliminary health information only. It is NOT a substitute for professional medical advice, diagnosis, or treatment.',
                      Icons.medical_services_outlined,
                      AppColors.error,
                    ),

                    const SizedBox(height: 20),

                    _buildDisclaimerSection(
                      context,
                      'Always Consult Healthcare Professionals',
                      'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay seeking it because of something you have read in this app.',
                      Icons.local_hospital_outlined,
                      AppColors.primary,
                    ),

                    const SizedBox(height: 20),

                    _buildDisclaimerSection(
                      context,
                      'Emergency Situations',
                      'If you think you may have a medical emergency, call your doctor or emergency services immediately. This app should never be used for emergency medical situations.',
                      Icons.emergency_outlined,
                      AppColors.error,
                    ),

                    const SizedBox(height: 20),

                    _buildDisclaimerSection(
                      context,
                      'Accuracy and Limitations',
                      'While we strive for accuracy, AI analysis may not be 100% accurate. The information provided is based on general medical knowledge and may not apply to your specific situation.',
                      Icons.info_outline,
                      AppColors.secondary,
                    ),

                    const SizedBox(height: 20),

                    _buildDisclaimerSection(
                      context,
                      'Privacy and Data Security',
                      'Your health information is processed securely and privately. We do not store personal health data permanently and follow strict privacy guidelines.',
                      Icons.security_outlined,
                      AppColors.success,
                    ),

                    const SizedBox(height: 32),

                    // Emergency contacts
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_in_talk,
                                color: AppColors.error,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Emergency Contacts',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Emergency Services: 112 (India)\n'
                            '• Ambulance: 102\n'
                            '• Police: 100\n'
                            '• Fire: 101\n'
                            '• Women Helpline: 1091\n'
                            '• Child Helpline: 1098\n'
                            '• Mental Health: 9152987821 (Vandrevala Foundation)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ThemeUtils.getTextPrimaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Acknowledgment checkboxes
                    _buildCheckbox(
                      'I have read and understand the medical disclaimer',
                      _hasReadDisclaimer,
                      (value) => setState(() => _hasReadDisclaimer = value ?? false),
                    ),

                    const SizedBox(height: 12),

                    _buildCheckbox(
                      'I understand this is not a substitute for professional medical advice',
                      _acceptsTerms,
                      (value) => setState(() => _acceptsTerms = value ?? false),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CustomButton(
                    text: 'I Understand - Continue',
                    onPressed: _canProceed ? () => _proceedToSymptomInput() : null,
                    width: double.infinity,
                    backgroundColor: _canProceed 
                        ? ThemeUtils.getPrimaryColor(context)
                        : ThemeUtils.getTextHintColor(context),
                    textColor: ThemeUtils.getTextOnPrimaryColor(context),
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    width: double.infinity,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextPrimaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String text, bool value, ValueChanged<bool?> onChanged) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: ThemeUtils.getPrimaryColor(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _canProceed => _hasReadDisclaimer && _acceptsTerms;

  void _proceedToSymptomInput() {
    ref.read(symptomCheckerProvider.notifier).acceptDisclaimer();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SymptomCheckerInputScreen(),
      ),
    );
  }
}