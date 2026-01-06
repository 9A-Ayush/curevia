import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../services/meditation_audio_service.dart';
import 'guided_meditation_session_screen.dart';
import 'ambient_sound_player_screen.dart';

/// Meditation Screen with guided sessions and breathing exercises
class MeditationScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const MeditationScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _meditationTimer;
  Timer? _breathingTimer;
  int _currentSeconds = 0;
  bool _isSessionActive = false;
  String _selectedDuration = '5 min';
  int _exerciseLevel = 1;
  int _breathingCycle = 0;
  String _breathingPhase = 'Prepare';
  
  // Animation controllers
  late AnimationController _breathingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;
  
  final MeditationAudioService _audioService = MeditationAudioService();

  final List<String> _durations = [
    '1 min',
    '3 min',
    '5 min',
    '10 min',
    '15 min',
    '20 min',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAudioService();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _breathingAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeAudioService() async {
    await _audioService.initialize();
    await _audioService.configureBackgroundAudio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _meditationTimer?.cancel();
    _breathingTimer?.cancel();
    _breathingAnimationController.dispose();
    _pulseAnimationController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Meditation'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(text: 'Guided'),
            Tab(text: 'Breathing'),
            Tab(text: 'Sounds'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGuidedTab(), _buildBreathingTab(), _buildSoundsTab()],
      ),
    );
  }
  Widget _buildGuidedTab() {
    final sessions = [
      MeditationSession(
        title: 'Mindful Breathing',
        description: 'Focus on your breath to calm your mind',
        duration: '5-15 min',
        difficulty: 'Beginner',
        icon: Icons.air,
        color: AppColors.info,
      ),
      MeditationSession(
        title: 'Body Scan',
        description: 'Progressive relaxation from head to toe',
        duration: '10-20 min',
        difficulty: 'Intermediate',
        icon: Icons.accessibility_new,
        color: AppColors.success,
      ),
      MeditationSession(
        title: 'Loving Kindness',
        description: 'Cultivate compassion for yourself and others',
        duration: '8-15 min',
        difficulty: 'Beginner',
        icon: Icons.favorite,
        color: AppColors.accent,
      ),
      MeditationSession(
        title: 'Sleep Meditation',
        description: 'Gentle guidance to help you fall asleep',
        duration: '15-30 min',
        difficulty: 'Beginner',
        icon: Icons.bedtime,
        color: AppColors.secondary,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildWelcomeCard();
        }

        final session = sessions[index - 1];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Meditation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a few minutes to center yourself and find inner peace.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(MeditationSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _startGuidedSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: session.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(session.icon, color: session.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(session.duration, Icons.schedule),
                        const SizedBox(width: 8),
                        _buildInfoChip(session.difficulty, Icons.trending_up),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow, color: AppColors.primary, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ThemeUtils.getTextSecondaryColor(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBreathingTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.03),
            ThemeUtils.getBackgroundColor(context),
            AppColors.secondary.withOpacity(0.02),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveValue(
              context: context,
              mobile: 16.0,
              tablet: 32.0,
              desktop: 48.0,
            ),
            vertical: 20.0,
          ),
          child: Column(
            children: [
              // Header Card
              _buildHeaderCard(),
              
              SizedBox(height: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 20.0,
                tablet: 24.0,
                desktop: 28.0,
              )),
              
              // Main Breathing Interface
              _buildMainBreathingInterface(),
              
              SizedBox(height: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 20.0,
                tablet: 24.0,
                desktop: 28.0,
              )),
              
              // Controls Section
              if (!_isSessionActive) _buildControlsSection(),
              
              // Progress and Stats
              if (_isSessionActive) _buildProgressSection(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveValue(
        context: context,
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
      )),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.air,
              size: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 28.0,
                tablet: 32.0,
                desktop: 36.0,
              ),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSessionActive ? 'Breathing Session Active' : 'Breathing Exercise',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                    fontSize: ResponsiveUtils.getResponsiveValue(
                      context: context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSessionActive 
                    ? 'Level $_exerciseLevel • ${_breathingCycle + 1} cycles completed'
                    : 'Guided 4-7-8 breathing technique for relaxation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                    fontSize: ResponsiveUtils.getResponsiveValue(
                      context: context,
                      mobile: 14.0,
                      tablet: 15.0,
                      desktop: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSessionActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildMainBreathingInterface() {
    final circleSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 280.0,
      tablet: 320.0,
      desktop: 360.0,
    );
    
    return SizedBox(
      height: circleSize + 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow effect
          if (_isSessionActive)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: circleSize * _pulseAnimation.value,
                  height: circleSize * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Main breathing circle
          AnimatedBuilder(
            animation: _isSessionActive ? _breathingAnimation : _pulseAnimation,
            builder: (context, child) {
              final scale = _isSessionActive 
                ? _breathingAnimation.value 
                : _pulseAnimation.value;
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.8),
                        AppColors.accent.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeUtils.getSurfaceColor(context).withOpacity(0.95),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSessionActive) ...[
                            Text(
                              _formatTime(_currentSeconds),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: ResponsiveUtils.getResponsiveValue(
                                  context: context,
                                  mobile: 32.0,
                                  tablet: 36.0,
                                  desktop: 40.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _breathingPhase,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.getResponsiveValue(
                                  context: context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 22.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level $_exerciseLevel',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(context),
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.self_improvement,
                              size: ResponsiveUtils.getResponsiveValue(
                                context: context,
                                mobile: 48.0,
                                tablet: 56.0,
                                desktop: 64.0,
                              ),
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ready to Begin',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveUtils.getResponsiveValue(
                                  context: context,
                                  mobile: 22.0,
                                  tablet: 24.0,
                                  desktop: 26.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap start to begin your\nbreathing session',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(context),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Breathing instruction overlay
          if (_isSessionActive)
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSurfaceColor(context).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPhaseIcon(),
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPhaseInstruction(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
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
  Widget _buildControlsSection() {
    return Column(
      children: [
        // Duration Selection
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Session Duration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _durations.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDuration = duration;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected 
                          ? LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            )
                          : null,
                        color: isSelected 
                          ? null 
                          : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(isSelected ? 0 : 0.3),
                          width: isSelected ? 0 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          color: isSelected 
                            ? Colors.white 
                            : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Technique Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.info.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.info.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '4-7-8 Breathing Technique',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTechniqueStep('1', 'Inhale', '4s', Icons.keyboard_arrow_up),
                  const SizedBox(width: 16),
                  _buildTechniqueStep('2', 'Hold', '7s', Icons.pause),
                  const SizedBox(width: 16),
                  _buildTechniqueStep('3', 'Exhale', '8s', Icons.keyboard_arrow_down),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reduces anxiety, improves focus, and promotes deep relaxation',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Start Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startBreathingSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Start Breathing Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildProgressSection() {
    final progress = _currentSeconds > 0 
      ? (1.0 - (_currentSeconds / (_getDurationInSeconds(_selectedDuration))))
      : 0.0;
    
    return Column(
      children: [
        // Progress Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Progress',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level $_exerciseLevel',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Cycles', '${_breathingCycle + 1}', Icons.refresh),
                  _buildStatItem('Level', '$_exerciseLevel', Icons.trending_up),
                  _buildStatItem('Time Left', _formatTime(_currentSeconds), Icons.schedule),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Stop Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _stopBreathingSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.error.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Stop Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechniqueStep(String number, String action, String duration, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(height: 4),
          Text(
            action,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.info,
            ),
          ),
          Text(
            duration,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  Widget _buildSoundsTab() {
    final sounds = [
      // Om sound as first option
      AmbientSound('Om', Icons.self_improvement, const Color(0xFFFF9933), 'om.mp3'),
      AmbientSound('Rain', Icons.grain, AppColors.info, 'rain.mp3'),
      AmbientSound('Ocean Waves', Icons.waves, AppColors.primary, 'ocean waves.mp3'),
      AmbientSound('Forest', Icons.park, AppColors.success, 'forest.mp3'),
      AmbientSound('White Noise', Icons.graphic_eq, AppColors.secondary, 'White noise.mp3'),
      AmbientSound('Singing Bowls', Icons.music_note, AppColors.accent, 'singing bowls.mp3'),
      AmbientSound('Birds', Icons.flutter_dash, AppColors.warning, 'birds.mp3'),
      AmbientSound('Thunderstorm', Icons.flash_on, const Color(0xFF6A1B9A), 'thunderstorm.mp3'),
      AmbientSound(
        'Campfire',
        Icons.local_fire_department,
        const Color(0xFFFF5722),
        'campfire.mp3',
      ),
      AmbientSound('Wind Chimes', Icons.air, const Color(0xFF00BCD4), 'wind chimes.mp3'),
      AmbientSound('Waterfall', Icons.water_drop, const Color(0xFF2196F3), 'waterfalls.mp3'),
      AmbientSound(
        'Night Crickets',
        Icons.nights_stay,
        const Color(0xFF4CAF50),
        'night cricket.mp3',
      ),
      // Removed Cafe Ambience as requested
      AmbientSound('Piano Meditation', Icons.piano, const Color(0xFF9C27B0), 'piano.mp3'),
      AmbientSound(
        'Tibetan Chants',
        Icons.self_improvement,
        const Color(0xFFFF9800),
        'Tibetan chants.mp3',
      ),
      AmbientSound('Mountain Wind', Icons.landscape, const Color(0xFF607D8B), 'mountain winds.mp3'),
      AmbientSound('River Stream', Icons.stream, const Color(0xFF009688), 'river stream.mp3'),
      AmbientSound('Desert Wind', Icons.air, const Color(0xFFFFB74D), 'dessert wind.mp3'),
      AmbientSound(
        'Monastery Bells',
        Icons.notifications,
        const Color(0xFF8BC34A),
        'Monastry bells.mp3',
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        return _buildSoundCard(sound);
      },
    );
  }

  Widget _buildSoundCard(AmbientSound sound) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AmbientSoundPlayerScreen(
                soundName: sound.name,
                soundFile: sound.fileName,
                icon: sound.icon,
                color: sound.color,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sound.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sound.icon, color: sound.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                sound.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _startGuidedSession(MeditationSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuidedMeditationSessionScreen(
          title: session.title,
          description: session.description,
          duration: session.duration,
          color: session.color,
        ),
      ),
    );
  }

  void _startBreathingSession() {
    final minutes = int.parse(_selectedDuration.split(' ')[0]);
    final totalSeconds = minutes * 60;
    
    setState(() {
      _isSessionActive = true;
      _currentSeconds = totalSeconds;
      _breathingCycle = 0;
      _breathingPhase = 'Prepare';
    });

    // Start the main timer
    _meditationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSeconds--;
      });

      if (_currentSeconds <= 0) {
        _stopBreathingSession();
        // Increase exercise level when timer completes
        _increaseExerciseLevel();
        // Play completion sound
        _audioService.playTimerCompletionSound();
      }
    });
    
    // Start breathing cycle
    _startBreathingCycle();
    
    HapticFeedback.mediumImpact();
  }

  void _startBreathingCycle() {
    _breathingTimer?.cancel();
    
    // Prepare phase (2 seconds)
    setState(() {
      _breathingPhase = 'Prepare';
    });
    
    Timer(const Duration(seconds: 2), () {
      if (!_isSessionActive) return;
      
      // Inhale phase (4 seconds)
      setState(() {
        _breathingPhase = 'Inhale';
      });
      
      _breathingAnimationController.forward();
      
      Timer(const Duration(seconds: 4), () {
        if (!_isSessionActive) return;
        
        // Hold phase (7 seconds)
        setState(() {
          _breathingPhase = 'Hold';
        });
        
        Timer(const Duration(seconds: 7), () {
          if (!_isSessionActive) return;
          
          // Exhale phase (8 seconds)
          setState(() {
            _breathingPhase = 'Exhale';
          });
          
          _breathingAnimationController.reverse();
          
          Timer(const Duration(seconds: 8), () {
            if (!_isSessionActive) return;
            
            // Complete cycle
            setState(() {
              _breathingCycle++;
              _breathingPhase = 'Rest';
            });
            
            // Rest for 2 seconds before next cycle
            Timer(const Duration(seconds: 2), () {
              if (_isSessionActive) {
                _startBreathingCycle();
              }
            });
          });
        });
      });
    });
  }

  void _stopBreathingSession() {
    _meditationTimer?.cancel();
    _breathingTimer?.cancel();
    _breathingAnimationController.reset();
    
    setState(() {
      _isSessionActive = false;
      _breathingPhase = 'Prepare';
      _currentSeconds = 0;
    });
    
    HapticFeedback.lightImpact();
  }

  void _increaseExerciseLevel() {
    setState(() {
      _exerciseLevel = math.min(_exerciseLevel + 1, 10); // Max level 10
    });
    
    // Show level up notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white),
              const SizedBox(width: 8),
              Text('Level up! You\'re now at Level $_exerciseLevel'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  int _getDurationInSeconds(String duration) {
    final minutes = int.parse(duration.split(' ')[0]);
    return minutes * 60;
  }

  IconData _getPhaseIcon() {
    switch (_breathingPhase) {
      case 'Inhale':
        return Icons.keyboard_arrow_up;
      case 'Hold':
        return Icons.pause;
      case 'Exhale':
        return Icons.keyboard_arrow_down;
      case 'Rest':
        return Icons.self_improvement;
      default:
        return Icons.air;
    }
  }

  String _getPhaseInstruction() {
    switch (_breathingPhase) {
      case 'Prepare':
        return 'Get ready to breathe';
      case 'Inhale':
        return 'Breathe in slowly';
      case 'Hold':
        return 'Hold your breath';
      case 'Exhale':
        return 'Breathe out slowly';
      case 'Rest':
        return 'Relax and prepare';
      default:
        return 'Focus on your breath';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class MeditationSession {
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final IconData icon;
  final Color color;

  MeditationSession({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.icon,
    required this.color,
  });
}

class AmbientSound {
  final String name;
  final IconData icon;
  final Color color;
  final String fileName;

  AmbientSound(this.name, this.icon, this.color, this.fileName);
}

/// Emotion types for simplified system
enum EmotionType {
  happy,
  normal,
  sad,
}

/// Emotion option data class
class EmotionOption {
  final EmotionType type;
  final String emoji;
  final String label;
  final Color color;

  EmotionOption({
    required this.type,
    required this.emoji,
    required this.label,
    required this.color,
  });
}