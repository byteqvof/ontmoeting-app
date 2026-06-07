import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/home_repository.dart';

class MarkActivityChatRead
    implements UseCase<void, MarkActivityChatReadParams> {
  const MarkActivityChatRead(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, void>> call(MarkActivityChatReadParams params) {
    return _repository.markActivityChatRead(
      activityId: params.activityId,
      messageId: params.messageId,
    );
  }
}

class MarkActivityChatReadParams extends Equatable {
  const MarkActivityChatReadParams({required this.activityId, this.messageId});

  final String activityId;
  final String? messageId;

  @override
  List<Object?> get props => [activityId, messageId];
}
