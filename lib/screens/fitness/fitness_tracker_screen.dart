import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../services/fitness/fitness_service.dart';
import '../../services/fitness/fitness_permissions.dart';

/// Fitness Tracker Screen for monitoring daily activities
class FitnessTrackerScreen extends StatefulWidget {
  const FitnessTrackerScreen({super.key});

  @override
  State<FitnessTrackerScreen> createState() => _FitnessTrackerScreenState();
}

class _FitnessTrackerScreenState extends State<FitnessTrackerScreen> {
  final FitnessService _fitnessService = FitnessService();

  // Real-time fitness data
  int _dailySteps = 0;
  int _stepGoal = 10000;
  double _caloriesBurned = 0.0;
  double _distanceKm = 0.0;
  int _activeMinutes = 0;

  // Stream subscriptions
  StreamSubscription<int>? _stepsSubscription;
  StreamSubscription<double>? _caloriesSubscription;
  StreamSubscription<double>? _distanceSubscription;

  // Loading and permission states
  bool _isLoading = true;
  bool _hasPermissions = false;
  bool _isInitialized = false;

  // Workout UI timer
  Timer? _workoutUITimer;

  @override
  void initState() {
    super.initState();
    _initializeFitnessTracking();
  }

  @override
  void dispose() {
    _stepsSubscription?.cancel();
    _caloriesSubscription?.cancel();
    _distanceSubscription?.cancel();
    _workoutUITimer?.cancel();
    _fitnessService.dispose();
    super.dispose();
  }

  /// Initialize fitness tracking
  Future<void> _initializeFitnessTracking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check and request permissions
      _hasPermissions = await FitnessPermissions.arePermissionsGranted();

      if (!_hasPermissions && mounted) {
        _hasPermissions = await FitnessPermissions.requestAllPermissions(
          context,
        );
      }

