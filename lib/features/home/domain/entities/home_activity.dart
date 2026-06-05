import 'package:equatable/equatable.dart';

import 'home_category.dart';

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
    required this.hostName,
    required this.hostFullName,
    required this.hostSubtitle,
    required this.hostScore,
    required this.participantInitials,
    required this.participantNames,
    required this.availableSpots,
    required this.spotsLabel,
    this.isJoined = false,
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
  final String hostName;
  final String hostFullName;
  final String hostSubtitle;
  final int hostScore;
  final List<String> participantInitials;
  final List<String> participantNames;
  final int availableSpots;
  final String spotsLabel;
  final bool isJoined;

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
    hostName,
    hostFullName,
    hostSubtitle,
    hostScore,
    participantInitials,
    participantNames,
    availableSpots,
    spotsLabel,
    isJoined,
  ];
}
