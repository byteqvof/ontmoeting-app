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
import 'package:meetings_app/features/home/domain/usecases/get_activity_agenda.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_notice_controller.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_realtime_controller.dart';
import 'package:meetings_app/features/home/presentation/pages/activity_agenda_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(sl.reset);

  testWidgets(
    'shows hosted agenda activities when the hosted count is nonzero',
    (tester) async {
      final client = _testSupabaseClient();
      sl.registerLazySingleton(
        () => GetActivityAgenda(
          _AgendaRepository(
            ActivityAgenda(
              hostedActivities: [_hostedActivity()],
              joinedActivities: const [],
            ),
          ),
        ),
      );
      sl.registerLazySingleton<ActivityChatNoticeService>(
        () => ActivityChatNoticeController(
          client,
          ActivityChatRealtimeController(client),
        ),
      );
      sl.registerLazySingleton<FriendshipService>(_FriendshipServiceStub.new);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ActivityAgendaPage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Organiseert 1'));
      await tester.pumpAndSettle();

      expect(find.text('Organiseert 1'), findsOneWidget);
      expect(find.text('Test activiteit beheren'), findsOneWidget);
      expect(find.text('Beheer'), findsOneWidget);
      expect(find.text('Bewerk'), findsOneWidget);
    },
  );
}

HomeActivity _hostedActivity() {
  return HomeActivity(
    id: 'activity-hosted-1',
    category: const HomeCategory(id: 'category-1', label: 'Buiten'),
    distanceKm: 1,
    distanceLabel: '1 km',
    title: 'Test activiteit beheren',
    startsAt: DateTime.now().add(const Duration(days: 1)),
    dateLabel: 'morgen',
    timeLabel: '15:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Bibliotheek',
    description: 'Rustig en laagdrempelig.',
    hostId: 'host-1',
    hostName: 'Jasper',
    hostFullName: 'Jasper Scheper',
    hostSubtitle: 'Ter Apel',
    hostScore: 100,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
    isJoined: true,
    isOwnedByCurrentUser: true,
    canSendChat: true,
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

class _AgendaRepository implements HomeRepository {
  const _AgendaRepository(this.agenda);

  final ActivityAgenda agenda;

  @override
  Future<Either<Failure, ActivityAgenda>> getActivityAgenda() async {
    return Right(agenda);
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
  Future<Either<Failure, HomeActivity>> getActivityById(String activityId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) {
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
  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
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
  Future<Either<Failure, ActivityParticipationUpdate>>
  setActivityParticipation({required String activityId, required bool join}) {
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
  Future<Either<Failure, HomeActivity>> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<Either<Failure, HomeLocation>> watchCurrentLocation() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MeetingLocationSuggestion>>>
  searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) {
    throw UnimplementedError();
  }
}
