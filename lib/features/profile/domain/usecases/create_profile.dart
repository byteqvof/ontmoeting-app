import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/create_profile_draft.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class CreateProfile implements UseCase<Profile, CreateProfileDraft> {
  const CreateProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Profile>> call(CreateProfileDraft params) {
    return _repository.createProfile(params);
  }
}
