import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_feed.dart';
import '../entities/home_feed_filters.dart';
import '../entities/home_location.dart';
import '../repositories/home_repository.dart';

class GetHomeFeed implements UseCase<HomeFeed, GetHomeFeedParams> {
  const GetHomeFeed(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeFeed>> call(GetHomeFeedParams params) {
    return _repository.getHomeFeed(
      location: params.location,
      filters: params.filters,
    );
  }
}

class GetHomeFeedParams extends Equatable {
  const GetHomeFeedParams({required this.location, required this.filters});

  final HomeLocation location;
  final HomeFeedFilters filters;

  @override
  List<Object?> get props => [location, filters];
}
