import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import 'professional_details_step.dart';
import 'practice_info_step.dart';
import 'availability_step.dart';
import 'bank_details_step.dart';
import 'additional_info_step.dart';
import 'review_submit_step.dart';
import 'verification_pending_screen.dart';

/// Doctor onboarding screen with 7 steps including verification
class DoctorOnboardingScreen extends ConsumerStatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  ConsumerState<DoctorOnboardingScreen> createState() =>
      _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState
    extends ConsumerState<DoctorOnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 7; // Updated to 7 steps including verification pending screen

  // Store data from each step
  Map<String, dynamic> _onboardingData = {};

  // Animation controllers
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  
  // Animations
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Page controller for smooth transitions
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    ));
    
    // Initialize page controller
    _pageController = PageController();
    
    // Start initial animations
    _progressAnimationController.forward();
    _slideAnimationController.forward();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      // Animate out current step
      await _slideAnimationController.reverse();
      await _fadeAnimationController.reverse();
      
      setState(() {
        _currentStep++;
      });
      
      // Update progress animation
      _progressAnimationController.animateTo((_currentStep + 1) / _totalSteps);
      
      // Animate to next page
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      
      // Animate in new step
      _slideAnimationController.forward();
      _fadeAnimationController.forward();
    }
  }

  void _previousStep() async {
    if (_currentStep > 0) {
      // Animate out current step
      await _slideAnimationController.reverse();
      await _fadeAnimationController.reverse();
      
      setState(() {
        _currentStep--;
      });
      
      // Update progress animation
      _progressAnimationController.animateTo((_currentStep + 1) / _totalSteps);
      
      // Animate to previous page
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      
      // Animate in new step
      _slideAnimationController.forward();
      _fadeAnimationController.forward();
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

  List<StepInfo> _getStepInfos() {
    return [
      StepInfo(
        title: 'Professional Details',
        subtitle: 'Your medical credentials',
        icon: Icons.medical_services,
        color: AppColors.primary,
      ),
      StepInfo(
        title: 'Practice Information',
        subtitle: 'Clinic and consultation details',
        icon: Icons.local_hospital,
        color: AppColors.secondary,
      ),
      StepInfo(
        title: 'Availability',
        subtitle: 'Working hours and schedule',
        icon: Icons.schedule,
        color: AppColors.info,
      ),
      StepInfo(
        title: 'Bank Details',
        subtitle: 'Payment information',
        icon: Icons.account_balance,
        color: AppColors.warning,
      ),
      StepInfo(
        title: 'Additional Information',
        subtitle: 'Bio and specializations',
        icon: Icons.person_add,
        color: AppColors.success,
      ),
      StepInfo(
        title: 'Review & Submit',
        subtitle: 'Final verification',
        icon: Icons.check_circle,
        color: AppColors.accent,
      ),
      StepInfo(
        title: 'Verification Pending',
        subtitle: 'Awaiting approval',
        icon: Icons.hourglass_empty,
        color: AppColors.warning,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userModel;
    final stepInfos = _getStepInfos();
    final currentStepInfo = stepInfos[_currentStep];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppColors.darkPrimary.withOpacity(0.1),
                    AppColors.darkSecondary.withOpacity(0.05),
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated Header
              _buildAnimatedHeader(currentStepInfo),
              
              // Progress Indicator
              _buildModernProgressIndicator(stepInfos),
              
              // Content Area
              Expanded(
                child: _buildContentArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(StepInfo stepInfo) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Welcome message
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [stepInfo.color, stepInfo.color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: stepInfo.color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        stepInfo.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${_currentStep + 1} of $_totalSteps',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stepInfo.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          Text(
                            stepInfo.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernProgressIndicator(List<StepInfo> stepInfos) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight;
    final textSecondaryColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.darkShadowLight 
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: borderColor,
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [AppColors.darkPrimary, AppColors.darkSecondary]
                              : [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      width: MediaQuery.of(context).size.width * 
                             ((_currentStep + 1) / _totalSteps) * 0.8,
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              final stepInfo = stepInfos[index];
              final successColor = isDarkMode ? AppColors.darkSuccess : AppColors.success;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? successColor
                      : isCurrent
                          ? stepInfo.color
                          : borderColor,
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: stepInfo.color.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                          key: ValueKey('check'),
                        )
                      : Icon(
                          stepInfo.icon,
                          color: isCurrent ? Colors.white : textSecondaryColor,
                          size: 20,
                          key: ValueKey('icon_$index'),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    
    return Container(
      margin: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode 
                          ? AppColors.darkShadowMedium 
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepContent(0),
                      _buildStepContent(1),
                      _buildStepContent(2),
                      _buildStepContent(3),
                      _buildStepContent(4),
                      _buildStepContent(5),
                      _buildStepContent(6),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
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
          onContinue: _nextStep, // Add continue to go to verification pending
        );
      case 6:
        return const VerificationPendingScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Step information model for better organization
class StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}