import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/core/di/injection_container.dart';
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
import 'package:meetings_app/features/home/presentation/pages/activity_search_page.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('submitting a search shows loading feedback and real results', (
    tester,
  ) async {
    final repository = _FakeHomeRepository();
    _registerSearchDependencies(repository);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ActivitySearchPage()),
    );

    await tester.enterText(find.byType(TextField), 'avond');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(find.text('Zoeken naar "avond"...'), findsOneWidget);

    repository.completeFeed(_feed([_fishingActivity(), _coffeeActivity()]));
    await tester.pumpAndSettle();

    expect(find.text('Avondvissen aan de Maas'), findsOneWidget);
    expect(find.text('Koffie centrum'), findsNothing);
    expect(find.text('1 resultaat'), findsOneWidget);
  });

  testWidgets('recent and category buttons execute searches', (tester) async {
    final repository = _FakeHomeRepository();
    _registerSearchDependencies(repository);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ActivitySearchPage()),
    );

    await tester.tap(find.text('Avondvissen'));
    await tester.pump();
    expect(find.text('Zoeken naar "Avondvissen"...'), findsOneWidget);

    repository.completeFeed(_feed([_fishingActivity(), _coffeeActivity()]));
    await tester.pumpAndSettle();
    expect(find.text('Avondvissen aan de Maas'), findsOneWidget);

    repository.prepareNextFeed();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    await tester.tap(find.text('Koffie'));
    await tester.pump();
    expect(find.text('Zoeken naar "Koffie"...'), findsOneWidget);

    repository.completeFeed(_feed([_fishingActivity(), _coffeeActivity()]));
    await tester.pumpAndSettle();
    expect(find.text('Koffie centrum'), findsOneWidget);
    expect(find.text('Avondvissen aan de Maas'), findsNothing);
  });
}

void _registerSearchDependencies(_FakeHomeRepository repository) {
  sl
    ..registerLazySingleton(() => GetCurrentLocation(repository))
    ..registerLazySingleton(() => GetHomeFeed(repository));
}

HomeFeed _feed(List<HomeActivity> activities) {
  return HomeFeed(
    locationName: 'Ter Apel',
    selectedTimeFilter: 'Alles',
    selectedDistanceKm: 50,
    timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
    distanceFilters: const [5, 10, 25, 50],
    categories: const [_fishingCategory, _coffeeCategory],
    activities: activities,
  );
}

HomeActivity _fishingActivity() {
  return HomeActivity(
    id: 'activity-fishing',
    category: _fishingCategory,
    distanceKm: 1.4,
    distanceLabel: '1,4 km',
    title: 'Avondvissen aan de Maas',
    dateLabel: 'vrijdag 26 jun',
    timeLabel: '19:00',
    locationName: 'Maastricht',
    meetingPoint: 'St. Pietersplas',
    description: 'Rustig vissen aan het water.',
    hostId: 'host-1',
    hostName: 'Joren',
    hostFullName: 'Joren',
    hostSubtitle: 'Ter Apel',
    hostScore: 55,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
  );
}

HomeActivity _coffeeActivity() {
  return HomeActivity(
    id: 'activity-coffee',
    category: _coffeeCategory,
    distanceKm: 0.8,
    distanceLabel: '0,8 km',
    title: 'Koffie centrum',
    dateLabel: 'vandaag',
    timeLabel: '11:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Bibliotheek',
    description: 'Koffie drinken in het centrum.',
    hostId: 'host-2',
    hostName: 'Jasper',
    hostFullName: 'Jasper',
    hostSubtitle: 'Ter Apel',
    hostScore: 42,
    participants: const [],
    availableSpots: 3,
    spotsLabel: 'nog 3 plekken',
  );
}

const _fishingCategory = HomeCategory(
  id: 'fishing',
  label: 'Vissen',
  icon: Icons.phishing_rounded,
  color: Color(0xFF1E5740),
  backgroundColor: Color(0xFFE6EFE9),
);

const _coffeeCategory = HomeCategory(
  id: 'coffee',
  label: 'Koffie',
  icon: Icons.local_cafe_rounded,
  color: Color(0xFF9A6238),
  backgroundColor: Color(0xFFF1E5DC),
);

class _FakeHomeRepository implements HomeRepository {
  Completer<Either<Failure, HomeFeed>> _feedCompleter = Completer();

  void prepareNextFeed() {
    _feedCompleter = Completer();
  }

  void completeFeed(HomeFeed feed) {
    _feedCompleter.complete(right(feed));
  }

  @override
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    return right(
      const HomeLocation(
        cityName: 'Ter Apel',
        latitude: 52.876,
        longitude: 7.059,
      ),
    );
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
  }) {
    return _feedCompleter.future;
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
  Future<Either<Failure, HomeActivity>> getActivityById(String activityId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({required String activityId, required bool join}) {
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
  Future<Either<Failure, ActivityCompletionUpdate>> completeActivity({
    required String activityId,
  }) {
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

  @override
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() {
    return const Stream.empty();
  }
}
