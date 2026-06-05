import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/home_repository.dart';

class GetCurrentCityName implements UseCase<String, NoParams> {
  const GetCurrentCityName(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return _repository.getCurrentLocation().then(
      (result) => result.map((location) => location.cityName),
    );
  }
}
