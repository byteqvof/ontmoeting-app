import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class IsProfileOnboardingRequired implements UseCase<bool, NoParams> {
  const IsProfileOnboardingRequired(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.isProfileOnboardingRequired();
  }
}
