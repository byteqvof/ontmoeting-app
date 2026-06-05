import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/activity_agenda.dart';
import '../entities/activity_chat_message.dart';
import '../entities/activity_participation_update.dart';
import '../entities/create_activity_draft.dart';
import '../entities/home_feed.dart';
import '../entities/home_location.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, String>> createActivity(CreateActivityDraft draft);

  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  });

  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({required String activityId, required bool join});

  Future<Either<Failure, ActivityAgenda>> getActivityAgenda();

  Future<Either<Failure, List<ActivityChatMessage>>> getActivityChatMessages({
    required String activityId,
  });

  Future<Either<Failure, ActivityChatMessage>> sendActivityChatMessage({
    required String activityId,
    required String body,
  });

  Future<Either<Failure, HomeLocation>> getCurrentLocation();

  Stream<Either<Failure, HomeLocation>> watchCurrentLocation();
}
