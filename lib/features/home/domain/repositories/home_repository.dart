import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/activity_agenda.dart';
import '../entities/activity_chat_message.dart';
import '../entities/activity_completion_update.dart';
import '../entities/activity_feedback.dart';
import '../entities/activity_participation_update.dart';
import '../entities/create_activity_draft.dart';
import '../entities/home_activity.dart';
import '../entities/home_feed.dart';
import '../entities/home_feed_filters.dart';
import '../entities/home_location.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, String>> createActivity(CreateActivityDraft draft);

  Future<Either<Failure, HomeActivity>> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  });

  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
  });

  Future<Either<Failure, HomeActivity>> getActivityById(String activityId);

  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({required String activityId, required bool join});

  Future<Either<Failure, ActivityAgenda>> getActivityAgenda();

  Future<Either<Failure, List<ActivityChatMessage>>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  });

  Future<Either<Failure, ActivityChatMessage>> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  });

  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
  });

  Future<Either<Failure, ActivityCompletionUpdate>> completeActivity({
    required String activityId,
  });

  Future<Either<Failure, ActivityFeedback>> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  });

  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  });

  Stream<Either<Failure, HomeLocation>> watchCurrentLocation();
}
