import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity_completion_update.dart';
import '../repositories/home_repository.dart';

class CompleteActivity
    implements UseCase<ActivityCompletionUpdate, CompleteActivityParams> {
  const CompleteActivity(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, ActivityCompletionUpdate>> call(
    CompleteActivityParams params,
  ) {
    return _repository.completeActivity(activityId: params.activityId);
  }
}

class CompleteActivityParams extends Equatable {
  const CompleteActivityParams({required this.activityId});

  final String activityId;

  @override
  List<Object?> get props => [activityId];
}
