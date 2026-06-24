import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
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
import 'package:meetings_app/features/home/domain/repositories/home_repository.dart';
import 'package:meetings_app/features/home/domain/usecases/create_activity.dart';
import 'package:meetings_app/features/home/presentation/bloc/create_activity_bloc.dart';

void main() {
  test('meeting place label keeps typed house number when geocoder omits it', () {
    final label = formatMeetingPlaceAddressLine(
      query: '9561 AB Markeweg 23',
      city: 'Ter Apel',
      placemark: const Placemark(
        street: 'Markeweg',
        thoroughfare: 'Markeweg',
        locality: 'Ter Apel',
      ),
    );

    expect(label, contains('Markeweg 23'));
    expect(label, contains('Ter Apel'));
  });

  test('submits the custom selected date and time', () async {
    final repository = _CapturingHomeRepository();
    final bloc = CreateActivityBloc(
      CreateActivity(repository),
      location: defaultHomeLocation,
      categories: const [_category],
    );

    bloc
      ..add(const CreateActivityTitleChanged('rondje wandelen'))
      ..add(const CreateActivityLocationChanged('Centrum Ter Apel'))
      ..add(
        const CreateActivityMeetingLocationSelected(
          ResolvedMeetingLocation(
            addressLine: 'Centrum Ter Apel',
            city: 'Ter Apel',
            latitude: 52.876,
            longitude: 7.059,
          ),
        ),
      )
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
    'uses geocoded meeting place instead of current home location',
    () async {
      final repository = _CapturingHomeRepository();
      final bloc = CreateActivityBloc(
        CreateActivity(repository),
        location: defaultHomeLocation,
        categories: const [_category],
        searchMeetingPlaces: (_, _) async => const [],
      );

      bloc
        ..add(const CreateActivityTitleChanged('rondje wandelen'))
        ..add(const CreateActivityLocationChanged('Marktplein 1, Winschoten'))
        ..add(
          const CreateActivityMeetingLocationSelected(
            ResolvedMeetingLocation(
              addressLine: 'Marktplein 1, Winschoten',
              city: 'Winschoten',
              latitude: 53.144,
              longitude: 7.034,
            ),
          ),
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
      location: defaultHomeLocation,
      categories: const [_category],
    );

    bloc
      ..add(const CreateActivityTitleChanged('Avond'))
      ..add(const CreateActivityLocationChanged('Centrum Ter Apel'))
      ..add(
        const CreateActivityMeetingLocationSelected(
          ResolvedMeetingLocation(
            addressLine: 'Centrum Ter Apel',
            city: 'Ter Apel',
            latitude: 52.876,
            longitude: 7.059,
          ),
        ),
      )
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
      location: defaultHomeLocation,
      categories: const [_category],
      searchMeetingPlaces: (query, fallbackLocation) async {
        expect(query, 'bibliotheek');
        expect(fallbackLocation.cityName, 'Ter Apel');
        return const [
          ResolvedMeetingLocation(
            addressLine: 'Bibliotheek Ter Apel, Hoofdstraat 66',
            city: 'Ter Apel',
            latitude: 52.8762,
            longitude: 7.0594,
          ),
        ];
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
      ..add(
        const CreateActivityMeetingLocationSelected(
          ResolvedMeetingLocation(
            addressLine: 'Bibliotheek Ter Apel, Hoofdstraat 66',
            city: 'Ter Apel',
            latitude: 52.8762,
            longitude: 7.0594,
          ),
        ),
      )
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
}

const _category = HomeCategory(
  id: '11111111-1111-1111-1111-111111111111',
  label: 'Buiten',
  icon: Icons.grid_view_rounded,
  color: Color(0xFF1E5740),
  backgroundColor: Color(0xFFE6EFE9),
);

class _CapturingHomeRepository implements HomeRepository {
  CreateActivityDraft? createdDraft;

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
}
