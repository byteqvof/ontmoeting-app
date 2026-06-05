import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_dummy_data_source.dart';
import '../datasources/home_location_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dataSource, this._locationDataSource);

  final HomeDummyDataSource _dataSource;
  final HomeLocationDataSource _locationDataSource;

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  }) async {
    try {
      return right(
        await _dataSource.getHomeFeed(
          location: location,
          distanceKm: distanceKm,
        ),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, HomeLocation>> getCurrentLocation() async {
    try {
      return right(await _locationDataSource.getCurrentLocation());
    } catch (error) {
      return left(_mapLocationError(error));
    }
  }

  @override
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() async* {
    try {
      await for (final location in _locationDataSource.watchCurrentLocation()) {
        yield right(location);
      }
    } catch (error) {
      yield left(_mapLocationError(error));
    }
  }

  Failure _mapLocationError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission')) {
      return const PermissionFailure(
        'Locatietoegang is nodig om activiteiten in je plaats te tonen.',
      );
    }
    if (message.contains('disabled')) {
      return const PermissionFailure(
        'Zet locatievoorzieningen aan om je plaats automatisch te vinden.',
      );
    }
    return UnknownFailure(error.toString());
  }
}
