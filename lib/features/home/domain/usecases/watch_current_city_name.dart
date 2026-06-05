import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/home_repository.dart';

class WatchCurrentCityName implements StreamUseCase<String, NoParams> {
  const WatchCurrentCityName(this._repository);

  final HomeRepository _repository;

  @override
  Stream<Either<Failure, String>> call(NoParams params) {
    return _repository.watchCurrentLocation().map(
      (result) => result.map((location) => location.cityName),
    );
  }
}
