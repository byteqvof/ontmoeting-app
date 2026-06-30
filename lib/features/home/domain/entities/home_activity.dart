import 'package:equatable/equatable.dart';

import 'activity_participation_update.dart';
import 'activity_completion_update.dart';
import 'home_category.dart';
import 'home_participant.dart';

class HomeActivity extends Equatable {
  const HomeActivity({
    required this.id,
    required this.category,
    required this.distanceKm,
    required this.distanceLabel,
    required this.title,
    this.isFeatured = false,
    required this.dateLabel,
    required this.timeLabel,
    this.startsAt,
    this.latitude = 0,
    this.longitude = 0,
    required this.locationName,
    required this.meetingPoint,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.hostFullName,
    required this.hostSubtitle,
    required this.hostScore,
    this.hostIdentityVerified = false,
    this.hostReputationLevel = 'new_member',
    this.hostAvatarUrl,
    this.hostFeedbackSubmitted = false,
    required this.participants,
    this.participantCount = 0,
    required this.availableSpots,
    required this.spotsLabel,
    this.status = 'published',
    this.groupType = 'open',
    this.minReputationLevel = 'new_member',
    this.requiresIdentityVerified = false,
    this.isPrivateLocation = false,
    this.targetAgeBands = const [],
    this.targetGenders = const [],
    this.isJoined = false,
    this.participationStatus,
    this.isOwnedByCurrentUser = false,
    this.chatLastMessage,
    this.chatLastMessageAt,
    this.chatLastSenderName,
    this.chatLastMessageType = 'user',
    this.chatUnreadCount = 0,
    this.canSendChat = false,
  });

  final String id;
  final HomeCategory category;
  final double distanceKm;
  final String distanceLabel;
  final String title;
  final bool isFeatured;
  final String dateLabel;
  final String timeLabel;
  final DateTime? startsAt;
  final double latitude;
  final double longitude;
  final String locationName;
  final String meetingPoint;
  final String description;
  final String hostId;
  final String hostName;
  final String hostFullName;
  final String hostSubtitle;
  final int hostScore;
  final bool hostIdentityVerified;
  final String hostReputationLevel;
  final String? hostAvatarUrl;
  final bool hostFeedbackSubmitted;
  final List<HomeParticipant> participants;
  final int participantCount;
  final int availableSpots;
  final String spotsLabel;
  final String status;
  final String groupType;
  final String minReputationLevel;
  final bool requiresIdentityVerified;
  final bool isPrivateLocation;
  final List<String> targetAgeBands;
  final List<String> targetGenders;
  final bool isJoined;
  final String? participationStatus;
  final bool isOwnedByCurrentUser;
  final String? chatLastMessage;
  final DateTime? chatLastMessageAt;
  final String? chatLastSenderName;
  final String chatLastMessageType;
  final int chatUnreadCount;
  final bool canSendChat;

  bool get isCompleted => status == 'completed';

  bool get isUpcoming => startsAt != null && startsAt!.isAfter(DateTime.now());

  bool get isChatClosed => isCompleted;

  bool get hasStarted => startsAt == null || !startsAt!.isAfter(DateTime.now());

  bool get canBeCompletedNow =>
      isOwnedByCurrentUser && !isCompleted && hasStarted;

  bool get isApprovalRequired => groupType == 'approval';

  bool get isParticipationPending => participationStatus == 'pending';

  HomeActivity copyWith({
    HomeCategory? category,
    List<HomeParticipant>? participants,
    int? participantCount,
    int? availableSpots,
    String? spotsLabel,
    String? status,
    bool? isFeatured,
    String? groupType,
    String? minReputationLevel,
    bool? requiresIdentityVerified,
    bool? isPrivateLocation,
    List<String>? targetAgeBands,
    List<String>? targetGenders,
    bool? isJoined,
    String? participationStatus,
    bool? isOwnedByCurrentUser,
    String? chatLastMessage,
    DateTime? chatLastMessageAt,
    String? chatLastSenderName,
    String? chatLastMessageType,
    int? chatUnreadCount,
    bool? canSendChat,
    bool? hostFeedbackSubmitted,
  }) {
    return HomeActivity(
      id: id,
      category: category ?? this.category,
      distanceKm: distanceKm,
      distanceLabel: distanceLabel,
      title: title,
      isFeatured: isFeatured ?? this.isFeatured,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      startsAt: startsAt,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      meetingPoint: meetingPoint,
      description: description,
      hostId: hostId,
      hostName: hostName,
      hostFullName: hostFullName,
      hostSubtitle: hostSubtitle,
      hostScore: hostScore,
      hostIdentityVerified: hostIdentityVerified,
      hostReputationLevel: hostReputationLevel,
      hostAvatarUrl: hostAvatarUrl,
      hostFeedbackSubmitted:
          hostFeedbackSubmitted ?? this.hostFeedbackSubmitted,
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
      availableSpots: availableSpots ?? this.availableSpots,
      spotsLabel: spotsLabel ?? this.spotsLabel,
      status: status ?? this.status,
      groupType: groupType ?? this.groupType,
      minReputationLevel: minReputationLevel ?? this.minReputationLevel,
      requiresIdentityVerified:
          requiresIdentityVerified ?? this.requiresIdentityVerified,
      isPrivateLocation: isPrivateLocation ?? this.isPrivateLocation,
      targetAgeBands: targetAgeBands ?? this.targetAgeBands,
      targetGenders: targetGenders ?? this.targetGenders,
      isJoined: isJoined ?? this.isJoined,
      participationStatus: participationStatus ?? this.participationStatus,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      chatLastMessage: chatLastMessage ?? this.chatLastMessage,
      chatLastMessageAt: chatLastMessageAt ?? this.chatLastMessageAt,
      chatLastSenderName: chatLastSenderName ?? this.chatLastSenderName,
      chatLastMessageType: chatLastMessageType ?? this.chatLastMessageType,
      chatUnreadCount: chatUnreadCount ?? this.chatUnreadCount,
      canSendChat: canSendChat ?? this.canSendChat,
    );
  }

  HomeActivity applyParticipationUpdate(ActivityParticipationUpdate update) {
    if (update.activityId != id) {
      return this;
    }

    return copyWith(
      participants: update.participants,
      participantCount: update.participantsCount,
      availableSpots: update.availableSpots,
      spotsLabel: update.spotsLabel,
      isJoined: update.isJoined,
      participationStatus: update.participationStatus,
      canSendChat: isOwnedByCurrentUser || update.isJoined,
    );
  }

  HomeActivity applyCompletionUpdate(ActivityCompletionUpdate update) {
    if (update.activityId != id) {
      return this;
    }

    return copyWith(status: update.status);
  }

  @override
  List<Object?> get props => [
    id,
    category,
    distanceKm,
    distanceLabel,
    title,
    isFeatured,
    dateLabel,
    timeLabel,
    startsAt,
    latitude,
    longitude,
    locationName,
    meetingPoint,
    description,
    hostId,
    hostName,
    hostFullName,
    hostSubtitle,
    hostScore,
    hostIdentityVerified,
    hostReputationLevel,
    hostAvatarUrl,
    hostFeedbackSubmitted,
    participants,
    participantCount,
    availableSpots,
    spotsLabel,
    status,
    groupType,
    minReputationLevel,
    requiresIdentityVerified,
    isPrivateLocation,
    targetAgeBands,
    targetGenders,
    isJoined,
    participationStatus,
    isOwnedByCurrentUser,
    chatLastMessage,
    chatLastMessageAt,
    chatLastSenderName,
    chatLastMessageType,
    chatUnreadCount,
    canSendChat,
  ];
}
