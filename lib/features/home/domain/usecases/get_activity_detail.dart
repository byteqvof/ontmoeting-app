import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_activity.dart';
import '../repositories/home_repository.dart';

class GetActivityDetail
    implements UseCase<HomeActivity, GetActivityDetailParams> {
  const GetActivityDetail(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeActivity>> call(GetActivityDetailParams params) {
    return _repository.getActivityById(params.activityId);
  }
}

class GetActivityDetailParams extends Equatable {
  const GetActivityDetailParams(this.activityId);

  final String activityId;

  @override
  List<Object?> get props => [activityId];
}
