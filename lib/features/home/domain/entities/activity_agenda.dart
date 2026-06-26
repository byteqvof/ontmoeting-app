import 'package:equatable/equatable.dart';

import 'home_activity.dart';

class ActivityAgenda extends Equatable {
  const ActivityAgenda({
    required this.hostedActivities,
    required this.joinedActivities,
    this.completedActivities = const [],
  });

  final List<HomeActivity> hostedActivities;
  final List<HomeActivity> joinedActivities;
  final List<HomeActivity> completedActivities;

  int get totalCount =>
      activeHostedActivities.length +
      activeJoinedActivities.length +
      uniqueCompletedActivities.length;

  List<HomeActivity> get activeHostedActivities {
    final completedIds = _completedActivityIds;
    return _uniqueActivities(
      hostedActivities.where(
        (activity) =>
            !activity.isCompleted && !completedIds.contains(activity.id),
      ),
    );
  }

  List<HomeActivity> get activeJoinedActivities {
    final completedIds = _completedActivityIds;
    final hostedIds = activeHostedActivities
        .map((activity) => activity.id)
        .toSet();
    return _uniqueActivities(
      joinedActivities.where(
        (activity) =>
            activity.isJoined &&
            !activity.isCompleted &&
            !completedIds.contains(activity.id) &&
            !hostedIds.contains(activity.id),
      ),
    );
  }

  List<HomeActivity> get uniqueCompletedActivities {
    final completedById = <String, HomeActivity>{};
    for (final activity in [
      ...completedActivities,
      ...hostedActivities.where((activity) => activity.isCompleted),
      ...joinedActivities.where((activity) => activity.isCompleted),
    ]) {
      final current = completedById[activity.id];
      if (current == null ||
          _activityContextScore(activity) > _activityContextScore(current)) {
        completedById[activity.id] = activity;
      }
    }
    return completedById.values.toList();
  }

  List<HomeActivity> get chatActivities {
    final activitiesById = <String, HomeActivity>{};
    for (final activity in [
      ...activeHostedActivities,
      ...activeJoinedActivities,
      ..._inactiveChatHistoryActivities,
      ...uniqueCompletedActivities,
    ]) {
      activitiesById.putIfAbsent(activity.id, () => activity);
    }
    final activities = activitiesById.values.toList();
    if (!activities.any(
      (activity) =>
          activity.chatUnreadCount > 0 || activity.chatLastMessageAt != null,
    )) {
      return activities;
    }
    return activities..sort((left, right) {
      final unreadCompare = right.chatUnreadCount.compareTo(
        left.chatUnreadCount,
      );
      if (unreadCompare != 0) {
        return unreadCompare;
      }
      final leftTime = left.chatLastMessageAt;
      final rightTime = right.chatLastMessageAt;
      if (leftTime != null && rightTime != null) {
        return rightTime.compareTo(leftTime);
      }
      if (leftTime == null && rightTime != null) {
        return 1;
      }
      if (leftTime != null && rightTime == null) {
        return -1;
      }
      return 0;
    });
  }

  ActivityAgenda withChatMarkedRead(String activityId) {
    List<HomeActivity> clearUnread(List<HomeActivity> activities) {
      return activities
          .map(
            (activity) => activity.id == activityId
                ? activity.copyWith(chatUnreadCount: 0)
                : activity,
          )
          .toList();
    }

    return ActivityAgenda(
      hostedActivities: clearUnread(hostedActivities),
      joinedActivities: clearUnread(joinedActivities),
      completedActivities: clearUnread(completedActivities),
    );
  }

  ActivityAgenda withActivityUpdated(HomeActivity updatedActivity) {
    List<HomeActivity> updateActivities(List<HomeActivity> activities) {
      return activities
          .map(
            (activity) =>
                activity.id == updatedActivity.id ? updatedActivity : activity,
          )
          .toList();
    }

    return ActivityAgenda(
      hostedActivities: updateActivities(hostedActivities),
      joinedActivities: updateActivities(joinedActivities),
      completedActivities: updateActivities(completedActivities),
    );
  }

  @override
  List<Object?> get props => [
    hostedActivities,
    joinedActivities,
    completedActivities,
  ];

  List<HomeActivity> get _inactiveChatHistoryActivities {
    final completedIds = _completedActivityIds;
    final hostedIds = activeHostedActivities
        .map((activity) => activity.id)
        .toSet();
    return _uniqueActivities(
      joinedActivities.where(
        (activity) =>
            !activity.isJoined &&
            !activity.isCompleted &&
            !completedIds.contains(activity.id) &&
            !hostedIds.contains(activity.id) &&
            activity.chatLastMessageAt != null,
      ),
    );
  }

  Set<String> get _completedActivityIds =>
      uniqueCompletedActivities.map((activity) => activity.id).toSet();
}

List<HomeActivity> _uniqueActivities(Iterable<HomeActivity> activities) {
  final activitiesById = <String, HomeActivity>{};
  for (final activity in activities) {
    activitiesById.putIfAbsent(activity.id, () => activity);
  }
  return activitiesById.values.toList();
}

int _activityContextScore(HomeActivity activity) {
  var score = 0;
  if (activity.isOwnedByCurrentUser) {
    score += 8;
  }
  if (activity.isJoined) {
    score += 6;
  }
  if (activity.canSendChat) {
    score += 3;
  }
  if (activity.hostFeedbackSubmitted) {
    score += 2;
  }
  score += activity.participants.length * 4;
  score += activity.participants.where((participant) {
    return participant.attendanceStatus != null ||
        participant.feedbackSubmitted;
  }).length;
  return score;
}
