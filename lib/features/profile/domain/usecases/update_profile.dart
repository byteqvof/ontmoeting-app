import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../entities/update_profile_draft.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile implements UseCase<Profile, UpdateProfileDraft> {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Profile>> call(UpdateProfileDraft params) {
    return _repository.updateProfile(params);
  }
}
