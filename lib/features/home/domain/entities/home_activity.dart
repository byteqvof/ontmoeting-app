import 'package:equatable/equatable.dart';

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
    required this.locationName,
    required this.meetingPoint,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.hostFullName,
    required this.hostSubtitle,
    required this.hostScore,
    this.hostAvatarUrl,
    required this.participants,
    required this.availableSpots,
    required this.spotsLabel,
    this.isJoined = false,
    this.isOwnedByCurrentUser = false,
  });

  final String id;
  final HomeCategory category;
  final double distanceKm;
  final String distanceLabel;
  final String title;
  final String dateLabel;
  final String timeLabel;
  final String locationName;
  final String meetingPoint;
  final String description;
  final String hostId;
  final String hostName;
  final String hostFullName;
  final String hostSubtitle;
  final int hostScore;
  final String? hostAvatarUrl;
  final List<HomeParticipant> participants;
  final int availableSpots;
  final String spotsLabel;
  final bool isJoined;
  final bool isOwnedByCurrentUser;

  HomeActivity copyWith({HomeCategory? category}) {
    return HomeActivity(
      id: id,
      category: category ?? this.category,
      distanceKm: distanceKm,
      distanceLabel: distanceLabel,
      title: title,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      locationName: locationName,
      meetingPoint: meetingPoint,
      description: description,
      hostId: hostId,
      hostName: hostName,
      hostFullName: hostFullName,
      hostSubtitle: hostSubtitle,
      hostScore: hostScore,
      hostAvatarUrl: hostAvatarUrl,
      participants: participants,
      availableSpots: availableSpots,
      spotsLabel: spotsLabel,
      isJoined: isJoined,
      isOwnedByCurrentUser: isOwnedByCurrentUser,
    );
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
    locationName,
    meetingPoint,
    description,
    hostId,
    hostName,
    hostFullName,
    hostSubtitle,
    hostScore,
    hostAvatarUrl,
    participants,
    availableSpots,
    spotsLabel,
    isJoined,
    isOwnedByCurrentUser,
  ];
}
