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
    return _repository.getActivityChatMessages(activityId: params.activityId);
  }
}

class GetActivityChatMessagesParams extends Equatable {
  const GetActivityChatMessagesParams({required this.activityId});

  final String activityId;

  @override
  List<Object?> get props => [activityId];
}
