import 'package:equatable/equatable.dart';

class HomeParticipant extends Equatable {
  const HomeParticipant({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.isHost,
    this.avatarUrl,
    this.attendanceStatus,
    this.attendanceMarkedAt,
    this.feedbackSubmitted = false,
  });

  final String id;
  final String displayName;
  final String initials;
  final bool isHost;
  final String? avatarUrl;
  final String? attendanceStatus;
  final DateTime? attendanceMarkedAt;
  final bool feedbackSubmitted;

  bool get canOpenProfile => id.isNotEmpty;

  bool get isAttendancePresent => attendanceStatus == 'present';

  bool get isAttendanceAbsent => attendanceStatus == 'absent';

  bool get isAttendanceUnknown =>
      attendanceStatus == null || attendanceStatus == 'unknown';

  HomeParticipant copyWith({
    String? attendanceStatus,
    DateTime? attendanceMarkedAt,
    bool? feedbackSubmitted,
  }) {
    return HomeParticipant(
      id: id,
      displayName: displayName,
      initials: initials,
      isHost: isHost,
      avatarUrl: avatarUrl,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      attendanceMarkedAt: attendanceMarkedAt ?? this.attendanceMarkedAt,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    initials,
    isHost,
    avatarUrl,
    attendanceStatus,
    attendanceMarkedAt,
    feedbackSubmitted,
  ];
}
