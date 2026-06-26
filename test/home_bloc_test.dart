import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/features/home/domain/entities/activity_agenda.dart';
import 'package:meetings_app/features/home/domain/entities/activity_chat_message.dart';
import 'package:meetings_app/features/home/domain/entities/activity_completion_update.dart';
import 'package:meetings_app/features/home/domain/entities/activity_feedback.dart';
import 'package:meetings_app/features/home/domain/entities/activity_participation_update.dart';
import 'package:meetings_app/features/home/domain/entities/create_activity_draft.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/domain/entities/home_feed.dart';
import 'package:meetings_app/features/home/domain/entities/home_feed_filters.dart';
import 'package:meetings_app/features/home/domain/entities/home_location.dart';
import 'package:meetings_app/features/home/domain/entities/meeting_location_suggestion.dart';
import 'package:meetings_app/features/home/domain/repositories/home_repository.dart';
import 'package:meetings_app/features/home/domain/usecases/get_current_location.dart';
import 'package:meetings_app/features/home/domain/usecases/get_home_feed.dart';
import 'package:meetings_app/features/home/domain/usecases/set_activity_participation.dart';
import 'package:meetings_app/features/home/domain/usecases/watch_current_location.dart';
import 'package:meetings_app/features/home/presentation/bloc/home_bloc.dart';

void main() {
  test('loads startup location without forcing a fresh GPS fix', () async {
    final repository = _HomeRepositoryStub();
    final bloc = HomeBloc(
      GetHomeFeed(repository),
      GetCurrentLocation(repository),
      SetActivityParticipation(repository),
      WatchCurrentLocation(repository),
    );

    bloc.add(const HomeStarted());

    await expectLater(bloc.stream, emitsThrough(isA<HomeLoaded>()));
    expect(repository.lastForceRefresh, isFalse);
    await bloc.close();
  });

  test(
    'ignores small watcher location changes without reloading feed',
    () async {
      final repository = _HomeRepositoryStub();
      final bloc = HomeBloc(
        GetHomeFeed(repository),
        GetCurrentLocation(repository),
        SetActivityParticipation(repository),
        WatchCurrentLocation(repository),
      );

      bloc.add(const HomeStarted());
      await expectLater(bloc.stream, emitsThrough(isA<HomeLoaded>()));

      repository.emitWatchedLocation(
        const HomeLocation(
          cityName: 'Winschoten',
          latitude: 53.1442,
          longitude: 7.0342,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.feedLoadCount, 1);
      await bloc.close();
    },
  );

  test(
    'large watcher location changes reload feed without hard loading state',
    () async {
      final repository = _HomeRepositoryStub();
      final bloc = HomeBloc(
        GetHomeFeed(repository),
        GetCurrentLocation(repository),
        SetActivityParticipation(repository),
        WatchCurrentLocation(repository),
      );

      bloc.add(const HomeStarted());
      await expectLater(bloc.stream, emitsThrough(isA<HomeLoaded>()));

      final states = <HomeState>[];
      final subscription = bloc.stream.listen(states.add);
      repository.emitWatchedLocation(
        const HomeLocation(
          cityName: 'Groningen',
          latitude: 53.219,
          longitude: 6.566,
        ),
      );
      await expectLater(bloc.stream, emitsThrough(isA<HomeLoaded>()));

      expect(repository.feedLoadCount, 2);
      expect(states.whereType<HomeLoadingFeed>(), isEmpty);
      await subscription.cancel();
      await bloc.close();
    },
  );
}

class _HomeRepositoryStub implements HomeRepository {
  final _locationController =
      StreamController<Either<Failure, HomeLocation>>.broadcast();
  bool? lastForceRefresh;
  int feedLoadCount = 0;

  void emitWatchedLocation(HomeLocation location) {
    _locationController.add(right(location));
  }

  @override
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    lastForceRefresh = forceRefresh;
    return right(_location);
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
  }) async {
    feedLoadCount += 1;
    return right(
      HomeFeed(
        locationName: location.cityName,
        selectedTimeFilter: filters.selectedTimeFilter,
        selectedDistanceKm: filters.distanceKm,
        timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
        distanceFilters: const [5, 10, 25, 50],
        categories: const [_category],
        activities: const [],
      ),
    );
  }

  @override
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() {
    return _locationController.stream;
  }

  @override
  Future<Either<Failure, String>> createActivity(CreateActivityDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeActivity>> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityCompletionUpdate>> completeActivity({
    required String activityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityAgenda>> getActivityAgenda() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ActivityChatMessage>>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeActivity>> getActivityById(String activityId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityChatMessage>> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({required String activityId, required bool join}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityFeedback>> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MeetingLocationSuggestion>>>
  searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) {
    throw UnimplementedError();
  }
}

const _location = HomeLocation(
  cityName: 'Winschoten',
  latitude: 53.144,
  longitude: 7.034,
);

const _category = HomeCategory(
  id: 'category-1',
  label: 'Buiten',
  icon: Icons.park_rounded,
  color: Color(0xFF1E5740),
  backgroundColor: Color(0xFFE6EFE9),
);
