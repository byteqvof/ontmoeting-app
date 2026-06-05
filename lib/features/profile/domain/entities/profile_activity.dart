import 'package:equatable/equatable.dart';

import 'profile_interest.dart';

class ProfileActivity extends Equatable {
  const ProfileActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateLabel,
    required this.timeLabel,
    required this.locationName,
    required this.meetingPoint,
    required this.status,
    required this.availableSpots,
    required this.spotsLabel,
  });

  final String id;
  final String title;
  final String description;
  final ProfileInterest category;
  final String dateLabel;
  final String timeLabel;
  final String locationName;
  final String meetingPoint;
  final String status;
  final int availableSpots;
  final String spotsLabel;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    dateLabel,
    timeLabel,
    locationName,
    meetingPoint,
    status,
    availableSpots,
    spotsLabel,
  ];
}
