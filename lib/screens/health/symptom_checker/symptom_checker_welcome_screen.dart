import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../providers/symptom_checker_provider.dart';
import 'symptom_checker_disclaimer_screen.dart';

/// Welcome screen for the symptom checker
class SymptomCheckerWelcomeScreen extends ConsumerWidget {
  const SymptomCheckerWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Medical icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 60,
                        color: ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'AI-Powered Symptom Analysis',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    Text(
                      'Get preliminary health insights based on your symptoms',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Features list
                    _buildFeaturesList(context),
                    
                    const SizedBox(height: 40),
                    
                    // Important notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This tool provides preliminary insights only. Always consult healthcare professionals for proper diagnosis.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ThemeUtils.getTextPrimaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Get started button
              CustomButton(
                text: 'Get Started',
                onPressed: () => _navigateToDisclaimer(context, ref),
                width: double.infinity,
                backgroundColor: ThemeUtils.getPrimaryColor(context),
                textColor: ThemeUtils.getTextOnPrimaryColor(context),
                icon: Icons.arrow_forward,
              ),
              
              const SizedBox(height: 16),
              
              // Privacy note
              Text(
                'Your privacy is protected. All data is processed securely.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final theme = Theme.of(context);
    
    final features = [
      {
        'icon': Icons.psychology_outlined,
        'title': 'AI Analysis',
        'description': 'Advanced AI powered by Google Gemini',
      },
      {
        'icon': Icons.camera_alt_outlined,
        'title': 'Image Support',
        'description': 'Upload photos of visible symptoms',
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Secure & Private',
        'description': 'Your health data stays protected',
      },
      {
        'icon': Icons.local_hospital_outlined,
        'title': 'Doctor Recommendations',
        'description': 'Get specialist suggestions when needed',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: ThemeUtils.getPrimaryColor(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature['description'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _navigateToDisclaimer(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SymptomCheckerDisclaimerScreen(),
      ),
    );
  }
}