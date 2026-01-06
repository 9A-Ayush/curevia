import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_model.dart';
import '../providers/mood_provider.dart';
import '../constants/app_colors.dart';
import '../utils/theme_utils.dart';

/// Widget for displaying mood history with real-time updates
class MoodHistoryWidget extends ConsumerWidget {
  final String userId;
  final int? limit;

  const MoodHistoryWidget({
    super.key,
    required this.userId,
    this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodEntriesAsync = ref.watch(moodEntriesStreamProvider(userId));
    final moodStatisticsAsync = ref.watch(moodStatisticsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics section
        moodStatisticsAsync.when(
          data: (statistics) => _buildStatisticsCard(context, statistics),
          loading: () => const _LoadingCard(),
          error: (error, stack) => _buildErrorCard(context, 'Error loading statistics'),
        ),
        
        const SizedBox(height: 16),
        
        // Mood entries list
        Text(
          'Recent Entries',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        moodEntriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return _buildEmptyState(context);
            }

            final displayEntries = limit != null 
                ? entries.take(limit!).toList() 
                : entries;

            return Column(
              children: displayEntries.map((entry) => 
                _buildMoodHistoryItem(context, entry)
              ).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildErrorCard(
            context, 
            'Error loading mood history: $error',
          ),
        ),
      ],
    );
  }

  /// Build statistics card
  Widget _buildStatisticsCard(BuildContext context, MoodStatistics statistics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  statistics.trendIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mood Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statistics.trendMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (statistics.totalEntries > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Total Entries',
                    statistics.totalEntries.toString(),
                    Icons.timeline,
                    AppColors.primary,
                  ),
                  _buildStatItem(
                    context,
                    'Avg Score',
                    statistics.averageMoodScore.toStringAsFixed(1),
                    Icons.trending_up,
                    _getScoreColor(statistics.averageMoodScore),
                  ),
                  if (statistics.dominantMood != null)
                    _buildStatItem(
                      context,
                      'Most Common',
                      statistics.dominantMood!.emoji,
                      Icons.mood,
                      AppColors.info,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Get color based on mood score
  Color _getScoreColor(double score) {
    if (score >= 1.5) return AppColors.success;
    if (score >= 1.0) return AppColors.warning;
    return AppColors.error;
  }

  /// Build mood history item
  Widget _buildMoodHistoryItem(BuildContext context, MoodEntry entry) {
    final timeAgo = _getTimeAgo(entry.timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getEmotionColor(entry.emotionType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getEmotionColor(entry.emotionType).withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              entry.mood,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          entry.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          timeAgo,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.notes != null)
              Icon(
                Icons.note_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
        onTap: () => _showMoodEntryDetails(context, entry),
      ),
    );
  }

  /// Get emotion color
  Color _getEmotionColor(EmotionType emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return AppColors.success;
      case EmotionType.normal:
        return AppColors.info;
      case EmotionType.sad:
        return AppColors.warning;
    }
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.mood_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No mood entries yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your mood to see your history here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(BuildContext context, String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show mood entry details
  void _showMoodEntryDetails(BuildContext context, MoodEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEmotionColor(entry.emotionType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(entry.mood, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    _getTimeAgo(entry.timestamp),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: entry.notes != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(entry.notes!),
                ],
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get time ago string
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday, ${_formatTime(timestamp)}';
      } else {
        return '${difference.inDays} days ago, ${_formatTime(timestamp)}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Loading card widget
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}