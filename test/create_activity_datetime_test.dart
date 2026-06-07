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
import 'package:meetings_app/features/home/domain/repositories/home_repository.dart';
import 'package:meetings_app/features/home/domain/usecases/create_activity.dart';
import 'package:meetings_app/features/home/presentation/bloc/create_activity_bloc.dart';

const _testLocation = HomeLocation(
  cityName: 'Ter Apel',
  latitude: 52.876,
  longitude: 7.059,
);

void main() {
  test('submits the custom selected date and time', () async {
    final repository = _CapturingHomeRepository();
    final bloc = CreateActivityBloc(
      CreateActivity(repository),
      location: _testLocation,
      categories: const [_category],
      geocodeMeetingPlace: _fakeGeocodeMeetingPlace,
    );

    bloc
      ..add(const CreateActivityTitleChanged('rondje wandelen'))
      ..add(const CreateActivityLocationChanged('Centrum Ter Apel'))
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
        location: _testLocation,
        categories: const [_category],
        geocodeMeetingPlace: (query, fallbackLocation) async {
          expect(query, 'Marktplein 1, Winschoten');
          expect(fallbackLocation.cityName, 'Ter Apel');
          return const ResolvedMeetingLocation(
            addressLine: 'Marktplein 1',
            city: 'Winschoten',
            latitude: 53.144,
            longitude: 7.034,
          );
        },
      );

      bloc
        ..add(const CreateActivityTitleChanged('rondje wandelen'))
        ..add(const CreateActivityLocationChanged('Marktplein 1, Winschoten'))
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

      expect(repository.createdDraft?.addressLine, 'Marktplein 1');
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
        location: _testLocation,
        categories: const [_category],
        geocodeMeetingPlace: _fakeGeocodeMeetingPlace,
      );

      bloc
        ..add(const CreateActivityTitleChanged('Avond'))
        ..add(const CreateActivityLocationChanged('Centrum Ter Apel'))
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
}

Future<ResolvedMeetingLocation> _fakeGeocodeMeetingPlace(
  String query,
  HomeLocation fallbackLocation,
) async {
  return ResolvedMeetingLocation(
    addressLine: query,
    city: fallbackLocation.cityName,
    latitude: fallbackLocation.latitude,
    longitude: fallbackLocation.longitude,
  );
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
