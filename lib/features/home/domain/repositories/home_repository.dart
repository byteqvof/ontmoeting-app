import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/home_feed.dart';
import '../entities/home_location.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  });

  Future<Either<Failure, HomeLocation>> getCurrentLocation();

  Stream<Either<Failure, HomeLocation>> watchCurrentLocation();
}
