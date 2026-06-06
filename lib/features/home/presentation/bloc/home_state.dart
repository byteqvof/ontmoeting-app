part of 'home_bloc.dart';

const _unsetParticipationError = Object();

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
    required this.selectedDistanceKm,
    required this.selectedTimeFilter,
    required this.selectedCategoryId,
    this.isRefreshing = false,
    this.pendingActivityIds = const [],
    this.participationError,
  });

  final HomeFeed feed;
  final HomeLocation location;
  final int selectedDistanceKm;
  final String selectedTimeFilter;
  final String selectedCategoryId;
  final bool isRefreshing;
  final List<String> pendingActivityIds;
  final String? participationError;

  bool isParticipationPending(String activityId) {
    return pendingActivityIds.contains(activityId);
  }

  List<HomeActivity> get visibleActivities {
    final categoryFiltered = selectedCategoryId == 'all'
        ? feed.activities
        : feed.activities
              .where((activity) => activity.category.id == selectedCategoryId)
              .toList();

    if (selectedTimeFilter == 'Alles') {
      return categoryFiltered;
    }

    if (selectedTimeFilter == 'Vandaag') {
      return categoryFiltered
          .where((activity) => activity.dateLabel == 'donderdag 5 jun')
          .toList();
    }

    return categoryFiltered
        .where(
          (activity) =>
              activity.dateLabel == 'vrijdag 6 jun' ||
              activity.dateLabel == 'zaterdag 7 jun' ||
              activity.dateLabel == 'zondag 8 jun',
        )
        .toList();
  }

  HomeLoaded copyWith({
    HomeFeed? feed,
    HomeLocation? location,
    int? selectedDistanceKm,
    String? selectedTimeFilter,
    String? selectedCategoryId,
    bool? isRefreshing,
    List<String>? pendingActivityIds,
    Object? participationError = _unsetParticipationError,
  }) {
    return HomeLoaded(
      feed: feed ?? this.feed,
      location: location ?? this.location,
      selectedDistanceKm: selectedDistanceKm ?? this.selectedDistanceKm,
      selectedTimeFilter: selectedTimeFilter ?? this.selectedTimeFilter,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pendingActivityIds: pendingActivityIds ?? this.pendingActivityIds,
      participationError:
          identical(participationError, _unsetParticipationError)
          ? this.participationError
          : participationError as String?,
    );
  }

  @override
  List<Object?> get props => [
    feed,
    location,
    selectedDistanceKm,
    selectedTimeFilter,
    selectedCategoryId,
    isRefreshing,
    pendingActivityIds,
    participationError,
  ];
}
