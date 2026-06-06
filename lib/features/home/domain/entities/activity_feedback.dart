import 'package:equatable/equatable.dart';

class ActivityFeedback extends Equatable {
  const ActivityFeedback({
    required this.id,
    required this.activityId,
    required this.reviewerId,
    required this.targetProfileId,
    required this.targetName,
    required this.targetInitials,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.targetAvatarUrl,
  });

  final String id;
  final String activityId;
  final String reviewerId;
  final String targetProfileId;
  final String targetName;
  final String targetInitials;
  final String? targetAvatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    activityId,
    reviewerId,
    targetProfileId,
    targetName,
    targetInitials,
    targetAvatarUrl,
    rating,
    comment,
    createdAt,
  ];
}
