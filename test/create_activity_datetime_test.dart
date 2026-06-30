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
import 'package:meetings_app/features/home/domain/usecases/create_activity.dart';
import 'package:meetings_app/features/home/domain/usecases/search_meeting_locations.dart';
import 'package:meetings_app/features/home/presentation/bloc/create_activity_bloc.dart';
import 'package:meetings_app/features/home/presentation/pages/create_activity_page.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders the redesigned compact create activity screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _CapturingHomeRepository();
    sl
      ..registerLazySingleton(() => CreateActivity(repository))
      ..registerLazySingleton(() => SearchMeetingLocations(repository));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const CreateActivityPage(
          location: _terApelLocation,
          categories: [_category],
        ),
      ),
    );

    expect(find.text('Nieuwe activiteit'), findsOneWidget);
    expect(find.text('Wat ga je\ndoen?'), findsOneWidget);
    expect(find.text('Kies een categorie om te beginnen'), findsOneWidget);
    expect(find.text('Titel'), findsOneWidget);
    expect(find.text('Waar'), findsOneWidget);
    expect(find.text('Wanneer'), findsOneWidget);
    expect(find.text('Hoeveel mensen'), findsOneWidget);
    expect(find.text('Deelname-instellingen'), findsOneWidget);
    expect(find.text('Geverifieerd profiel nodig'), findsOneWidget);
    expect(find.text('Goedkeuren wie aansluit'), findsOneWidget);
    expect(find.text('Locatie privé'), findsOneWidget);
    expect(find.text('Plaats activiteit'), findsOneWidget);
    expect(find.textContaining('Ik ga'), findsNothing);
    expect(find.text('KIES CATEGORIE'), findsNothing);
  });

  test('submits the custom selected date and time', () async {
    final repository = _CapturingHomeRepository();
    final bloc = CreateActivityBloc(
      CreateActivity(repository),
      SearchMeetingLocations(repository),
      location: _terApelLocation,
      categories: const [_category],
    );

    bloc
      ..add(const CreateActivityTitleChanged('rondje wandelen'))
      ..add(const CreateActivityLocationChanged('Centrum Ter Apel'))
      ..add(const CreateActivityMeetingLocationSelected(_terApelSuggestion))
      ..add(CreateActivityDateSelected(DateTime(2099, 7, 10)))
      ..add(const CreateActivityTimeSelected(hour: 14, minute: 35))
      ..add(const CreateActivitySubmitted());

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<CreateActivityState>(
          (state) =>
              state.submissionStatus == CreateActivitySubmissionStatus.success,
        ),
      ),
    );

    expect(repository.createdDraft, isNotNull);
    expect(repository.createdDraft!.startsAt, DateTime(2099, 7, 10, 14, 35));
    await bloc.close();
  });

  test(
    'uses selected meeting place instead of current home location',
    () async {
      final repository = _CapturingHomeRepository();
      final bloc = CreateActivityBloc(
        CreateActivity(repository),
        SearchMeetingLocations(repository),
        location: _terApelLocation,
        categories: const [_category],
        searchMeetingPlaces: (_, _) async => const [],
      );

      bloc
        ..add(const CreateActivityTitleChanged('rondje wandelen'))
        ..add(const CreateActivityLocationChanged('Marktplein 1, Winschoten'))
        ..add(
          const CreateActivityMeetingLocationSelected(_winschotenSuggestion),
        )
        ..add(CreateActivityDateSelected(DateTime(2099, 7, 10)))
        ..add(const CreateActivityTimeSelected(hour: 14, minute: 35))
        ..add(const CreateActivitySubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CreateActivityState>(
            (state) =>
                state.submissionStatus ==
                CreateActivitySubmissionStatus.success,
          ),
        ),
      );

      expect(repository.createdDraft?.addressLine, 'Marktplein 1, Winschoten');
      expect(repository.createdDraft?.city, 'Winschoten');
      expect(repository.createdDraft?.latitude, 53.144);
      expect(repository.createdDraft?.longitude, 7.034);
      await bloc.close();
    },
  );

  test(
    'uses generated description when optional notes are too short',
    () async {
      final repository = _CapturingHomeRepository();
      final bloc = CreateActivityBloc(
        CreateActivity(repository),
        SearchMeetingLocations(repository),
        location: _terApelLocation,
        categories: const [_category],
      );

      bloc
        ..add(const CreateActivityTitleChanged('Avond'))
        ..add(const CreateActivityLocationChanged('Centrum Ter Apel'))
        ..add(const CreateActivityMeetingLocationSelected(_terApelSuggestion))
        ..add(CreateActivityDateSelected(DateTime(2099, 7, 10)))
        ..add(const CreateActivityTimeSelected(hour: 14, minute: 35))
        ..add(const CreateActivityNotesChanged('ok'))
        ..add(const CreateActivitySubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CreateActivityState>(
            (state) =>
                state.submissionStatus ==
                CreateActivitySubmissionStatus.success,
          ),
        ),
      );

      expect(repository.createdDraft?.description, contains('Ik ga Avond'));
      expect(
        repository.createdDraft!.description.length,
        greaterThanOrEqualTo(10),
      );
      await bloc.close();
    },
  );

  test('does not show hardcoded meeting place suggestions before search', () {
    final state = CreateActivityState(cityName: 'Ter Apel');

    expect(state.locationSuggestions, isEmpty);
  });

  test('searches meeting places and submits the selected result', () async {
    final repository = _CapturingHomeRepository();
    final bloc = CreateActivityBloc(
      CreateActivity(repository),
      SearchMeetingLocations(repository),
      location: _terApelLocation,
      categories: const [_category],
      searchMeetingPlaces: (query, fallbackLocation) async {
        expect(query, 'bibliotheek');
        expect(fallbackLocation.cityName, 'Ter Apel');
        return const [_librarySuggestion];
      },
    );

    bloc
      ..add(const CreateActivityTitleChanged('rondje wandelen'))
      ..add(const CreateActivityLocationChanged('bibliotheek'))
      ..add(const CreateActivityMeetingLocationSearchRequested('bibliotheek'));

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<CreateActivityState>(
          (state) =>
              state.locationSearchStatus ==
                  CreateActivityLocationSearchStatus.success &&
              state.locationResults.length == 1,
        ),
      ),
    );

    bloc
      ..add(const CreateActivityMeetingLocationSelected(_librarySuggestion))
      ..add(CreateActivityDateSelected(DateTime(2099, 7, 10)))
      ..add(const CreateActivityTimeSelected(hour: 14, minute: 35))
      ..add(const CreateActivitySubmitted());

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<CreateActivityState>(
          (state) =>
              state.submissionStatus == CreateActivitySubmissionStatus.success,
        ),
      ),
    );

    expect(
      repository.createdDraft?.addressLine,
      'Bibliotheek Ter Apel, Hoofdstraat 66',
    );
    expect(repository.createdDraft?.latitude, 52.8762);
    expect(repository.createdDraft?.longitude, 7.0594);
    await bloc.close();
  });

  test('searches meeting places through the usecase', () async {
    final repository = _CapturingHomeRepository()
      ..locationSearchResults = const [_librarySuggestion];
    final bloc = CreateActivityBloc(
      CreateActivity(repository),
      SearchMeetingLocations(repository),
      location: _terApelLocation,
      categories: const [_category],
    );

    bloc
      ..add(const CreateActivityLocationChanged('bibliotheek'))
      ..add(const CreateActivityMeetingLocationSearchRequested('bibliotheek'));

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<CreateActivityState>(
          (state) =>
              state.locationSearchStatus ==
                  CreateActivityLocationSearchStatus.success &&
              state.locationResults.single == _librarySuggestion,
        ),
      ),
    );

    expect(repository.lastLocationSearchQuery, 'bibliotheek');
    expect(repository.lastLocationSearchNearLocation, _terApelLocation);
    await bloc.close();
  });

  test(
    'fails submit when typed location was not selected from suggestions',
    () async {
      final repository = _CapturingHomeRepository();
      final bloc = CreateActivityBloc(
        CreateActivity(repository),
        SearchMeetingLocations(repository),
        location: _terApelLocation,
        categories: const [_category],
      );

      bloc
        ..add(const CreateActivityTitleChanged('rondje wandelen'))
        ..add(const CreateActivityLocationChanged('Bibliotheek Ter Apel'))
        ..add(CreateActivityDateSelected(DateTime(2099, 7, 10)))
        ..add(const CreateActivityTimeSelected(hour: 14, minute: 35))
        ..add(const CreateActivitySubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CreateActivityState>(
            (state) =>
                state.submissionStatus ==
                    CreateActivitySubmissionStatus.failure &&
                state.errorMessage ==
                    'Kies een gevonden meetingplek uit de lijst voordat je plaatst.',
          ),
        ),
      );

      expect(repository.createdDraft, isNull);
      await bloc.close();
    },
  );
}

