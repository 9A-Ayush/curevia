import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/mood_provider.dart';
import '../../models/mood_model.dart' as mood_model;
import '../../widgets/mood_history_widget.dart';
import '../../widgets/index_status_banner.dart';
import '../../utils/firestore_index_helper.dart';

/// Mood tracking dashboard screen
class MoodDashboardScreen extends ConsumerStatefulWidget {
  const MoodDashboardScreen({super.key});

  @override
  ConsumerState<MoodDashboardScreen> createState() => _MoodDashboardScreenState();
}

class _MoodDashboardScreenState extends ConsumerState<MoodDashboardScreen> {
  final String _userId = 'current_user_id'; // TODO: Get from auth provider

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final moodNotifier = ref.read(moodTrackingProvider.notifier);
    moodNotifier.loadMoodHistory(userId: _userId);
    moodNotifier.loadMoodStatistics(userId: _userId);
    moodNotifier.checkTodaysMoodEntry(_userId);
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodTrackingProvider);
    final todaysMoodAsync = ref.watch(todaysMoodCheckProvider(_userId));

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Mood Dashboard'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => FirestoreIndexHelper.showIndexStatusDialog(context, _userId),
            tooltip: 'Index Status',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: IndexStatusBanner(
        userId: _userId,
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick mood entry section
                _buildQuickMoodEntry(),
                const SizedBox(height: 24),

                // Today's mood status
                todaysMoodAsync.when(
                  data: (hasLogged) => _buildTodaysMoodStatus(hasLogged),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Mood history widget
                Text(
                  'Mood History & Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                MoodHistoryWidget(userId: _userId),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickMoodDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mood),
        label: const Text('Log Mood'),
      ),
    );
  }

  /// Build quick mood entry section
  Widget _buildQuickMoodEntry() {
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How are you feeling today?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your emotional wellbeing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: mood_model.EmotionType.values.map((emotion) {
                return _buildQuickEmotionButton(emotion);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick emotion button
  Widget _buildQuickEmotionButton(mood_model.EmotionType emotion) {
    return GestureDetector(
      onTap: () => _logMood(emotion),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emotion.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              emotion.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build today's mood status
  Widget _buildTodaysMoodStatus(bool hasLogged) {
    if (!hasLogged) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Haven\'t logged your mood today',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Take a moment to check in with yourself',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showQuickMoodDialog,
                child: const Text('Log Now'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.success.withOpacity(0.1),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Great! You\'ve logged your mood today',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show quick mood dialog
  void _showQuickMoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How are you feeling?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select your current mood:'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: mood_model.EmotionType.values.map((emotion) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _logMood(emotion);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emotion.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(
                          emotion.displayName,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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

  /// Log mood
  void _logMood(mood_model.EmotionType emotion) async {
    final moodNotifier = ref.read(moodTrackingProvider.notifier);
    
    final entryId = await moodNotifier.saveMoodEntry(
      userId: _userId,
      emotionType: emotion,
      metadata: {
        'source': 'mood_dashboard',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (entryId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood logged: ${emotion.displayName}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}