import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/core/services/account_trust_service.dart';
import 'package:meetings_app/features/home/data/datasources/home_location_data_source.dart';
import 'package:meetings_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:meetings_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:meetings_app/features/home/domain/entities/activity_agenda.dart';
import 'package:meetings_app/features/home/domain/entities/activity_chat_message.dart';
import 'package:meetings_app/features/home/domain/entities/activity_completion_update.dart';
import 'package:meetings_app/features/home/domain/entities/activity_feedback.dart';
import 'package:meetings_app/features/home/domain/entities/activity_participation_update.dart';
import 'package:meetings_app/features/home/domain/entities/create_activity_draft.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_feed.dart';
import 'package:meetings_app/features/home/domain/entities/home_feed_filters.dart';
import 'package:meetings_app/features/home/domain/entities/home_location.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/domain/entities/meeting_location_suggestion.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_trust.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _sampleLocation = HomeLocation(
  cityName: 'Winschoten',
  latitude: 53.144,
  longitude: 7.034,
);

void main() {
  test('maps transient home connection reset to network failure', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        Exception(
          'ClientException: Connection reset by peer, '
          'uri=https://example.supabase.co/functions/v1/activities-nearby',
        ),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.getHomeFeed(
      location: _sampleLocation,
      filters: const HomeFeedFilters(),
    );

    result.fold((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'De verbinding hapert. Probeer het opnieuw.');
    }, (_) => fail('Expected a network failure.'));
  });

  test('returns a location failure when device location times out', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(Exception('unused')),
      _ThrowingLocationDataSource(
        TimeoutException('Future not completed', const Duration(seconds: 14)),
      ),
    );

    final result = await repository.getCurrentLocation();

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'We kunnen je locatie niet bepalen. Controleer de locatie van je toestel en probeer opnieuw.',
      );
    }, (_) => fail('Expected location failure.'));
  });

  test(
    'does not map disabled device location service as permission denied',
    () async {
      final repository = HomeRepositoryImpl(
        _ThrowingHomeRemoteDataSource(Exception('unused')),
        _ThrowingLocationDataSource(const LocationServiceDisabledException()),
      );

      final result = await repository.getCurrentLocation();

      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure, isNot(isA<PermissionFailure>()));
        expect(
          failure.message,
          'Zet locatievoorzieningen aan om je plaats automatisch te vinden.',
        );
      }, (_) => fail('Expected location failure.'));
    },
  );

  test('does not wait for a hanging device location lookup', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(Exception('unused')),
      const _HangingLocationDataSource(),
      locationLookupTimeout: const Duration(milliseconds: 10),
    );

    final result = await repository.getCurrentLocation();

    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('Expected location failure.'),
    );
  });

  test(
    'does not cache failed location lookups as the real device location',
    () async {
      final locationDataSource = _SequenceLocationDataSource([
        TimeoutException('Future not completed', const Duration(seconds: 14)),
        const HomeLocation(
          cityName: 'Winschoten',
          latitude: 53.144,
          longitude: 7.034,
        ),
      ]);
      final repository = HomeRepositoryImpl(
        _ThrowingHomeRemoteDataSource(Exception('unused')),
        locationDataSource,
      );

      final fallback = await repository.getCurrentLocation();
      final live = await repository.getCurrentLocation(forceRefresh: true);

      fallback.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected first lookup to fail.'),
      );
      live.fold(
        (failure) => fail('Expected live location, got $failure'),
        (location) => expect(location.cityName, 'Winschoten'),
      );
    },
  );

  test('passes force refresh through to the location data source', () async {
    final locationDataSource = _RecordingLocationDataSource(
      const HomeLocation(
        cityName: 'Winschoten',
        latitude: 53.144,
        longitude: 7.034,
      ),
    );
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(Exception('unused')),
      locationDataSource,
    );

    final result = await repository.getCurrentLocation(forceRefresh: true);

    expect(result.isRight(), isTrue);
    expect(locationDataSource.lastForceRefresh, isTrue);
  });

  test(
    'reuses cached location on later requests and watcher startup',
    () async {
      final locationDataSource = _CountingLocationDataSource(_sampleLocation);
      final repository = HomeRepositoryImpl(
        _HomeRemoteDataSourceStub(feed: _feed()),
        locationDataSource,
      );

      final first = await repository.getCurrentLocation();
      final second = await repository.getCurrentLocation();
      final watched = await repository.watchCurrentLocation().first;

      expect(first.isRight(), isTrue);
      expect(second.isRight(), isTrue);
      expect(watched.isRight(), isTrue);
      expect(locationDataSource.currentLocationCalls, 1);
      expect(locationDataSource.watchLocationCalls, 0);
    },
  );

  test('reuses fresh home feed cache for same location and distance', () async {
    final remoteDataSource = _HomeRemoteDataSourceStub(feed: _feed());
    final repository = HomeRepositoryImpl(
      remoteDataSource,
      const _FakeLocationDataSource(),
      feedCacheTtl: const Duration(seconds: 30),
    );

    const location = _sampleLocation;
    final first = await repository.getHomeFeed(
      location: location,
      filters: const HomeFeedFilters(),
    );
    final second = await repository.getHomeFeed(
      location: location,
      filters: const HomeFeedFilters(),
    );

    expect(first.isRight(), isTrue);
    expect(second.isRight(), isTrue);
    expect(remoteDataSource.getHomeFeedCalls, 1);
  });

  test('force refresh bypasses the fresh home feed cache', () async {
    final remoteDataSource = _HomeRemoteDataSourceStub(feed: _feed());
    final repository = HomeRepositoryImpl(
      remoteDataSource,
      const _FakeLocationDataSource(),
      feedCacheTtl: const Duration(seconds: 30),
    );

    const location = _sampleLocation;
    final first = await repository.getHomeFeed(
      location: location,
      filters: const HomeFeedFilters(),
    );
    final refreshed = await repository.getHomeFeed(
      location: location,
      filters: const HomeFeedFilters(),
      forceRefresh: true,
    );

    expect(first.isRight(), isTrue);
    expect(refreshed.isRight(), isTrue);
    expect(remoteDataSource.getHomeFeedCalls, 2);
  });

  test('marking chat read delegates to remote and clears feed cache', () async {
    final remoteDataSource = _HomeRemoteDataSourceStub(feed: _feed());
    final repository = HomeRepositoryImpl(
      remoteDataSource,
      const _FakeLocationDataSource(),
      feedCacheTtl: const Duration(seconds: 30),
    );
    const location = _sampleLocation;

    await repository.getHomeFeed(
      location: location,
      filters: const HomeFeedFilters(),
    );
    final result = await repository.markActivityChatRead(
      activityId: 'activity-1',
      messageId: 'message-1',
    );
    await repository.getHomeFeed(
      location: location,
      filters: const HomeFeedFilters(),
    );

    expect(result.isRight(), isTrue);
    expect(remoteDataSource.markActivityChatReadCalls, 1);
    expect(remoteDataSource.lastMarkedActivityId, 'activity-1');
    expect(remoteDataSource.lastMarkedMessageId, 'message-1');
    expect(remoteDataSource.getHomeFeedCalls, 2);
  });

  test('maps leave failures without chat access copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(
          status: 403,
          details: {
            'error': {
              'message': 'Verify your phone number before joining activities',
            },
          },
        ),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.setActivityParticipation(
      activityId: 'activity-1',
      join: false,
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Afmelden voor deze activiteit lukt nu niet. Probeer het opnieuw.',
      );
    }, (_) => fail('Expected leave failure.'));
  });

  test('maps generic join conflict to user friendly copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(status: 409, reasonPhrase: 'Conflict'),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.setActivityParticipation(
      activityId: 'activity-1',
      join: true,
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, isNot(contains('Conflict')));
      expect(
        failure.message,
        'Aanmelden voor deze activiteit lukt nu niet. Vernieuw het overzicht en probeer opnieuw.',
      );
    }, (_) => fail('Expected join conflict failure.'));
  });

  test('maps generic completion conflict to user friendly copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(status: 409, reasonPhrase: 'Conflict'),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.completeActivity(activityId: 'activity-1');

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, isNot(contains('Conflict')));
      expect(
        failure.message,
        'Afronden lukt nu niet. Vernieuw de activiteit en probeer opnieuw.',
      );
    }, (_) => fail('Expected completion conflict failure.'));
  });

  test('maps chat forbidden to chat access copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(
          status: 403,
          details: {
            'error': {'message': 'ACTIVITY_CHAT_FORBIDDEN'},
          },
        ),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.getActivityChatMessages(
      activityId: 'activity-1',
    );

    result.fold((failure) {
      expect(failure, isA<PermissionFailure>());
      expect(failure.message, 'Meld je eerst aan om de chat te openen.');
    }, (_) => fail('Expected chat permission failure.'));
  });

  test('maps closed chat to ended activity copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(
          status: 409,
          details: {
            'error': {'message': 'ACTIVITY_CHAT_CLOSED'},
          },
        ),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.sendActivityChatMessage(
      activityId: 'activity-1',
      body: 'Hoi',
      clientMessageId: '11111111-1111-4111-8111-111111111111',
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Deze activiteit is voorbij. De chat is gesloten.',
      );
    }, (_) => fail('Expected closed chat failure.'));
  });

  test('maps chat server errors to user-friendly chat copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(
          status: 500,
          details: {
            'error': {'message': 'Could not update activity chat'},
          },
        ),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.sendActivityChatMessage(
      activityId: 'activity-1',
      body: 'Hoi',
      clientMessageId: '11111111-1111-4111-8111-111111111111',
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Chat openen lukt nu niet. Probeer het later opnieuw.',
      );
    }, (_) => fail('Expected chat failure.'));
  });

  test('maps location search outage to address search copy', () async {
    final repository = HomeRepositoryImpl(
      _ThrowingHomeRemoteDataSource(
        const FunctionException(status: 502, reasonPhrase: 'Bad Gateway'),
      ),
      const _FakeLocationDataSource(),
    );

    final result = await repository.searchMeetingLocations(
      query: 'Markeweg',
      nearLocation: _sampleLocation,
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Adres zoeken is tijdelijk niet beschikbaar.');
    }, (_) => fail('Expected location search failure.'));
  });

  test('syncs account trust before joining an activity', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final accountTrustService = _CountingAccountTrustService(preferences);
    final remoteDataSource = _HomeRemoteDataSourceStub(feed: _feed());
    final repository = HomeRepositoryImpl(
      remoteDataSource,
      const _FakeLocationDataSource(),
      accountTrustService: accountTrustService,
    );

    final result = await repository.setActivityParticipation(
      activityId: 'activity-1',
      join: true,
    );

    expect(result.isRight(), isTrue);
    expect(accountTrustService.syncTrustCalls, 1);
  });
}

