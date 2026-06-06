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
    required this.dateLabel,
    required this.timeLabel,
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
    required this.participants,
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
  });

  final String id;
  final HomeCategory category;
  final double distanceKm;
  final String distanceLabel;
  final String title;
  final String dateLabel;
  final String timeLabel;
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
  final List<HomeParticipant> participants;
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

  bool get isCompleted => status == 'completed';

  bool get isApprovalRequired => groupType == 'approval';

  bool get isParticipationPending => participationStatus == 'pending';

  HomeActivity copyWith({
    HomeCategory? category,
    List<HomeParticipant>? participants,
    int? availableSpots,
    String? spotsLabel,
    String? status,
    String? groupType,
    String? minReputationLevel,
    bool? requiresIdentityVerified,
    bool? isPrivateLocation,
    List<String>? targetAgeBands,
    List<String>? targetGenders,
    bool? isJoined,
    String? participationStatus,
    bool? isOwnedByCurrentUser,
  }) {
    return HomeActivity(
      id: id,
      category: category ?? this.category,
      distanceKm: distanceKm,
      distanceLabel: distanceLabel,
      title: title,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
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
      participants: participants ?? this.participants,
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
    );
  }

  HomeActivity applyParticipationUpdate(ActivityParticipationUpdate update) {
    if (update.activityId != id) {
      return this;
    }

    return copyWith(
      participants: update.participants,
      availableSpots: update.availableSpots,
      spotsLabel: update.spotsLabel,
      isJoined: update.isJoined,
      participationStatus: update.participationStatus,
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
    dateLabel,
    timeLabel,
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
    participants,
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
  ];
}
