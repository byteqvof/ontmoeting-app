import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity_chat_message.dart';
import '../repositories/home_repository.dart';

class GetActivityChatMessages
    implements
        UseCase<List<ActivityChatMessage>, GetActivityChatMessagesParams> {
  const GetActivityChatMessages(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<ActivityChatMessage>>> call(
    GetActivityChatMessagesParams params,
  ) {
    return _repository.getActivityChatMessages(
      activityId: params.activityId,
      afterCreatedAt: params.afterCreatedAt,
      afterId: params.afterId,
    );
  }
}

class GetActivityChatMessagesParams extends Equatable {
  const GetActivityChatMessagesParams({
    required this.activityId,
    this.afterCreatedAt,
    this.afterId,
  });

  final String activityId;
  final DateTime? afterCreatedAt;
  final String? afterId;

  @override
  List<Object?> get props => [activityId, afterCreatedAt, afterId];
}