class _ThrowingHomeRemoteDataSource implements HomeRemoteDataSource {
  const _ThrowingHomeRemoteDataSource(this.error);

  final Object error;

  @override
  Future<String> createActivity(CreateActivityDraft draft) async {
    throw error;
  }

  @override
  Future<HomeActivity> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) async {
    throw error;
  }

  @override
  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
  }) async {
    throw error;
  }

  @override
  Future<HomeActivity> getActivityById(String activityId) async {
    throw error;
  }

  @override
  Future<ActivityParticipationUpdate> setActivityParticipation({
    required String activityId,
    required bool join,
  }) async {
    throw error;
  }

  @override
  Future<ActivityAgenda> getActivityAgenda() async {
    throw error;
  }

  @override
  Future<List<ActivityChatMessage>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  }) async {
    throw error;
  }

  @override
  Future<ActivityChatMessage> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  }) async {
    throw error;
  }

  @override
  Future<void> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) async {
    throw error;
  }

  @override
  Future<ActivityCompletionUpdate> completeActivity({
    required String activityId,
  }) async {
    throw error;
  }

  @override
  Future<ActivityFeedback> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) async {
    throw error;
  }

  @override
  Future<List<MeetingLocationSuggestion>> searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) async {
    throw error;
  }
}

class _FakeLocationDataSource implements HomeLocationDataSource {
  const _FakeLocationDataSource();

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    return _sampleLocation;
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    yield await getCurrentLocation();
  }
}

