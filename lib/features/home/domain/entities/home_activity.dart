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
    required this.hostName,
    required this.participantInitials,
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
  final String hostName;
  final List<String> participantInitials;
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
    hostName,
    participantInitials,
    spotsLabel,
    isJoined,
  ];
}
