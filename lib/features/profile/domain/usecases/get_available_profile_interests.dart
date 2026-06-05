import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile_interest.dart';
import '../repositories/profile_repository.dart';

class GetAvailableProfileInterests
    implements UseCase<List<ProfileInterest>, NoParams> {
  const GetAvailableProfileInterests(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, List<ProfileInterest>>> call(NoParams params) {
    return _repository.getAvailableInterests();
  }
}
