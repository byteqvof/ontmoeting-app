import 'dart:math';

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
      clientMessageId: params.clientMessageId,
    );
  }
}

class SendActivityChatMessageParams extends Equatable {
  const SendActivityChatMessageParams({
    required this.activityId,
    required this.body,
    required this.clientMessageId,
  });

  final String activityId;
  final String body;
  final String clientMessageId;

  @override
  List<Object?> get props => [activityId, body, clientMessageId];
}

String createActivityChatClientMessageId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
}
