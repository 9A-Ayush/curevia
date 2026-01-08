import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/symptom_checker_provider.dart';
import '../../../models/symptom_checker_models.dart';
import 'symptom_checker_results_screen.dart';

/// Processing screen with hidden loading for symptom analysis
class SymptomCheckerProcessingScreen extends ConsumerStatefulWidget {
  final SymptomAnalysisRequest request;

  const SymptomCheckerProcessingScreen({
    super.key,
    required this.request,
  });

  @override
  ConsumerState<SymptomCheckerProcessingScreen> createState() =>
      _SymptomCheckerProcessingScreenState();
}

class _SymptomCheckerProcessingScreenState
    extends ConsumerState<SymptomCheckerProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  final List<String> _processingMessages = [
    'Analyzing your symptoms...',
    'Consulting medical knowledge base...',
    'Evaluating possible conditions...',
    'Generating recommendations...',
    'Preparing your results...',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnalysis();
    _startMessageRotation();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _processingMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  void _startAnalysis() {
    // Start the analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(symptomCheckerProvider.notifier).analyzeSymptoms(widget.request);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Listen to analysis state
    ref.listen<SymptomCheckerState>(symptomCheckerProvider, (previous, next) {
      if (next.analysisResult != null && !next.isLoading) {
        // Analysis completed, navigate to results
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SymptomCheckerResultsScreen(),
          ),
        );
      } else if (next.error != null) {
        // Show error dialog
        _showErrorDialog(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Medical AI icon with animations
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ThemeUtils.getPrimaryColor(context),
                                  ThemeUtils.getPrimaryColor(context).withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.psychology_outlined,
                              size: 60,
                              color: ThemeUtils.getTextOnPrimaryColor(context),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'AI Analysis in Progress',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Animated processing message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _processingMessages[_currentMessageIndex],
                  key: ValueKey(_currentMessageIndex),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Progress indicator
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeUtils.getBorderLightColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_rotationController.value * 0.8) + 0.2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ThemeUtils.getPrimaryColor(context),
                              ThemeUtils.getPrimaryColor(context).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Reassuring information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ThemeUtils.getBorderLightColor(context),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: ThemeUtils.getPrimaryColor(context),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Secure Processing',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your health information is being processed securely using advanced AI technology. This typically takes 10-30 seconds.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Processing steps
              _buildProcessingSteps(),

              const SizedBox(height: 48),

              // Cancel button
              TextButton(
                onPressed: () => _showCancelDialog(),
                child: Text(
                  'Cancel Analysis',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingSteps() {
    final theme = Theme.of(context);
    
    final steps = [
      {'icon': Icons.description_outlined, 'text': 'Analyzing symptoms'},
      {'icon': Icons.library_books_outlined, 'text': 'Consulting medical database'},
      {'icon': Icons.analytics_outlined, 'text': 'Evaluating conditions'},
      {'icon': Icons.recommend_outlined, 'text': 'Generating recommendations'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= _currentMessageIndex;
        final isCompleted = index < _currentMessageIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? ThemeUtils.getPrimaryColor(context)
                      : ThemeUtils.getBorderLightColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted ? Icons.check : step['icon'] as IconData,
                  size: 18,
                  color: isActive
                      ? ThemeUtils.getTextOnPrimaryColor(context)
                      : ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step['text'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? ThemeUtils.getTextPrimaryColor(context)
                        : ThemeUtils.getTextSecondaryColor(context),
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (isActive && !isCompleted)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeUtils.getPrimaryColor(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Error'),
        content: Text(
          'We encountered an issue while analyzing your symptoms: $error\n\n'
          'Please try again or consult with a healthcare professional.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to input
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
            },
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Analysis'),
        content: const Text('Are you sure you want to cancel the symptom analysis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Analysis'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}