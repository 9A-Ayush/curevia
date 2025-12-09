import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity model for tracking user activities
class ActivityModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final String? relatedId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.relatedId,
    this.metadata,
    required this.timestamp,
    required this.createdAt,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      relatedId: map['relatedId'],
      metadata: map['metadata'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'relatedId': relatedId,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get icon for activity type
  String get iconName {
    switch (type) {
      case 'appointment_booked':
      case 'appointment_completed':
        return 'calendar_today';
      case 'prescription_received':
        return 'medication';
      case 'health_record_added':
        return 'folder';
      case 'symptom_check':
        return 'medical_services';
      case 'medicine_search':
        return 'search';
      default:
        return 'info';
    }
  }

  /// Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
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
