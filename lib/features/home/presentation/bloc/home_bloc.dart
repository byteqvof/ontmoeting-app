import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_home_feed.dart';
import '../../domain/usecases/set_activity_participation.dart';
import '../../domain/usecases/watch_current_location.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._getHomeFeed,
    this._getCurrentLocation,
    this._setActivityParticipation,
    this._watchLocation,
  ) : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeLocationRequested>(_onLocationRequested);
    on<HomeLocationChanged>(_onLocationChanged);
    on<HomeLocationFailureReceived>(_onLocationFailureReceived);
    on<HomeDistanceSelected>(_onDistanceSelected);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomeTimeFilterSelected>(_onTimeFilterSelected);
    on<HomeCategorySelected>(_onCategorySelected);
    on<HomeFiltersApplied>(_onFiltersApplied);
    on<HomeActivityParticipationToggled>(_onActivityParticipationToggled);
    on<HomeActivityUpdated>(_onActivityUpdated);
    on<HomeParticipationConfirmationConsumed>(
      _onParticipationConfirmationConsumed,
    );
  }

  static const _defaultFilters = HomeFeedFilters();

  final GetHomeFeed _getHomeFeed;
  final GetCurrentLocation _getCurrentLocation;
  final SetActivityParticipation _setActivityParticipation;
  final WatchCurrentLocation _watchLocation;

  StreamSubscription? _locationSubscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    add(const HomeLocationRequested());
  }

  Future<void> _onLocationRequested(
    HomeLocationRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeResolvingLocation());
    final result = await _getCurrentLocation(const NoParams());
    await result.fold(
      (failure) async => emit(HomeLocationBlocked(failure.message)),
      (location) async {
        await _loadFeed(emit, location: location, filters: _defaultFilters);
        await _startLocationWatcher(restart: true);
      },
    );
  }

  Future<void> _onLocationChanged(
    HomeLocationChanged event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }

    if (current.location == event.location) {
      return;
    }

    AppLogger.debug('HomeBloc location changed to ${event.location.cityName}');
    await _loadFeed(emit, location: event.location, filters: current.filters);
  }

  void _onLocationFailureReceived(
    HomeLocationFailureReceived event,
    Emitter<HomeState> emit,
  ) {
    AppLogger.debug('HomeBloc location watch failed: ${event.failure.message}');
    emit(HomeLocationBlocked(event.failure.message));
  }

  Future<void> _onDistanceSelected(
    HomeDistanceSelected event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }
    await _loadFeed(
      emit,
      location: current.location,
      filters: current.filters.copyWith(distanceKm: event.distanceKm),
    );
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded || current.isRefreshing) {
      return;
    }

    emit(current.copyWith(isRefreshing: true));
    final result = await _getHomeFeed(
      GetHomeFeedParams(location: current.location, filters: current.filters),
    );

    result.fold(
      (failure) {
        AppLogger.debug('HomeBloc refresh failed: ${failure.message}');
        AnalyticsService.instance.track(
          'feed_load_failed',
          properties: {'source': 'refresh'},
        );
        emit(current.copyWith(isRefreshing: false));
      },
      (feed) {
        AnalyticsService.instance.track(
          'feed_loaded',
          properties: {
            'source': 'refresh',
            'activity_count': feed.activities.length,
            'distance_km': current.filters.distanceKm,
          },
        );
        emit(current.copyWith(feed: feed, isRefreshing: false));
      },
    );
  }

  Future<void> _onTimeFilterSelected(
    HomeTimeFilterSelected event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }
    await _loadFeed(
      emit,
      location: current.location,
      filters: _filtersForTimeLabel(current.filters, event.filter),
    );
  }

  Future<void> _onCategorySelected(
    HomeCategorySelected event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }
    await _loadFeed(
      emit,
      location: current.location,
      filters: current.filters.copyWith(
        categoryIds: event.categoryId == 'all' ? const [] : [event.categoryId],
      ),
    );
  }

  Future<void> _onFiltersApplied(
    HomeFiltersApplied event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }
    await _loadFeed(
      emit,
      location: current.location,
      filters: event.filters,
      analyticsSource: 'filters',
    );
    AnalyticsService.instance.track(
      'filter_applied',
      properties: _filterAnalyticsProperties(event.filters),
    );
  }

  Future<void> _onActivityParticipationToggled(
    HomeActivityParticipationToggled event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded ||
        current.isParticipationPending(event.activityId)) {
      return;
    }

    final activity = _activityById(current.feed.activities, event.activityId);
    if (activity == null || activity.isOwnedByCurrentUser) {
      return;
    }

    if (!activity.isJoined && activity.availableSpots <= 0) {
      emit(current.copyWith(participationError: 'Deze activiteit zit vol.'));
      return;
    }

    emit(
      current.copyWith(
        pendingActivityIds: [...current.pendingActivityIds, activity.id],
        participationError: null,
      ),
    );

    final result = await _setActivityParticipation(
      SetActivityParticipationParams(
        activityId: activity.id,
        join: !activity.isJoined,
      ),
    );

    final latest = state;
    if (latest is! HomeLoaded) {
      return;
    }

    final pendingActivityIds = latest.pendingActivityIds
        .where((activityId) => activityId != activity.id)
        .toList();

    result.fold(
      (failure) {
        AppLogger.debug(
          'HomeBloc participation update failed: ${failure.message}',
        );
        AnalyticsService.instance.track(
          'join_failed',
          properties: {'joining': !activity.isJoined},
        );
        emit(
          latest.copyWith(
            pendingActivityIds: pendingActivityIds,
            participationError: failure.message,
          ),
        );
      },
      (update) {
        final activities = latest.feed.activities
            .map((activity) => activity.applyParticipationUpdate(update))
            .toList();
        final joinedActivity = !activity.isJoined && update.isJoined
            ? _activityById(activities, activity.id)
            : null;
        AnalyticsService.instance.track(
          update.isJoined ? 'join_success' : 'leave_success',
          properties: {
            'participant_count': update.participantsCount,
            'available_spots': update.availableSpots,
          },
        );
        emit(
          latest.copyWith(
            feed: latest.feed.copyWith(activities: activities),
            pendingActivityIds: pendingActivityIds,
            participationError: null,
            joinedActivityConfirmation: joinedActivity,
          ),
        );
      },
    );
  }

  void _onActivityUpdated(HomeActivityUpdated event, Emitter<HomeState> emit) {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }

    final activities = current.feed.activities
        .map(
          (activity) =>
              activity.id == event.activity.id ? event.activity : activity,
        )
        .toList();
    emit(current.copyWith(feed: current.feed.copyWith(activities: activities)));
  }

  void _onParticipationConfirmationConsumed(
    HomeParticipationConfirmationConsumed event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(joinedActivityConfirmation: null));
    }
  }

  Future<void> _loadFeed(
    Emitter<HomeState> emit, {
    required HomeLocation location,
    required HomeFeedFilters filters,
    String analyticsSource = 'initial',
  }) async {
    emit(HomeLoadingFeed(location: location, distanceKm: filters.distanceKm));
    final result = await _getHomeFeed(
      GetHomeFeedParams(location: location, filters: filters),
    );
    result.fold(
      (failure) {
        AnalyticsService.instance.track(
          'feed_load_failed',
          properties: {'source': analyticsSource},
        );
        emit(HomeError(failure.message));
      },
      (feed) {
        AnalyticsService.instance.track(
          'feed_loaded',
          properties: {
            'source': analyticsSource,
            'activity_count': feed.activities.length,
            'distance_km': filters.distanceKm,
            'has_advanced_filters': filters.hasAdvancedFilters,
          },
        );
        emit(HomeLoaded(feed: feed, location: location, filters: filters));
      },
    );
  }

  Future<void> _startLocationWatcher({bool restart = false}) async {
    if (_locationSubscription != null && !restart) {
      return;
    }

    await _locationSubscription?.cancel();
    AppLogger.debug('HomeBloc starting location watcher');
    _locationSubscription = _watchLocation(const NoParams()).listen((result) {
      result.fold(
        (failure) => add(HomeLocationFailureReceived(failure)),
        (location) => add(HomeLocationChanged(location)),
      );
    });
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}

