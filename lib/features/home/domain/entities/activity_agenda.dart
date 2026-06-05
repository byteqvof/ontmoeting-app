import 'package:equatable/equatable.dart';

import 'home_activity.dart';

class ActivityAgenda extends Equatable {
  const ActivityAgenda({
    required this.hostedActivities,
    required this.joinedActivities,
  });

  final List<HomeActivity> hostedActivities;
  final List<HomeActivity> joinedActivities;

  int get totalCount => hostedActivities.length + joinedActivities.length;

  List<HomeActivity> get chatActivities {
    final activitiesById = <String, HomeActivity>{};
    for (final activity in [...hostedActivities, ...joinedActivities]) {
      activitiesById.putIfAbsent(activity.id, () => activity);
    }
    return activitiesById.values.toList();
  }

  @override
  List<Object?> get props => [hostedActivities, joinedActivities];
}
