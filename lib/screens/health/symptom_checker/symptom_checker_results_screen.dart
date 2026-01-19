import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../providers/symptom_checker_provider.dart';
import '../../../models/symptom_checker_models.dart';
import '../../patient/find_doctors_screen.dart';

/// Results screen showing symptom analysis results
class SymptomCheckerResultsScreen extends ConsumerWidget {
  const SymptomCheckerResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisResult = ref.watch(analysisResultProvider);
    
    if (analysisResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Results'),
          backgroundColor: ThemeUtils.getPrimaryColor(context),
          foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        ),
        body: const Center(
          child: Text('No analysis results available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
        actions: [
          // Share button removed for privacy and security reasons
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer banner
            _buildDisclaimerBanner(context),
            
            const SizedBox(height: 24),
            
            // Overall severity
            _buildSeverityCard(context, analysisResult),
            
            const SizedBox(height: 24),
            
            // Possible conditions
            _buildPossibleConditions(context, analysisResult),
            
            const SizedBox(height: 24),
            
            // Recommendations
            _buildRecommendations(context, analysisResult),
            
            const SizedBox(height: 24),
            
            // Urgent signs
            if (analysisResult.urgentSigns.isNotEmpty) ...[
              _buildUrgentSigns(context, analysisResult),
              const SizedBox(height: 24),
            ],
            
            // Next steps
            _buildNextSteps(context, analysisResult),
            
            const SizedBox(height: 24),
            
            // Suggested specialist
            if (analysisResult.suggestedSpecialist.isNotEmpty) ...[
              _buildSpecialistRecommendation(context, analysisResult),
              const SizedBox(height: 24),
            ],
            
            // Emergency advice
            if (analysisResult.emergencyAdvice != null) ...[
              _buildEmergencyAdvice(context, analysisResult.emergencyAdvice!),
              const SizedBox(height: 24),
            ],
            
            // Action buttons
            _buildActionButtons(context, ref, analysisResult),
            
            const SizedBox(height: 24),
            
            // Final disclaimer
            _buildFinalDisclaimer(context, analysisResult),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerBanner(BuildContext context) {
    return Container(
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
          const Icon(
            Icons.info_outline,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a preliminary analysis only. Always consult healthcare professionals for proper diagnosis and treatment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);
    Color severityColor;
    IconData severityIcon;

    switch (result.overallSeverity) {
      case SeverityLevel.low:
        severityColor = AppColors.success;
        severityIcon = Icons.check_circle_outline;
        break;
      case SeverityLevel.moderate:
        severityColor = AppColors.warning;
        severityIcon = Icons.warning_amber_outlined;
        break;
      case SeverityLevel.high:
        severityColor = AppColors.error;
        severityIcon = Icons.error_outline;
        break;
      case SeverityLevel.emergency:
        severityColor = AppColors.error;
        severityIcon = Icons.emergency_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                severityIcon,
                color: severityColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.overallSeverity.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.overallSeverity.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.confidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Confidence: ${result.confidence}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: severityColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPossibleConditions(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Possible Conditions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        ...result.possibleConditions.map((condition) {
          return _buildConditionCard(context, condition);
        }).toList(),
      ],
    );
  }

  Widget _buildConditionCard(BuildContext context, PossibleCondition condition) {
    final theme = Theme.of(context);
    Color probabilityColor;

    switch (condition.probability.toLowerCase()) {
      case 'high':
        probabilityColor = AppColors.error;
        break;
      case 'medium':
        probabilityColor = AppColors.warning;
        break;
      case 'low':
        probabilityColor = AppColors.success;
        break;
      default:
        probabilityColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  condition.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: probabilityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  condition.probability,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: probabilityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            condition.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          if (condition.symptoms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Related symptoms:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: condition.symptoms.map((symptom) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    symptom,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getPrimaryColor(context),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (condition.treatment != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Treatment Info:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    condition.treatment!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: result.recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < result.recommendations.length - 1 ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentSigns(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seek Immediate Care If You Experience:',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 16),
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
            children: result.urgentSigns.map((sign) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sign,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Steps',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: result.nextSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < result.nextSteps.length - 1 ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialistRecommendation(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_hospital_outlined,
            color: ThemeUtils.getPrimaryColor(context),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Specialist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.suggestedSpecialist,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAdvice(BuildContext context, String emergencyAdvice) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.emergency,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Emergency Advice',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            emergencyAdvice,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextPrimaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, SymptomAnalysisResult result) {
    return Column(
      children: [
        CustomButton(
          text: 'Find Doctors',
          onPressed: () => _navigateToFindDoctors(context, result.suggestedSpecialist),
          width: double.infinity,
          backgroundColor: ThemeUtils.getPrimaryColor(context),
          textColor: ThemeUtils.getTextOnPrimaryColor(context),
          icon: Icons.search,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'New Analysis',
                onPressed: () => _startNewAnalysis(context, ref),
                isOutlined: true,
                icon: Icons.refresh,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Save Results',
                onPressed: () => _saveResults(context, ref),
                isOutlined: true,
                icon: Icons.bookmark_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalDisclaimer(BuildContext context, SymptomAnalysisResult result) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medical Disclaimer',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.disclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Sharing functionality removed for privacy and security reasons
  // Users can take screenshots if they need to save results

  void _navigateToFindDoctors(BuildContext context, String specialty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FindDoctorsScreen(),
      ),
    );
  }

  void _startNewAnalysis(BuildContext context, WidgetRef ref) {
    ref.read(symptomCheckerProvider.notifier).reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _saveResults(BuildContext context, WidgetRef ref) {
    ref.read(symptomCheckerProvider.notifier).saveAnalysisResult();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Results saved to your health history'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}