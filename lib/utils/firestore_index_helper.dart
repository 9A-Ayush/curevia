import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for managing Firestore index status and fallbacks
class FirestoreIndexHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if mood entries indexes are ready by attempting a test query
  static Future<bool> areMoodIndexesReady(String userId) async {
    try {
      // Try a simple query that requires the index
      await _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      print('✅ Mood entries indexes are ready!');
      return true;
    } catch (e) {
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        print('⏳ Mood entries indexes are still building...');
        return false;
      }
      print('❌ Error checking index status: $e');
      return false;
    }
  }

  /// Get index status information
  static Future<IndexStatus> getMoodIndexStatus(String userId) async {
    try {
      final isReady = await areMoodIndexesReady(userId);
      
      if (isReady) {
        return IndexStatus(
          isReady: true,
          message: 'Indexes are ready! Real-time mood tracking is fully functional.',
          recommendation: 'You can use all mood tracking features without limitations.',
        );
      } else {
        return IndexStatus(
          isReady: false,
          message: 'Indexes are still building. This usually takes 5-10 minutes.',
          recommendation: 'Mood tracking will work with basic functionality. Full features will be available once indexes are ready.',
        );
      }
    } catch (e) {
      return IndexStatus(
        isReady: false,
        message: 'Unable to check index status: $e',
        recommendation: 'Please check your internet connection and Firebase configuration.',
      );
    }
  }

  /// Show index status dialog to user
  static Future<void> showIndexStatusDialog(
    context, 
    String userId,
  ) async {
    final status = await getMoodIndexStatus(userId);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                status.isReady ? Icons.check_circle : Icons.hourglass_empty,
                color: status.isReady ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(status.isReady ? 'Indexes Ready' : 'Indexes Building'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.message),
              const SizedBox(height: 12),
              Text(
                'Recommendation:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(status.recommendation),
              if (!status.isReady) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can still log moods and view history. Performance will improve once indexes are ready.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!status.isReady)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Check again after a delay
                  await Future.delayed(const Duration(seconds: 2));
                  showIndexStatusDialog(context, userId);
                },
                child: const Text('Check Again'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Periodically check index status and notify when ready
  static Stream<bool> watchIndexStatus(String userId) async* {
    while (true) {
      final isReady = await areMoodIndexesReady(userId);
      yield isReady;
      
      if (isReady) {
        break; // Stop checking once ready
      }
      
      // Wait 30 seconds before checking again
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  /// Get Firebase Console URL for index management
  static String getFirebaseConsoleIndexUrl() {
    return 'https://console.firebase.google.com/project/curevia-f31a8/firestore/indexes';
  }

  /// Get helpful tips for index building
  static List<String> getIndexBuildingTips() {
    return [
      'Index building typically takes 5-10 minutes for new collections',
      'Larger datasets may take longer to index',
      'You can monitor progress in the Firebase Console',
      'The app will work with basic functionality while indexes build',
      'Real-time features will be fully available once indexes are ready',
    ];
  }
}

/// Data class for index status information
class IndexStatus {
  final bool isReady;
  final String message;
  final String recommendation;

  const IndexStatus({
    required this.isReady,
    required this.message,
    required this.recommendation,
  });
}