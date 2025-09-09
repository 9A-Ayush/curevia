import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enum for video call status
enum VideoCallStatus {
  scheduled,
  waiting,
  connecting,
  connected,
  ended,
  failed,
  cancelled,
}

/// Enum for participant role
enum ParticipantRole {
  doctor,
  patient,
}

/// Model representing a video call participant
class VideoCallParticipant extends Equatable {
  final String id;
  final String name;
  final String? profileImage;
  final ParticipantRole role;
  final bool isHost;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isVideoEnabled;
  final String? connectionStatus;

  const VideoCallParticipant({
    required this.id,
    required this.name,
    this.profileImage,
    required this.role,
    required this.isHost,
    required this.joinedAt,
    this.leftAt,
    required this.isMuted,
    required this.isVideoEnabled,
    this.connectionStatus,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        profileImage,
        role,
        isHost,
        joinedAt,
        leftAt,
        isMuted,
        isVideoEnabled,
        connectionStatus,
      ];

  VideoCallParticipant copyWith({
    String? id,
    String? name,
    String? profileImage,
    ParticipantRole? role,
    bool? isHost,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isMuted,
    bool? isVideoEnabled,
    String? connectionStatus,
  }) {
    return VideoCallParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'role': role.name,
      'isHost': isHost,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'isMuted': isMuted,
      'isVideoEnabled': isVideoEnabled,
      'connectionStatus': connectionStatus,
    };
  }

  factory VideoCallParticipant.fromMap(Map<String, dynamic> map) {
    return VideoCallParticipant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      profileImage: map['profileImage'],
      role: ParticipantRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => ParticipantRole.patient,
      ),
      isHost: map['isHost'] ?? false,
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      leftAt: (map['leftAt'] as Timestamp?)?.toDate(),
      isMuted: map['isMuted'] ?? false,
      isVideoEnabled: map['isVideoEnabled'] ?? true,
      connectionStatus: map['connectionStatus'],
    );
  }
}

/// Model representing a video call session
class VideoCallModel extends Equatable {
  final String id;
  final String appointmentId;
  final String roomId;
  final String? meetingLink;
  final String? accessToken;
  final VideoCallStatus status;
  final DateTime scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final List<VideoCallParticipant> participants;
  final String? recordingUrl;
  final bool isRecorded;
  final String? chatTranscript;
  final Map<String, dynamic>? callSettings;
  final String? endReason;
  final Map<String, dynamic>? callQuality;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoCallModel({
    required this.id,
    required this.appointmentId,
    required this.roomId,
    this.meetingLink,
    this.accessToken,
    required this.status,
    required this.scheduledStartTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes,
    required this.participants,
    this.recordingUrl,
    required this.isRecorded,
    this.chatTranscript,
    this.callSettings,
    this.endReason,
    this.callQuality,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        roomId,
        meetingLink,
        accessToken,
        status,
        scheduledStartTime,
        actualStartTime,
        actualEndTime,
        plannedDurationMinutes,
        actualDurationMinutes,
        participants,
        recordingUrl,
        isRecorded,
        chatTranscript,
        callSettings,
        endReason,
        callQuality,
        createdAt,
        updatedAt,
      ];

  VideoCallModel copyWith({
    String? id,
    String? appointmentId,
    String? roomId,
    String? meetingLink,
    String? accessToken,
    VideoCallStatus? status,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? plannedDurationMinutes,
    int? actualDurationMinutes,
    List<VideoCallParticipant>? participants,
    String? recordingUrl,
    bool? isRecorded,
    String? chatTranscript,
    Map<String, dynamic>? callSettings,
    String? endReason,
    Map<String, dynamic>? callQuality,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoCallModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      roomId: roomId ?? this.roomId,
      meetingLink: meetingLink ?? this.meetingLink,
      accessToken: accessToken ?? this.accessToken,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      participants: participants ?? this.participants,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      isRecorded: isRecorded ?? this.isRecorded,
      chatTranscript: chatTranscript ?? this.chatTranscript,
      callSettings: callSettings ?? this.callSettings,
      endReason: endReason ?? this.endReason,
      callQuality: callQuality ?? this.callQuality,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'roomId': roomId,
      'meetingLink': meetingLink,
      'accessToken': accessToken,
      'status': status.name,
      'scheduledStartTime': Timestamp.fromDate(scheduledStartTime),
      'actualStartTime': actualStartTime != null ? Timestamp.fromDate(actualStartTime!) : null,
      'actualEndTime': actualEndTime != null ? Timestamp.fromDate(actualEndTime!) : null,
      'plannedDurationMinutes': plannedDurationMinutes,
      'actualDurationMinutes': actualDurationMinutes,
      'participants': participants.map((p) => p.toMap()).toList(),
      'recordingUrl': recordingUrl,
      'isRecorded': isRecorded,
      'chatTranscript': chatTranscript,
      'callSettings': callSettings,
      'endReason': endReason,
      'callQuality': callQuality,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory VideoCallModel.fromMap(Map<String, dynamic> map) {
    return VideoCallModel(
      id: map['id'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      roomId: map['roomId'] ?? '',
      meetingLink: map['meetingLink'],
      accessToken: map['accessToken'],
      status: VideoCallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VideoCallStatus.scheduled,
      ),
      scheduledStartTime: (map['scheduledStartTime'] as Timestamp).toDate(),
      actualStartTime: (map['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (map['actualEndTime'] as Timestamp?)?.toDate(),
      plannedDurationMinutes: map['plannedDurationMinutes'] ?? 30,
      actualDurationMinutes: map['actualDurationMinutes'],
      participants: (map['participants'] as List<dynamic>?)
              ?.map((p) => VideoCallParticipant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      recordingUrl: map['recordingUrl'],
      isRecorded: map['isRecorded'] ?? false,
      chatTranscript: map['chatTranscript'],
      callSettings: map['callSettings'],
      endReason: map['endReason'],
      callQuality: map['callQuality'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get the doctor participant
  VideoCallParticipant? get doctor {
    try {
      return participants.firstWhere((p) => p.role == ParticipantRole.doctor);
    } catch (e) {
      return null;
    }
  }

  /// Get the patient participant
  VideoCallParticipant? get patient {
    try {
      return participants.firstWhere((p) => p.role == ParticipantRole.patient);
    } catch (e) {
      return null;
    }
  }

  /// Check if call is active
  bool get isActive {
    return status == VideoCallStatus.connected || 
           status == VideoCallStatus.connecting ||
           status == VideoCallStatus.waiting;
  }

  /// Check if call has ended
  bool get hasEnded {
    return status == VideoCallStatus.ended || 
           status == VideoCallStatus.failed ||
           status == VideoCallStatus.cancelled;
  }

  /// Get formatted duration
  String get formattedDuration {
    final duration = actualDurationMinutes ?? plannedDurationMinutes;
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case VideoCallStatus.scheduled:
        return 'Scheduled';
      case VideoCallStatus.waiting:
        return 'Waiting for participants';
      case VideoCallStatus.connecting:
        return 'Connecting...';
      case VideoCallStatus.connected:
        return 'In progress';
      case VideoCallStatus.ended:
        return 'Ended';
      case VideoCallStatus.failed:
        return 'Failed';
      case VideoCallStatus.cancelled:
        return 'Cancelled';
    }
  }
}
