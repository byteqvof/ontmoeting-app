import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile_activity.dart';
import '../repositories/profile_repository.dart';

class GetProfileActivities
    implements UseCase<List<ProfileActivity>, GetProfileActivitiesParams> {
  const GetProfileActivities(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, List<ProfileActivity>>> call(
    GetProfileActivitiesParams params,
  ) {
    return _repository.getActivitiesForUser(profileId: params.profileId);
  }
}

class GetProfileActivitiesParams extends Equatable {
  const GetProfileActivitiesParams({this.profileId});

  final String? profileId;

  @override
  List<Object?> get props => [profileId];
}
