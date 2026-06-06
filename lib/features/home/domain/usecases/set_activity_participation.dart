import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity_participation_update.dart';
import '../repositories/home_repository.dart';

class SetActivityParticipation
    implements
        UseCase<ActivityParticipationUpdate, SetActivityParticipationParams> {
  const SetActivityParticipation(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, ActivityParticipationUpdate>> call(
    SetActivityParticipationParams params,
  ) {
    return _repository.setActivityParticipation(
      activityId: params.activityId,
      join: params.join,
    );
  }
}

class SetActivityParticipationParams extends Equatable {
  const SetActivityParticipationParams({
    required this.activityId,
    required this.join,
  });

  final String activityId;
  final bool join;

  @override
  List<Object?> get props => [activityId, join];
}
