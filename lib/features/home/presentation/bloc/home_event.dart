part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeLocationRequested extends HomeEvent {
  const HomeLocationRequested();
}

final class HomeLocationChanged extends HomeEvent {
  const HomeLocationChanged(this.location);

  final HomeLocation location;

  @override
  List<Object?> get props => [location];
}

final class HomeLocationFailureReceived extends HomeEvent {
  const HomeLocationFailureReceived(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class HomeDistanceSelected extends HomeEvent {
  const HomeDistanceSelected(this.distanceKm);

  final int distanceKm;

  @override
  List<Object?> get props => [distanceKm];
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

final class HomeTimeFilterSelected extends HomeEvent {
  const HomeTimeFilterSelected(this.filter);

  final String filter;

  @override
  List<Object?> get props => [filter];
}

final class HomeCategorySelected extends HomeEvent {
  const HomeCategorySelected(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class HomeActivityParticipationToggled extends HomeEvent {
  const HomeActivityParticipationToggled(this.activityId);

  final String activityId;

  @override
  List<Object?> get props => [activityId];
}

final class HomeActivityUpdated extends HomeEvent {
  const HomeActivityUpdated(this.activity);

  final HomeActivity activity;

  @override
  List<Object?> get props => [activity];
}
