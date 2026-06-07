import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_location.dart';
import '../repositories/home_repository.dart';

class GetCurrentLocation
    implements UseCase<HomeLocation, GetCurrentLocationParams> {
  const GetCurrentLocation(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeLocation>> call(GetCurrentLocationParams params) {
    return _repository.getCurrentLocation(forceRefresh: params.forceRefresh);
  }
}

class GetCurrentLocationParams extends Equatable {
  const GetCurrentLocationParams({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}