      if (_hasPermissions) {
        // Initialize fitness service
        _isInitialized = await _fitnessService.initialize();

        if (_isInitialized) {
          _setupDataStreams();
          _loadInitialData();
        }
      }
    } catch (e) {
      debugPrint('Error initializing fitness tracking: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Setup data streams
  void _setupDataStreams() {
    _stepsSubscription = _fitnessService.stepsStream.listen((steps) {
      setState(() {
        _dailySteps = steps;
      });
    });

    _caloriesSubscription = _fitnessService.caloriesStream.listen((calories) {
      setState(() {
        _caloriesBurned = calories;
      });
    });

    _distanceSubscription = _fitnessService.distanceStream.listen((distance) {
      setState(() {
        _distanceKm = distance;
      });
    });
  }

  /// Load initial data
  void _loadInitialData() {
    setState(() {
      _dailySteps = _fitnessService.currentSteps;
      _stepGoal = _fitnessService.stepGoal;
      _caloriesBurned = _fitnessService.currentCalories;
      _distanceKm = _fitnessService.currentDistance;

      // Calculate active minutes based on steps (rough estimate)
      _activeMinutes = (_dailySteps / 100).round(); // ~100 steps per minute
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showFitnessHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing fitness tracking...'),
          ],
        ),
      );
    }

    if (!_hasPermissions) {
      return _buildPermissionDeniedView();
    }

    if (!_isInitialized) {
      return _buildInitializationFailedView();
    }

    return Column(
      children: [
        // Header with info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeUtils.getPrimaryColor(context),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
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
                          'Track your fitness journey',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Monitor steps, calories, and activities',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.directions_walk, '${_dailySteps} Steps'),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.local_fire_department,
                    '${_caloriesBurned.toInt()} Cal',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Workout Status (if any)
                if (_fitnessService.isWorkoutActive) ...[
                  _buildActiveWorkoutCard(),
                  const SizedBox(height: 16),
                ],

                // Steps Progress Card
                _buildStepsCard(),
                const SizedBox(height: 16),

                // Activity Stats Grid
                _buildActivityStatsGrid(),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 24),

                // Weekly Summary
                _buildWeeklySummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build permission denied view
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Permissions Required',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitness tracking requires access to your device sensors and activity data to monitor your steps, calories, and workouts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Check if permissions can be requested directly
                final canRequest = await FitnessPermissions.canRequestPermissions();
                
                if (canRequest) {
                  // First try to request permissions directly
                  final granted = await _fitnessService.requestPermissions();
                  if (granted) {
                    _initializeFitnessTracking();
                  } else {
                    // If direct request fails, try the fitness permissions flow
                    final fitnessGranted = await FitnessPermissions.requestAllPermissions(context);
                    if (fitnessGranted) {
                      _initializeFitnessTracking();
                    }
                  }
                } else {
                  // Permissions are permanently denied, show settings
                  await FitnessPermissions.showPermissionSettings(context);
                }
              },
              icon: const Icon(Icons.security),
              label: const Text('Grant Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await FitnessPermissions.showPermissionSettings(context);
              },
              child: const Text('View Permission Status'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build initialization failed view
  Widget _buildInitializationFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Initialization Failed',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to initialize fitness tracking. Please try again.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeFitnessTracking,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWorkoutCard() {
    final progress = _fitnessService.getWorkoutProgress();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success,
              AppColors.success.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${progress['workoutType']} Workout Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Duration: ${progress['duration']} minutes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showWorkoutProgress,
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  tooltip: 'View Progress',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWorkoutStat(
                    'Steps',
                    _formatNumber(progress['steps']),
                    Icons.directions_walk,
                  ),
                ),
                Expanded(
                  child: _buildWorkoutStat(
                    'Calories',
                    '${progress['calories'].toStringAsFixed(0)}',
                    Icons.local_fire_department,
                  ),
                ),
                Expanded(
                  child: _buildWorkoutStat(
                    'Distance',
                    '${progress['distance'].toStringAsFixed(2)} km',
                    Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stopWorkout,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    final progress = _dailySteps / _stepGoal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_walk,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Steps',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_dailySteps / $_stepGoal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_stepGoal - _dailySteps)} steps to reach your goal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Stats',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Distance',
                '${_distanceKm.toStringAsFixed(1)} km',
                Icons.straighten,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Time',
                '$_activeMinutes min',
                Icons.timer,
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Start Workout',
                Icons.play_arrow,
                AppColors.primary,
                _startWorkout,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Log Activity',
                Icons.add,
                AppColors.secondary,
                _logActivity,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fitnessService.getWeeklySummary(),
      builder: (context, snapshot) {
        final weeklyData =
            snapshot.data ??
            {
              'totalSteps': _dailySteps * 7,
              'avgDaily': _dailySteps,
              'bestDay': (_dailySteps * 1.2).round(),
              'improvement': 10,
            };

        // Get current week date range
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));

        final weekRange = '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Summary',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            weekRange,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeekStat(
                      'Total Steps',
                      _formatNumber(weeklyData['totalSteps']),
                    ),
                    _buildWeekStat(
                      'Avg Daily',
                      _formatNumber(weeklyData['avgDaily']),
                    ),
                    _buildWeekStat(
                      'Best Day',
                      _formatNumber(weeklyData['bestDay']),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You\'re ${weeklyData['improvement']}% more active than last week!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Show fitness history
  void _showFitnessHistory() async {
    final weeklySummary = await _fitnessService.getWeeklySummary();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weekly Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHistoryItem('Total Steps', '${weeklySummary['totalSteps']}'),
            _buildHistoryItem('Daily Average', '${weeklySummary['avgDaily']}'),
            _buildHistoryItem('Best Day', '${weeklySummary['bestDay']}'),
            _buildHistoryItem(
              'Improvement',
              '+${weeklySummary['improvement']}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Show settings
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fitness Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Set Goals'),
              onTap: () {
                Navigator.pop(context);
                _showGoalSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Permissions'),
              onTap: () {
                Navigator.pop(context);
                FitnessPermissions.showPermissionSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _initializeFitnessTracking();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show goal settings
  void _showGoalSettings() {
    final stepController = TextEditingController(text: _stepGoal.toString());
    final calorieController = TextEditingController(
      text: _fitnessService.calorieGoal.toString(),
    );
    final distanceController = TextEditingController(
      text: _fitnessService.distanceGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Fitness Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepController,
              decoration: const InputDecoration(
                labelText: 'Daily Steps Goal',
                suffixText: 'steps',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: calorieController,
              decoration: const InputDecoration(
                labelText: 'Daily Calories Goal',
                suffixText: 'cal',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(
                labelText: 'Daily Distance Goal',
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final steps = int.tryParse(stepController.text);
              final calories = double.tryParse(calorieController.text);
              final distance = double.tryParse(distanceController.text);

              if (steps != null && calories != null && distance != null) {
                // Store context before async operation
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                await _fitnessService.setGoals(
                  stepGoal: steps,
                  calorieGoal: calories,
                  distanceGoal: distance,
                );

                setState(() {
                  _stepGoal = steps;
                });

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Goals updated successfully!'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Start workout
  void _startWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text('Walking'),
              onTap: () => _startWorkoutType('Walking'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_run),
              title: const Text('Running'),
              onTap: () => _startWorkoutType('Running'),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Gym Workout'),
              onTap: () => _startWorkoutType('Gym'),
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('Other'),
              onTap: () => _startWorkoutType('Other'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Start specific workout type
  void _startWorkoutType(String type) {
    Navigator.pop(context);

    // Start workout using fitness service
    final result = _fitnessService.startWorkout(type);

    if (result['success']) {
      // Show success message with workout details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Started at: ${_formatTime(DateTime.parse(result['startTime']))}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View Progress',
            textColor: Colors.white,
            onPressed: _showWorkoutProgress,
          ),
        ),
      );

      // Update UI to show workout is active and start UI timer
      setState(() {
        // Trigger rebuild to show workout status
      });

      // Start UI update timer for real-time workout progress
      _startWorkoutUITimer();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Log manual activity
  void _logActivity() {
    final stepsController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsController,
              decoration: const InputDecoration(
                labelText: 'Steps',
                suffixText: 'steps',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories Burned',
                suffixText: 'cal',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final steps = int.tryParse(stepsController.text) ?? 0;
              final calories = double.tryParse(caloriesController.text) ?? 0.0;

              if (steps > 0 || calories > 0) {
                setState(() {
                  _dailySteps += steps;
                  _caloriesBurned += calories;
                  _distanceKm += (steps * 0.0008); // Rough estimate
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity logged successfully!'),
                  ),
                );
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  /// Format date for display (e.g., "Jan 15")
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Format numbers with commas (e.g., "1,234")
  String _formatNumber(dynamic number) {
    if (number == null) return '0';

    final int value = number is int ? number : (number as double).round();
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Format time for display (e.g., "2:30 PM")
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final displayHour = hour == 0 ? 12 : hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:$minute $period';
  }

  /// Show workout progress dialog
  void _showWorkoutProgress() {
    final progress = _fitnessService.getWorkoutProgress();

    if (!progress['active']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active workout')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${progress['workoutType']} Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressItem('Duration', '${progress['duration']} minutes'),
            _buildProgressItem('Steps', _formatNumber(progress['steps'])),
            _buildProgressItem(
              'Distance',
              '${progress['distance'].toStringAsFixed(2)} km',
            ),
            _buildProgressItem(
              'Calories',
              '${progress['calories'].toStringAsFixed(0)} cal',
            ),
            const SizedBox(height: 16),
            Text(
              'Started at: ${_formatTime(DateTime.parse(progress['startTime']))}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopWorkout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Stop Workout'),
          ),
        ],
      ),
    );
  }

  /// Build progress item widget
  Widget _buildProgressItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Stop current workout
  void _stopWorkout() {
    final result = _fitnessService.stopWorkout();

    // Stop UI update timer
    _stopWorkoutUITimer();

    if (result['success']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Workout Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${result['workoutType']} workout finished'),
              const SizedBox(height: 16),
              _buildProgressItem('Duration', '${result['duration']} minutes'),
              _buildProgressItem('Steps', _formatNumber(result['steps'])),
              _buildProgressItem(
                'Distance',
                '${result['distance'].toStringAsFixed(2)} km',
              ),
              _buildProgressItem(
                'Calories',
                '${result['calories'].toStringAsFixed(0)} cal',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  // Refresh UI
                });
              },
              child: const Text('Great!'),
            ),
          ],
        ),
      );
    }
  }

  /// Start workout UI update timer
  void _startWorkoutUITimer() {
    _workoutUITimer?.cancel(); // Cancel any existing timer
    _workoutUITimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_fitnessService.isWorkoutActive && mounted) {
        setState(() {
          // Update UI with latest workout progress
        });
      } else {
        // Workout is no longer active, stop timer
        timer.cancel();
        _workoutUITimer = null;
      }
    });
  }

  /// Stop workout UI update timer
  void _stopWorkoutUITimer() {
    _workoutUITimer?.cancel();
    _workoutUITimer = null;
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
