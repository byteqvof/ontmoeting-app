import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/create_activity_draft.dart';
import '../entities/home_activity.dart';
import '../repositories/home_repository.dart';

class UpdateActivity implements UseCase<HomeActivity, UpdateActivityParams> {
  const UpdateActivity(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeActivity>> call(UpdateActivityParams params) {
    return _repository.updateActivity(
      activityId: params.activityId,
      draft: params.draft,
    );
  }
}

class UpdateActivityParams extends Equatable {
  const UpdateActivityParams({required this.activityId, required this.draft});

  final String activityId;
  final CreateActivityDraft draft;

  @override
  List<Object?> get props => [activityId, draft];
}
