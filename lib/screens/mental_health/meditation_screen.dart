import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import 'guided_meditation_session_screen.dart';
import 'ambient_sound_player_screen.dart';

/// Meditation Screen with guided sessions and breathing exercises
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _meditationTimer;
  int _currentSeconds = 0;
  bool _isSessionActive = false;
  String _selectedDuration = '5 min';

  final List<String> _durations = [
    '1 min',
    '3 min',
    '5 min',
    '10 min',
    '15 min',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _meditationTimer?.cancel();
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
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
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
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
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
                  color: session.color.withValues(alpha: 0.1),
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
        color: ThemeUtils.getSurfaceColor(context).withValues(alpha: 0.5),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Duration Selection
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Duration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _durations.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return FilterChip(
                        label: Text(duration),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDuration = duration;
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Breathing Exercise
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSessionActive
                          ? 'Breathing Exercise'
                          : '4-7-8 Breathing',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_isSessionActive) ...[
                      Text(
                        'Inhale for 4 counts\nHold for 7 counts\nExhale for 8 counts',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Timer Display
                    if (_isSessionActive) ...[
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _formatTime(_currentSeconds),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Control Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSessionActive
                            ? _stopBreathingSession
                            : _startBreathingSession,
                        icon: Icon(
                          _isSessionActive ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(
                          _isSessionActive ? 'Stop Session' : 'Start Session',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSessionActive
                              ? AppColors.error
                              : AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundsTab() {
    final sounds = [
      AmbientSound('Rain', Icons.grain, AppColors.info),
      AmbientSound('Ocean Waves', Icons.waves, AppColors.primary),
      AmbientSound('Forest', Icons.park, AppColors.success),
      AmbientSound('White Noise', Icons.graphic_eq, AppColors.secondary),
      AmbientSound('Singing Bowls', Icons.music_note, AppColors.accent),
      AmbientSound('Birds', Icons.flutter_dash, AppColors.warning),
      AmbientSound('Thunderstorm', Icons.flash_on, const Color(0xFF6A1B9A)),
      AmbientSound(
        'Campfire',
        Icons.local_fire_department,
        const Color(0xFFFF5722),
      ),
      AmbientSound('Wind Chimes', Icons.air, const Color(0xFF00BCD4)),
      AmbientSound('Waterfall', Icons.water_drop, const Color(0xFF2196F3)),
      AmbientSound(
        'Night Crickets',
        Icons.nights_stay,
        const Color(0xFF4CAF50),
      ),
      AmbientSound('Cafe Ambience', Icons.coffee, const Color(0xFF795548)),
      AmbientSound('Piano Meditation', Icons.piano, const Color(0xFF9C27B0)),
      AmbientSound(
        'Tibetan Chants',
        Icons.self_improvement,
        const Color(0xFFFF9800),
      ),
      AmbientSound('Mountain Wind', Icons.landscape, const Color(0xFF607D8B)),
      AmbientSound('River Stream', Icons.stream, const Color(0xFF009688)),
      AmbientSound('Desert Wind', Icons.air, const Color(0xFFFFB74D)),
      AmbientSound(
        'Monastery Bells',
        Icons.notifications,
        const Color(0xFF8BC34A),
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
                  color: sound.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sound.icon, color: sound.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                sound.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
    });

    _meditationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSeconds--;
      });

      if (_currentSeconds <= 0) {
        _stopBreathingSession();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Breathing session completed! Well done.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _stopBreathingSession() {
    _meditationTimer?.cancel();
    setState(() {
      _isSessionActive = false;
      _currentSeconds = 0;
    });
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

  AmbientSound(this.name, this.icon, this.color);
}