class _ThrowingLocationDataSource implements HomeLocationDataSource {
  const _ThrowingLocationDataSource(this.error);

  final Object error;

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    throw error;
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    throw error;
  }
}

class _HangingLocationDataSource implements HomeLocationDataSource {
  const _HangingLocationDataSource();

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) {
    return Completer<HomeLocation>().future;
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() {
    return const Stream.empty();
  }
}

class _SequenceLocationDataSource implements HomeLocationDataSource {
  _SequenceLocationDataSource(this.results);

  final List<Object> results;
  int _index = 0;

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    final result = results[_index++];
    if (result is HomeLocation) {
      return result;
    }
    throw result;
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    yield await getCurrentLocation();
  }
}

class _CountingLocationDataSource implements HomeLocationDataSource {
  _CountingLocationDataSource(this.location);

  final HomeLocation location;
  int currentLocationCalls = 0;
  int watchLocationCalls = 0;

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    currentLocationCalls++;
    return location;
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    watchLocationCalls++;
    yield location;
  }
}

class _RecordingLocationDataSource implements HomeLocationDataSource {
  _RecordingLocationDataSource(this.location);

  final HomeLocation location;
  bool? lastForceRefresh;

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    lastForceRefresh = forceRefresh;
    return location;
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    yield location;
  }
}

