import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/core/di/injection_container.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/core/services/friendship_service.dart';
import 'package:meetings_app/features/home/domain/entities/activity_agenda.dart';
import 'package:meetings_app/features/home/domain/entities/activity_chat_message.dart';
import 'package:meetings_app/features/home/domain/entities/activity_completion_update.dart';
import 'package:meetings_app/features/home/domain/entities/activity_feedback.dart';
import 'package:meetings_app/features/home/domain/entities/activity_participation_update.dart';
import 'package:meetings_app/features/home/domain/entities/create_activity_draft.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/domain/entities/home_feed.dart';
import 'package:meetings_app/features/home/domain/entities/home_feed_filters.dart';
import 'package:meetings_app/features/home/domain/entities/home_location.dart';
import 'package:meetings_app/features/home/domain/entities/meeting_location_suggestion.dart';
import 'package:meetings_app/features/home/domain/repositories/home_repository.dart';
import 'package:meetings_app/features/home/domain/services/activity_chat_notice_service.dart';
import 'package:meetings_app/features/home/domain/usecases/get_current_location.dart';
import 'package:meetings_app/features/home/domain/usecases/get_home_feed.dart';
import 'package:meetings_app/features/home/domain/usecases/search_meeting_locations.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_notice_controller.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_realtime_controller.dart';
import 'package:meetings_app/features/home/presentation/pages/activity_map_page.dart';
import 'package:meetings_app/features/home/presentation/widgets/activity_map_canvas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(() async {
    debugActivityMapCanvasBuilder = null;
    await sl.reset();
  });

  testWidgets('renders redesigned map overlays and featured activity card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugActivityMapCanvasBuilder = (_, _) {
      return const ColoredBox(
        color: Color(0xFFE8ECE2),
        child: Center(child: Text('map placeholder')),
      );
    };

    final repository = _MapRepository();
    final client = _testSupabaseClient();
    sl
      ..registerLazySingleton(() => GetHomeFeed(repository))
      ..registerLazySingleton(() => GetCurrentLocation(repository))
      ..registerLazySingleton(() => SearchMeetingLocations(repository))
      ..registerLazySingleton<ActivityChatNoticeService>(
        () => ActivityChatNoticeController(
          client,
          ActivityChatRealtimeController(client),
        ),
      )
      ..registerLazySingleton<FriendshipService>(_FriendshipServiceStub.new);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ActivityMapPage(
          args: ActivityMapPageArgs(
            location: _maastrichtLocation,
            activities: [_coffeeActivity()],
            filters: const HomeFeedFilters(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zoek in Maastricht'), findsOneWidget);
    expect(find.text('Nu live'), findsOneWidget);
    expect(find.text('Vandaag'), findsOneWidget);
    expect(find.text('Dit weekend'), findsOneWidget);
    expect(find.text('live'), findsNothing);
    expect(find.text('drukte'), findsNothing);
    expect(find.text('1,1 km'), findsOneWidget);
    expect(find.text('Ochtendkoffie bij Coffeelovers'), findsOneWidget);
    expect(find.text('NB'), findsOneWidget);
    expect(find.text('SV'), findsNothing);
    expect(find.text('JE'), findsNothing);
    expect(find.text('EM'), findsNothing);
    expect(find.text('Aansluiten'), findsOneWidget);
    expect(find.text('nog 3 plek'), findsOneWidget);
  });
}

const _maastrichtLocation = HomeLocation(
  cityName: 'Maastricht',
  latitude: 50.851,
  longitude: 5.691,
);

HomeActivity _coffeeActivity() {
  return HomeActivity(
    id: 'activity-coffee',
    category: const HomeCategory(id: 'coffee', label: 'Koffie'),
    distanceKm: 1.1,
    distanceLabel: '1,1 km',
    title: 'Ochtendkoffie bij Coffeelovers',
    startsAt: DateTime.now(),
    dateLabel: 'Vandaag',
    timeLabel: '09:45',
    locationName: 'Maastricht',
    meetingPoint: 'Coffeelovers',
    description: 'Rustig koffie drinken voor wie zin heeft.',
    hostId: 'host-1',
    hostName: 'Nora',
    hostFullName: 'Nora Bakker',
    hostSubtitle: 'Maastricht',
    hostScore: 55,
    participants: const [],
    participantCount: 2,
    availableSpots: 3,
    spotsLabel: 'nog 3 plek',
  );
}

class _FriendshipServiceStub extends FriendshipService {
  _FriendshipServiceStub() : super(_testSupabaseClient());

  @override
  Future<List<FriendshipListItem>> listFriends() async {
    return const [];
  }
}

SupabaseClient _testSupabaseClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

class _MapRepository implements HomeRepository {
  @override
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    return right(_maastrichtLocation);
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
  }) async {
    return right(
      HomeFeed(
        locationName: location.cityName,
        selectedTimeFilter: 'Alles',
        selectedDistanceKm: filters.distanceKm,
        timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
        distanceFilters: const [5, 10, 25, 50],
        categories: const [],
        activities: [_coffeeActivity()],
      ),
    );
  }

  @override
  Future<Either<Failure, List<MeetingLocationSuggestion>>>
  searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) async {
    return right(const []);
  }

  @override
  Future<Either<Failure, ActivityCompletionUpdate>> completeActivity({
    required String activityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> createActivity(CreateActivityDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityAgenda>> getActivityAgenda() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeActivity>> getActivityById(String activityId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ActivityChatMessage>>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityChatMessage>> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityFeedback>> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({required String activityId, required bool join}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeActivity>> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() {
    return const Stream.empty();
  }
}
