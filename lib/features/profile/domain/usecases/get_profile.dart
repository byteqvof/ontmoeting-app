import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<Profile, GetProfileParams> {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Profile>> call(GetProfileParams params) {
    return _repository.getProfile(profileId: params.profileId);
  }
}

class GetProfileParams extends Equatable {
  const GetProfileParams({this.profileId});

  final String? profileId;

  @override
  List<Object?> get props => [profileId];
}
