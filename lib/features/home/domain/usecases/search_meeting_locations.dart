import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_location.dart';
import '../entities/meeting_location_suggestion.dart';
import '../repositories/home_repository.dart';

class SearchMeetingLocations
    implements
        UseCase<List<MeetingLocationSuggestion>, SearchMeetingLocationsParams> {
  const SearchMeetingLocations(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<MeetingLocationSuggestion>>> call(
    SearchMeetingLocationsParams params,
  ) {
    return _repository.searchMeetingLocations(
      query: params.query,
      nearLocation: params.nearLocation,
    );
  }
}

class SearchMeetingLocationsParams extends Equatable {
  const SearchMeetingLocationsParams({
    required this.query,
    required this.nearLocation,
  });

  final String query;
  final HomeLocation nearLocation;

  @override
  List<Object?> get props => [query, nearLocation];
}
