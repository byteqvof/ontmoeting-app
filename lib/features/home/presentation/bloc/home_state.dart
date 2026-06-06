part of 'home_bloc.dart';

const _unsetParticipationError = Object();
const _unsetJoinedActivityConfirmation = Object();

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeResolvingLocation extends HomeState {
  const HomeResolvingLocation();
}

final class HomeLocationBlocked extends HomeState {
  const HomeLocationBlocked(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class HomeLoadingFeed extends HomeState {
  const HomeLoadingFeed({required this.location, required this.distanceKm});

  final HomeLocation location;
  final int distanceKm;

  @override
  List<Object?> get props => [location, distanceKm];
}

final class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.feed,
    required this.location,
    required this.filters,
    this.isRefreshing = false,
    this.pendingActivityIds = const [],
    this.participationError,
    this.joinedActivityConfirmation,
  });

  final HomeFeed feed;
  final HomeLocation location;
  final HomeFeedFilters filters;
  final bool isRefreshing;
  final List<String> pendingActivityIds;
  final String? participationError;
  final HomeActivity? joinedActivityConfirmation;

  int get selectedDistanceKm => filters.distanceKm;

  String get selectedTimeFilter => filters.selectedTimeFilter;

  String get selectedCategoryId => filters.selectedCategoryId;

  bool isParticipationPending(String activityId) {
    return pendingActivityIds.contains(activityId);
  }

  List<HomeActivity> get visibleActivities => feed.activities;

  HomeLoaded copyWith({
    HomeFeed? feed,
    HomeLocation? location,
    HomeFeedFilters? filters,
    bool? isRefreshing,
    List<String>? pendingActivityIds,
    Object? participationError = _unsetParticipationError,
    Object? joinedActivityConfirmation = _unsetJoinedActivityConfirmation,
  }) {
    return HomeLoaded(
      feed: feed ?? this.feed,
      location: location ?? this.location,
      filters: filters ?? this.filters,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pendingActivityIds: pendingActivityIds ?? this.pendingActivityIds,
      participationError:
          identical(participationError, _unsetParticipationError)
          ? this.participationError
          : participationError as String?,
      joinedActivityConfirmation:
          identical(
            joinedActivityConfirmation,
            _unsetJoinedActivityConfirmation,
          )
          ? this.joinedActivityConfirmation
          : joinedActivityConfirmation as HomeActivity?,
    );
  }

  @override
  List<Object?> get props => [
    feed,
    location,
    filters,
    isRefreshing,
    pendingActivityIds,
    participationError,
    joinedActivityConfirmation,
  ];
}
