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

void main() {
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
  Future<Either<Failure, HomeLocation>> getCurrentLocation() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
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