const _category = HomeCategory(
  id: '11111111-1111-1111-1111-111111111111',
  label: 'Buiten',
  icon: Icons.grid_view_rounded,
  color: Color(0xFF1E5740),
  backgroundColor: Color(0xFFE6EFE9),
);

const _terApelLocation = HomeLocation(
  cityName: 'Ter Apel',
  latitude: 52.876,
  longitude: 7.059,
);

const _terApelSuggestion = MeetingLocationSuggestion(
  id: 'pdok-ter-apel',
  label: 'Centrum Ter Apel',
  addressLine: 'Centrum Ter Apel',
  city: 'Ter Apel',
  type: 'woonplaats',
  latitude: 52.876,
  longitude: 7.059,
);

const _winschotenSuggestion = MeetingLocationSuggestion(
  id: 'pdok-winschoten',
  label: 'Marktplein 1, Winschoten',
  addressLine: 'Marktplein 1, Winschoten',
  city: 'Winschoten',
  type: 'adres',
  latitude: 53.144,
  longitude: 7.034,
);

const _librarySuggestion = MeetingLocationSuggestion(
  id: 'pdok-library-ter-apel',
  label: 'Bibliotheek Ter Apel, Hoofdstraat 66',
  addressLine: 'Bibliotheek Ter Apel, Hoofdstraat 66',
  city: 'Ter Apel',
  type: 'adres',
  latitude: 52.8762,
  longitude: 7.0594,
);

class _CapturingHomeRepository implements HomeRepository {
  CreateActivityDraft? createdDraft;
  List<MeetingLocationSuggestion> locationSearchResults = const [];
  String? lastLocationSearchQuery;
  HomeLocation? lastLocationSearchNearLocation;

  @override
  Future<Either<Failure, String>> createActivity(CreateActivityDraft draft) {
    createdDraft = draft;
    return Future.value(right('activity-1'));
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
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
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
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MeetingLocationSuggestion>>>
  searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) async {
    lastLocationSearchQuery = query;
    lastLocationSearchNearLocation = nearLocation;
    return right(locationSearchResults);
  }
}
