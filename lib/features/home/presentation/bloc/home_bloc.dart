import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_home_feed.dart';
import '../../domain/usecases/watch_current_location.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getHomeFeed, this._getCurrentLocation, this._watchLocation)
    : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeLocationRequested>(_onLocationRequested);
    on<HomeLocationChanged>(_onLocationChanged);
    on<HomeLocationFailureReceived>(_onLocationFailureReceived);
    on<HomeDistanceSelected>(_onDistanceSelected);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomeTimeFilterSelected>(_onTimeFilterSelected);
    on<HomeCategorySelected>(_onCategorySelected);
  }

  static const _defaultDistanceKm = 10;

  final GetHomeFeed _getHomeFeed;
  final GetCurrentLocation _getCurrentLocation;
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
        await _loadFeed(
          emit,
          location: location,
          distanceKm: _defaultDistanceKm,
        );
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
    await _loadFeed(
      emit,
      location: event.location,
      distanceKm: current.selectedDistanceKm,
      selectedTimeFilter: current.selectedTimeFilter,
      selectedCategoryId: current.selectedCategoryId,
    );
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
      distanceKm: event.distanceKm,
      selectedTimeFilter: current.selectedTimeFilter,
      selectedCategoryId: current.selectedCategoryId,
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
      GetHomeFeedParams(
        location: current.location,
        distanceKm: current.selectedDistanceKm,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.debug('HomeBloc refresh failed: ${failure.message}');
        emit(current.copyWith(isRefreshing: false));
      },
      (feed) => emit(
        current.copyWith(
          feed: feed,
          isRefreshing: false,
          selectedTimeFilter: current.selectedTimeFilter,
          selectedCategoryId: current.selectedCategoryId,
        ),
      ),
    );
  }

  void _onTimeFilterSelected(
    HomeTimeFilterSelected event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }
    emit(current.copyWith(selectedTimeFilter: event.filter));
  }

  void _onCategorySelected(
    HomeCategorySelected event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is! HomeLoaded) {
      return;
    }
    emit(current.copyWith(selectedCategoryId: event.categoryId));
  }

  Future<void> _loadFeed(
    Emitter<HomeState> emit, {
    required HomeLocation location,
    required int distanceKm,
    String? selectedTimeFilter,
    String? selectedCategoryId,
  }) async {
    emit(HomeLoadingFeed(location: location, distanceKm: distanceKm));
    final result = await _getHomeFeed(
      GetHomeFeedParams(location: location, distanceKm: distanceKm),
    );
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (feed) => emit(
        HomeLoaded(
          feed: feed,
          location: location,
          selectedDistanceKm: distanceKm,
          selectedTimeFilter: selectedTimeFilter ?? feed.selectedTimeFilter,
          selectedCategoryId: selectedCategoryId ?? feed.categories.first.id,
        ),
      ),
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
