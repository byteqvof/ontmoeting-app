import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/account_trust_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/activity_agenda.dart';
import '../../domain/entities/activity_chat_message.dart';
import '../../domain/entities/activity_completion_update.dart';
import '../../domain/entities/activity_feedback.dart';
import '../../domain/entities/activity_participation_update.dart';
import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_location_data_source.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(
    this._dataSource,
    this._locationDataSource, {
    this.accountTrustService,
    this.locationLookupTimeout = const Duration(seconds: 6),
    this.feedCacheTtl = const Duration(seconds: 20),
  });

  final HomeRemoteDataSource _dataSource;
  final HomeLocationDataSource _locationDataSource;
  final AccountTrustService? accountTrustService;
  final Duration locationLookupTimeout;
  final Duration feedCacheTtl;

  HomeLocation? _cachedLocation;
  HomeFeed? _cachedFeed;
  HomeLocation? _cachedFeedLocation;
  HomeFeedFilters? _cachedFeedFilters;
  DateTime? _cachedFeedFetchedAt;

  @override
  Future<Either<Failure, String>> createActivity(
    CreateActivityDraft draft,
  ) async {
    try {
      final activityId = await _dataSource.createActivity(draft);
      _clearFeedCache();
      return right(activityId);
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, HomeActivity>> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) async {
    try {
      final activity = await _dataSource.updateActivity(
        activityId: activityId,
        draft: draft,
      );
      _clearFeedCache();
      return right(activity);
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedFeed = _freshCachedFeed(location: location, filters: filters);
      if (cachedFeed != null) {
        return right(cachedFeed);
      }
    }

    try {
      final feed = await _dataSource.getHomeFeed(
        location: location,
        filters: filters,
      );
      _cacheFeed(feed, location: location, filters: filters);
      return right(feed);
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, HomeActivity>> getActivityById(
    String activityId,
  ) async {
    try {
      return right(await _dataSource.getActivityById(activityId));
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
      if (join) {
        await _syncAccountTrustBeforeJoin();
      }
      final update = await _dataSource.setActivityParticipation(
        activityId: activityId,
        join: join,
      );
      _clearFeedCache();
      return right(update);
    } catch (error) {
      return left(_mapParticipationError(error, join: join));
    }
  }

  Future<void> _syncAccountTrustBeforeJoin() async {
    final service = accountTrustService;
    if (service == null) {
      return;
    }

    try {
      await service.syncTrust();
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Account trust pre-join sync failed',
        error: error,
        stackTrace: stackTrace,
      );
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
    DateTime? afterCreatedAt,
    String? afterId,
  }) async {
    try {
      return right(
        await _dataSource.getActivityChatMessages(
          activityId: activityId,
          afterCreatedAt: afterCreatedAt,
          afterId: afterId,
        ),
      );
    } catch (error) {
      return left(_mapChatError(error));
    }
  }

  @override
  Future<Either<Failure, ActivityChatMessage>> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  }) async {
    try {
      return right(
        await _dataSource.sendActivityChatMessage(
          activityId: activityId,
          body: body,
          clientMessageId: clientMessageId,
        ),
      );
    } catch (error) {
      return left(_mapChatError(error));
    }
  }

  @override
  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) async {
    try {
      await _dataSource.markActivityChatRead(
        activityId: activityId,
        messageId: messageId,
      );
      _clearFeedCache();
      return right(null);
    } catch (error) {
      return left(_mapChatError(error));
    }
  }

  @override
  Future<Either<Failure, ActivityCompletionUpdate>> completeActivity({
    required String activityId,
  }) async {
    try {
      final update = await _dataSource.completeActivity(activityId: activityId);
      _clearFeedCache();
      return right(update);
    } catch (error) {
      return left(_mapCompletionError(error));
    }
  }

  @override
  Future<Either<Failure, ActivityFeedback>> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) async {
    try {
      return right(
        await _dataSource.submitActivityFeedback(
          activityId: activityId,
          targetProfileId: targetProfileId,
          rating: rating,
          comment: comment,
        ),
      );
    } catch (error) {
      return left(_mapRemoteError(error));
    }
  }

  @override
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    final cachedLocation = _cachedLocation;
    if (!forceRefresh && cachedLocation != null) {
      return right(cachedLocation);
    }

    try {
      final location = await _locationDataSource
          .getCurrentLocation(forceRefresh: forceRefresh)
          .timeout(locationLookupTimeout);
      _cachedLocation = location;
      return right(location);
    } catch (error) {
      if (_shouldUseFallbackLocation(error)) {
        return right(defaultHomeLocation);
      }
      return left(_mapLocationError(error));
    }
  }

  @override
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() async* {
    final cachedLocation = _cachedLocation;
    if (cachedLocation != null) {
      yield right(cachedLocation);
    }

    try {
      await for (final location in _locationDataSource.watchCurrentLocation()) {
        if (_cachedLocation == location) {
          continue;
        }
        _cachedLocation = location;
        yield right(location);
      }
    } catch (error) {
      if (_shouldUseFallbackLocation(error)) {
        yield right(defaultHomeLocation);
        return;
      }
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
    if (_looksLikeTransientNetworkError(error)) {
      return const NetworkFailure('De verbinding hapert. Probeer het opnieuw.');
    }
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
      if (message.contains('chat')) {
        return const PermissionFailure(
          'Meld je eerst aan om de chat te openen.',
        );
      }
      if (message.contains('own')) {
        return const PermissionFailure(
          'Je kunt je niet aanmelden voor je eigen activiteit.',
        );
      }
      return const PermissionFailure('Je hebt geen toegang tot deze actie.');
    }
    if (error is FunctionException && error.status == 404) {
      return const ServerFailure(
        'Deze activiteit bestaat niet meer. Vernieuw het overzicht.',
      );
    }
    if (error is FunctionException && error.status == 409) {
      final message = _functionErrorMessage(error).toLowerCase();
      if (message.contains('started')) {
        return const ServerFailure(
          'Je kunt deze activiteit pas afronden nadat die begonnen is.',
        );
      }
      if (message.contains('feedback')) {
        return const ServerFailure('Feedback opslaan lukt nu niet.');
      }
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

  Failure _mapParticipationError(Object error, {required bool join}) {
    if (!join && error is FunctionException && error.status == 403) {
      return const ServerFailure(
        'Afmelden voor deze activiteit lukt nu niet. Probeer het opnieuw.',
      );
    }

    if (join && error is FunctionException) {
      final message = _functionErrorMessage(error).toLowerCase();
      if (error.status == 403) {
        if (message.contains('phone')) {
          return const PermissionFailure(
            'Bevestig eerst je telefoonnummer om mee te doen.',
          );
        }
        if (message.contains('own')) {
          return const PermissionFailure(
            'Je kunt je niet aanmelden voor je eigen activiteit.',
          );
        }
        if (message.contains('blocked')) {
          return const PermissionFailure(
            'Je kunt je niet aanmelden voor deze activiteit.',
          );
        }
        if (message.contains('closed')) {
          return const PermissionFailure('Deze groep is gesloten.');
        }
        if (message.contains('identity')) {
          return const PermissionFailure(
            'Deze activiteit vraagt identiteitsbevestiging.',
          );
        }
        if (message.contains('reputation')) {
          return const PermissionFailure(
            'Je reputatieniveau is te laag voor deze activiteit.',
          );
        }
        if (message.contains('specific audience') ||
            message.contains('target')) {
          return const PermissionFailure(
            'Deze activiteit is voor een specifieke doelgroep.',
          );
        }
        return const PermissionFailure(
          'Aanmelden voor deze activiteit lukt niet.',
        );
      }

      if (error.status == 409) {
        if (message.contains('full')) {
          return const ServerFailure('Deze activiteit zit vol.');
        }
        if (message.contains('unavailable')) {
          return const ServerFailure(
            'Deze activiteit is niet meer beschikbaar.',
          );
        }
        if (message.contains('profile')) {
          return const ServerFailure('Maak je profiel af om mee te doen.');
        }
        return const ServerFailure(
          'Aanmelden voor deze activiteit lukt nu niet. Vernieuw het overzicht en probeer opnieuw.',
        );
      }
    }

    return _mapRemoteError(error);
  }

  Failure _mapCompletionError(Object error) {
    if (error is FunctionException) {
      final message = _functionErrorMessage(error).toLowerCase();
      if (error.status == 403) {
        if (message.contains('organizer') ||
            message.contains('completion_forbidden')) {
          return const PermissionFailure(
            'Alleen de organisator kan deze activiteit afronden.',
          );
        }
        return const PermissionFailure('Je kunt deze activiteit niet afronden.');
      }
      if (error.status == 404) {
        return const ServerFailure(
          'Deze activiteit bestaat niet meer. Vernieuw het overzicht.',
        );
      }
      if (error.status == 409) {
        if (message.contains('started') ||
            message.contains('not_started')) {
          return const ServerFailure(
            'Je kunt deze activiteit pas afronden nadat die begonnen is.',
          );
        }
        return const ServerFailure(
          'Afronden lukt nu niet. Vernieuw de activiteit en probeer opnieuw.',
        );
      }
      if (error.status >= 500) {
        return const ServerFailure(
          'De activiteitenservice is tijdelijk niet beschikbaar.',
        );
      }
    }

    return _mapRemoteError(error);
  }

  Failure _mapChatError(Object error) {
    if (error is FunctionException && error.status == 403) {
      return const PermissionFailure('Meld je eerst aan om de chat te openen.');
    }

    if (error is FunctionException && error.status == 409) {
      final message = _functionErrorMessage(error).toLowerCase();
      if (message.contains('closed')) {
        return const ServerFailure(
          'Deze activiteit is voorbij. De chat is gesloten.',
        );
      }
    }

    if (error is FunctionException && error.status >= 500) {
      return const ServerFailure(
        'De chatservice is tijdelijk niet beschikbaar.',
      );
    }

    return _mapRemoteError(error);
  }

  HomeFeed? _freshCachedFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
  }) {
    final feed = _cachedFeed;
    final fetchedAt = _cachedFeedFetchedAt;
    if (feed == null ||
        fetchedAt == null ||
        _cachedFeedLocation != location ||
        _cachedFeedFilters != filters) {
      return null;
    }

    if (DateTime.now().difference(fetchedAt) > feedCacheTtl) {
      _clearFeedCache();
      return null;
    }

    return feed;
  }

  void _cacheFeed(
    HomeFeed feed, {
    required HomeLocation location,
    required HomeFeedFilters filters,
  }) {
    _cachedFeed = feed;
    _cachedFeedLocation = location;
    _cachedFeedFilters = filters;
    _cachedFeedFetchedAt = DateTime.now();
  }

  void _clearFeedCache() {
    _cachedFeed = null;
    _cachedFeedLocation = null;
    _cachedFeedFilters = null;
    _cachedFeedFetchedAt = null;
  }
}

bool _shouldUseFallbackLocation(Object error) {
  if (error is TimeoutException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('future not completed') ||
      message.contains('location timed out') ||
      message.contains('unable to get current location') ||
      message.contains('no location fix');
}

bool _looksLikeTransientNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('clientexception') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('timed out') ||
      message.contains('timeout');
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
