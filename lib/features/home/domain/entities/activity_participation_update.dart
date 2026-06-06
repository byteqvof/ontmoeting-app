import 'package:equatable/equatable.dart';

import 'home_participant.dart';

class ActivityParticipationUpdate extends Equatable {
  const ActivityParticipationUpdate({
    required this.activityId,
    required this.isJoined,
    required this.participants,
    required this.participantsCount,
    required this.availableSpots,
    this.participationStatus,
  });

  final String activityId;
  final bool isJoined;
  final List<HomeParticipant> participants;
  final int participantsCount;
  final int availableSpots;
  final String? participationStatus;

  String get spotsLabel {
    if (participationStatus == 'pending') {
      return 'wacht op akkoord';
    }
    if (isJoined) {
      return 'jij gaat ook';
    }
    return availableSpots == 1 ? 'nog 1 plek' : 'nog $availableSpots plekken';
  }

  @override
  List<Object?> get props => [
    activityId,
    isJoined,
    participants,
    participantsCount,
    availableSpots,
    participationStatus,
  ];
}
