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
      hostedActivities.length +
      joinedActivities.length +
      completedActivities.length;

  List<HomeActivity> get chatActivities {
    final activitiesById = <String, HomeActivity>{};
    for (final activity in [
      ...hostedActivities,
      ...joinedActivities,
      ...completedActivities,
    ]) {
      activitiesById.putIfAbsent(activity.id, () => activity);
    }
    return activitiesById.values.toList();
  }

  @override
  List<Object?> get props => [
    hostedActivities,
    joinedActivities,
    completedActivities,
  ];
}
