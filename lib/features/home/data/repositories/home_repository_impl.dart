import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/activity_agenda.dart';
import '../../domain/entities/activity_chat_message.dart';
import '../../domain/entities/activity_participation_update.dart';
import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_location_data_source.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dataSource, this._locationDataSource);

  final HomeRemoteDataSource _dataSource;
  final HomeLocationDataSource _locationDataSource;

  @override
  Future<Either<Failure, String>> createActivity(
    CreateActivityDraft draft,
  ) async {
    try {
      return right(await _dataSource.createActivity(draft));
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

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
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({
    required String activityId,
    required bool join,
  }) async {
    try {
      return right(
        await _dataSource.setActivityParticipation(
          activityId: activityId,
          join: join,
        ),
      );
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, ActivityAgenda>> getActivityAgenda() async {
    try {
      return right(await _dataSource.getActivityAgenda());
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, List<ActivityChatMessage>>> getActivityChatMessages({
    required String activityId,
  }) async {
    try {
      return right(
        await _dataSource.getActivityChatMessages(activityId: activityId),
      );
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, ActivityChatMessage>> sendActivityChatMessage({
    required String activityId,
    required String body,
  }) async {
    try {
      return right(
        await _dataSource.sendActivityChatMessage(
          activityId: activityId,
          body: body,
        ),
      );
    } catch (error) {
      return left(_mapRemoteError(error));
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

  Failure _mapRemoteError(Object error) {
    if (error is AuthException) {
      return AuthFailure(error.message);
    }
    if (error is FunctionException && error.status == 401) {
      return const AuthFailure(
        'Je sessie is verlopen. Log opnieuw in om door te gaan.',
      );
    }
    if (error is FunctionException && error.status == 400) {
      final message = _functionErrorMessage(error);
      if (message.toLowerCase().contains('message')) {
        return const ServerFailure(
          'Schrijf een bericht tussen 1 en 800 tekens.',
        );
      }
    }
    if (error is FunctionException && error.status == 403) {
      final message = _functionErrorMessage(error).toLowerCase();
      if (message.contains('chat') || message.contains('join')) {
        return const PermissionFailure(
          'Meld je eerst aan om de chat te openen.',
        );
      }
      return const PermissionFailure(
        'Je kunt je niet aanmelden voor je eigen activiteit.',
      );
    }
    if (error is FunctionException && error.status == 404) {
      return const ServerFailure(
        'Deze activiteit bestaat niet meer. Vernieuw het overzicht.',
      );
    }
    if (error is FunctionException && error.status == 409) {
      return ServerFailure(
        error.reasonPhrase ?? 'Aanmelden voor deze activiteit lukt niet.',
      );
    }
    if (error is FunctionException && error.status >= 500) {
      return const ServerFailure(
        'De activiteitenservice is tijdelijk niet beschikbaar.',
      );
    }
    return UnknownFailure(error.toString());
  }
}

String _functionErrorMessage(FunctionException error) {
  final details = error.details;
  if (details is Map) {
    final nestedError = details['error'];
    if (nestedError is Map && nestedError['message'] != null) {
      return nestedError['message'].toString();
    }
    if (details['message'] != null) {
      return details['message'].toString();
    }
  }
  return error.reasonPhrase ?? error.toString();
}
