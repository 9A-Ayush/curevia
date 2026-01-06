import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/mental_health/mental_health_screen.dart';
import '../screens/mental_health/mood_dashboard_screen.dart';
import '../providers/mood_provider.dart';
import '../models/mood_model.dart' as mood_model;

/// Example of how to integrate mood tracking into your app
class MoodTrackingIntegrationExample extends ConsumerWidget {
  const MoodTrackingIntegrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracking Integration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood Tracking Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Navigation to Mental Health Screen
            _buildFeatureCard(
              context,
              'Mental Health Screen',
              'Complete mental health support with mood tracking',
              Icons.psychology,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MentalHealthScreen(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Navigation to Mood Dashboard
            _buildFeatureCard(
              context,
              'Mood Dashboard',
              'Dedicated mood tracking and analytics',
              Icons.dashboard,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoodDashboardScreen(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick mood logging example
            _buildFeatureCard(
              context,
              'Quick Mood Log',
              'Log your mood directly from anywhere',
              Icons.mood,
              () => _showQuickMoodDialog(context, ref),
            ),
            
            const SizedBox(height: 20),
            
            // Real-time mood stream example
            const Text(
              'Recent Mood Entries (Real-time)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: _buildRecentMoodEntries(ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Build feature card
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  /// Build recent mood entries with real-time updates
  Widget _buildRecentMoodEntries(WidgetRef ref) {
    const userId = 'current_user_id'; // TODO: Get from auth provider
    final moodEntriesAsync = ref.watch(moodEntriesStreamProvider(userId));

    return moodEntriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mood_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No mood entries yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Start tracking your mood to see entries here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length > 5 ? 5 : entries.length, // Show max 5 entries
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  entry.mood,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(entry.label),
                subtitle: Text(_getTimeAgo(entry.timestamp)),
                trailing: entry.notes != null
                    ? const Icon(Icons.note_outlined, size: 16)
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading mood entries: $error'),
          ],
        ),
      ),
    );
  }

  /// Show quick mood dialog
  void _showQuickMoodDialog(BuildContext context, WidgetRef ref) {
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
                    _logMood(context, ref, emotion);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
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
  void _logMood(BuildContext context, WidgetRef ref, mood_model.EmotionType emotion) async {
    const userId = 'current_user_id'; // TODO: Get from auth provider
    final moodNotifier = ref.read(moodTrackingProvider.notifier);
    
    final entryId = await moodNotifier.saveMoodEntry(
      userId: userId,
      emotionType: emotion,
      metadata: {
        'source': 'quick_log',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (entryId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood logged: ${emotion.displayName}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Get time ago string
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Example of how to add mood tracking to your existing screens
class ExistingScreenWithMoodTracking extends ConsumerWidget {
  const ExistingScreenWithMoodTracking({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const userId = 'current_user_id'; // TODO: Get from auth provider
    final todaysMoodAsync = ref.watch(todaysMoodCheckProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Existing Screen'),
        actions: [
          // Add mood tracking to any screen
          IconButton(
            icon: const Icon(Icons.mood),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MoodDashboardScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Your existing content here
          const Expanded(
            child: Center(
              child: Text('Your existing screen content'),
            ),
          ),
          
          // Add mood reminder at bottom
          todaysMoodAsync.when(
            data: (hasLogged) {
              if (!hasLogged) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mood, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Haven\'t logged your mood today',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MentalHealthScreen(),
                          ),
                        ),
                        child: const Text('Log Now'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}