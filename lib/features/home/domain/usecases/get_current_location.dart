import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_location.dart';
import '../repositories/home_repository.dart';

class GetCurrentLocation implements UseCase<HomeLocation, NoParams> {
  const GetCurrentLocation(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeLocation>> call(NoParams params) {
    return _repository.getCurrentLocation();
  }
}