HomeActivity? _activityById(List<HomeActivity> activities, String activityId) {
  for (final activity in activities) {
    if (activity.id == activityId) {
      return activity;
    }
  }

  return null;
}

HomeFeedFilters _filtersForTimeLabel(HomeFeedFilters current, String label) {
  final today = _startOfDay(DateTime.now());

  if (label == 'Vandaag') {
    return current.copyWith(
      dateFilter: homeDateFilterToday,
      dateFrom: today,
      dateTo: today.add(const Duration(days: 1)),
    );
  }

  if (label == 'Dit weekend') {
    final daysUntilSaturday =
        (DateTime.saturday - today.weekday) % DateTime.daysPerWeek;
    final saturday = today.add(Duration(days: daysUntilSaturday));
    return current.copyWith(
      dateFilter: homeDateFilterWeekend,
      dateFrom: saturday,
      dateTo: saturday.add(const Duration(days: 2)),
    );
  }

  return current.copyWith(dateFilter: homeDateFilterAll, clearDateRange: true);
}

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

Map<String, Object> _filterAnalyticsProperties(HomeFeedFilters filters) {
  return {
    'distance_km': filters.distanceKm,
    'date_filter': filters.dateFilter,
    'category_count': filters.categoryIds.length,
    'age_band_count': filters.targetAgeBands.length,
    'gender_count': filters.targetGenders.length,
    'requires_identity_verified': filters.requiresIdentityVerified,
    'available_only': filters.availableOnly,
    'has_min_participants': filters.minParticipants != null,
    'has_max_participants': filters.maxParticipants != null,
    'sort': filters.sort,
  };
}