class _HomeRemoteDataSourceStub implements HomeRemoteDataSource {
  _HomeRemoteDataSourceStub({required this.feed});

  final HomeFeed feed;
  int getHomeFeedCalls = 0;
  int markActivityChatReadCalls = 0;
  String? lastMarkedActivityId;
  String? lastMarkedMessageId;

  @override
  Future<String> createActivity(CreateActivityDraft draft) async {
    return 'activity-1';
  }

  @override
  Future<HomeActivity> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
  }) async {
    getHomeFeedCalls++;
    return feed;
  }

  @override
  Future<HomeActivity> getActivityById(String activityId) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivityParticipationUpdate> setActivityParticipation({
    required String activityId,
    required bool join,
  }) async {
    return ActivityParticipationUpdate(
      activityId: activityId,
      isJoined: join,
      participants: const [],
      participantsCount: join ? 1 : 0,
      availableSpots: 4,
      participationStatus: join ? 'joined' : 'cancelled',
    );
  }

  @override
  Future<ActivityAgenda> getActivityAgenda() async {
    throw UnimplementedError();
  }

  @override
  Future<List<ActivityChatMessage>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivityChatMessage> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) async {
    markActivityChatReadCalls++;
    lastMarkedActivityId = activityId;
    lastMarkedMessageId = messageId;
  }

  @override
  Future<ActivityCompletionUpdate> completeActivity({
    required String activityId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivityFeedback> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MeetingLocationSuggestion>> searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) async {
    return const [];
  }
}

class _CountingAccountTrustService extends AccountTrustService {
  _CountingAccountTrustService(SharedPreferences preferences)
    : super(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
        preferences,
      );

  int syncTrustCalls = 0;

  @override
  Future<ProfileTrust> syncTrust() async {
    syncTrustCalls++;
    return ProfileTrust(
      phoneVerified: true,
      phoneVerifiedAt: DateTime.utc(2026, 6, 6),
      identityStatus: 'unverified',
      identityMethod: null,
      identityCompletedAt: null,
      ageVerified: false,
      reputationLevel: 'new_member',
      reputationScore: 0,
    );
  }
}

HomeFeed _feed() {
  return const HomeFeed(
    locationName: 'Winschoten',
    selectedTimeFilter: 'Alles',
    selectedDistanceKm: 10,
    timeFilters: ['Alles'],
    distanceFilters: [10],
    categories: [
      HomeCategory(
        id: 'category-1',
        label: 'Buiten',
        icon: Icons.park_rounded,
        color: Color(0xFF1E5740),
        backgroundColor: Color(0xFFE6EFE9),
      ),
    ],
    activities: [],
  );
}
