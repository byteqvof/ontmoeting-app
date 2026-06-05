import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity_chat_message.dart';
import '../repositories/home_repository.dart';

class SendActivityChatMessage
    implements UseCase<ActivityChatMessage, SendActivityChatMessageParams> {
  const SendActivityChatMessage(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, ActivityChatMessage>> call(
    SendActivityChatMessageParams params,
  ) {
    return _repository.sendActivityChatMessage(
      activityId: params.activityId,
      body: params.body,
    );
  }
}

class SendActivityChatMessageParams extends Equatable {
  const SendActivityChatMessageParams({
    required this.activityId,
    required this.body,
  });

  final String activityId;
  final String body;

  @override
  List<Object?> get props => [activityId, body];
}
