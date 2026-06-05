import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/create_activity_draft.dart';
import '../repositories/home_repository.dart';

class CreateActivity implements UseCase<String, CreateActivityDraft> {
  const CreateActivity(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, String>> call(CreateActivityDraft params) {
    return _repository.createActivity(params);
  }
}
