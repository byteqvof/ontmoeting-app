import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_location.dart';
import '../repositories/home_repository.dart';

class WatchCurrentLocation implements StreamUseCase<HomeLocation, NoParams> {
  const WatchCurrentLocation(this._repository);

  final HomeRepository _repository;

  @override
  Stream<Either<Failure, HomeLocation>> call(NoParams params) {
    return _repository.watchCurrentLocation();
  }
}
