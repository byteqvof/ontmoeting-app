import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity_agenda.dart';
import '../repositories/home_repository.dart';

class GetActivityAgenda implements UseCase<ActivityAgenda, NoParams> {
  const GetActivityAgenda(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, ActivityAgenda>> call(NoParams params) {
    return _repository.getActivityAgenda();
  }
}
