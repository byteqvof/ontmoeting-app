import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/core/di/injection_container.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/core/services/activity_attendance_service.dart';
import 'package:meetings_app/core/services/activity_favorite_service.dart';
import 'package:meetings_app/core/services/activity_share_service.dart';
import 'package:meetings_app/core/services/safety_report_reason.dart';
import 'package:meetings_app/core/services/safety_service.dart';
import 'package:meetings_app/features/auth/domain/entities/auth_oauth_provider.dart';
import 'package:meetings_app/features/auth/domain/entities/auth_sign_up_result.dart';
import 'package:meetings_app/features/auth/domain/entities/auth_user.dart';
import 'package:meetings_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meetings_app/features/auth/domain/usecases/auth_state_changes.dart';
import 'package:meetings_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:meetings_app/features/auth/domain/usecases/resend_sign_up_verification_email.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_in.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_in_with_oauth.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_out.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_up.dart';
import 'package:meetings_app/features/auth/presentation/bloc/auth_bloc.dart';
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
import 'package:meetings_app/features/home/domain/usecases/complete_activity.dart';
import 'package:meetings_app/features/home/domain/usecases/set_activity_participation.dart';
import 'package:meetings_app/features/home/domain/usecases/submit_activity_feedback.dart';
import 'package:meetings_app/features/home/presentation/pages/activity_detail_page.dart';
import 'package:meetings_app/features/profile/domain/entities/create_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/entities/profile.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_activity.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_interest.dart';
import 'package:meetings_app/features/profile/domain/entities/update_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:meetings_app/features/profile/domain/usecases/get_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

void main() {
  setUp(() async {
    await sl.reset();
    final homeRepository = _FakeHomeRepository();
    sl
      ..registerLazySingleton(() => SetActivityParticipation(homeRepository))
      ..registerLazySingleton(() => CompleteActivity(homeRepository))
      ..registerLazySingleton(() => SubmitActivityFeedback(homeRepository))
      ..registerLazySingleton<ActivityAttendanceService>(
        _FakeActivityAttendanceService.new,
      )
      ..registerLazySingleton<ActivityFavoriteService>(
        _FakeActivityFavoriteService.new,
      )
      ..registerLazySingleton<ActivityShareService>(
        () => const ActivityShareService(),
      )
      ..registerLazySingleton<SafetyService>(_FakeSafetyService.new)
      ..registerLazySingleton(() => GetProfile(_FakeProfileRepository()));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('activity detail can be dismissed with an iOS edge swipe', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final activity = _activity();
    final authRepository = _FakeAuthRepository();
    final authBloc = _authBloc(authRepository);
    addTearDown(authBloc.close);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/activities/${activity.id}'),
                child: const Text('Open activiteit'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/activities/:activityId',
          builder: (context, state) => ActivityDetailPage(activity: activity),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authBloc,
        child: MaterialApp.router(
          theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Open activiteit'));
    await tester.pumpAndSettle();

    expect(find.text(activity.title), findsOneWidget);

    await tester.dragFrom(const Offset(2, 420), const Offset(420, 0));
    await tester.pumpAndSettle();

    expect(find.text('Open activiteit'), findsOneWidget);
    expect(find.text(activity.title), findsNothing);
  });
}

AuthBloc _authBloc(AuthRepository repository) {
  return AuthBloc(
    SignIn(repository),
    SignInWithOAuth(repository),
    SignUp(repository),
    ResendSignUpVerificationEmail(repository),
    SignOut(repository),
    GetCurrentUser(repository),
    AuthStateChanges(repository),
  );
}

HomeActivity _activity() {
  return HomeActivity(
    id: 'activity-1',
    category: const HomeCategory(id: 'outside', label: 'Buiten'),
    distanceKm: 1.2,
    distanceLabel: '1,2 km',
    title: 'Avondvissen aan de Maas',
    dateLabel: 'vrijdag 26 jun',
    timeLabel: '17:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Markeweg 23',
    description: 'Ik ga testen. Sluit gezellig aan.',
    hostId: 'host-1',
    hostName: 'Joren',
    hostFullName: 'Joren',
    hostSubtitle: 'Ter Apel',
    hostScore: 55,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
  );
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<Either<Failure, AuthUser?>> _authController =
      StreamController<Either<Failure, AuthUser?>>.broadcast();

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    return right<Failure, AuthUser?>(null);
  }

  @override
  Stream<Either<Failure, AuthUser?>> authStateChanges() {
    return _authController.stream;
  }

  @override
  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    return right(AuthUser(id: 'user-1', email: email));
  }

  @override
  Future<Either<Failure, AuthSignUpResult>> signUp({
    required String email,
    required String password,
  }) async {
    return right(AuthSignUpAuthenticated(AuthUser(id: 'user-1', email: email)));
  }

  @override
  Future<Either<Failure, void>> resendSignUpVerificationEmail(
    String email,
  ) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> signInWithOAuth(
    AuthOAuthProvider provider,
  ) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> signOut() async => right(null);
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<Either<Failure, ActivityCompletionUpdate>> completeActivity({
    required String activityId,
  }) async {
    return right(
      ActivityCompletionUpdate(activityId: activityId, status: 'completed'),
    );
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
  Future<Either<Failure, HomeLocation>> getCurrentLocation({
    bool forceRefresh = false,
  }) {
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
  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) {
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
  setActivityParticipation({
    required String activityId,
    required bool join,
  }) async {
    return right(
      ActivityParticipationUpdate(
        activityId: activityId,
        isJoined: join,
        participants: const [],
        participantsCount: 0,
        availableSpots: 4,
      ),
    );
  }

  @override
  Future<Either<Failure, ActivityFeedback>> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) async {
    return right(
      ActivityFeedback(
        id: 'feedback-1',
        activityId: activityId,
        reviewerId: 'user-1',
        targetProfileId: targetProfileId,
        targetName: 'Joren',
        targetInitials: 'JO',
        rating: rating,
        comment: comment,
        createdAt: DateTime.utc(2026, 6, 30),
      ),
    );
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

class _FakeActivityAttendanceService extends ActivityAttendanceService {
  _FakeActivityAttendanceService() : super(_fakeSupabaseClient);

  @override
  Future<void> markAttendance({
    required String activityId,
    required String profileId,
    required ActivityAttendanceStatus status,
  }) async {}
}

class _FakeActivityFavoriteService extends ActivityFavoriteService {
  _FakeActivityFavoriteService() : super(_fakeSupabaseClient);

  @override
  Future<bool> getFavoriteStatus(String activityId) async => false;

  @override
  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorited,
  }) async {
    return isFavorited;
  }
}

class _FakeSafetyService extends SafetyService {
  _FakeSafetyService() : super(_fakeSupabaseClient);

  @override
  Future<void> reportActivity({
    required String activityId,
    SafetyReportReason reason = SafetyReportReason.other,
    String details = '',
  }) async {}

  @override
  Future<void> reportProfile({
    required String profileId,
    SafetyReportReason reason = SafetyReportReason.other,
    String details = '',
  }) async {}

  @override
  Future<void> blockProfile(String profileId) async {}

  @override
  Future<void> deleteAccount() async {}
}

final _fakeSupabaseClient = SupabaseClient(
  'https://example.supabase.co',
  'test-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<Either<Failure, Profile>> createProfile(CreateProfileDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ProfileActivity>>> getActivitiesForUser({
    String? profileId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ProfileInterest>>> getAvailableInterests() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Profile>> getProfile({String? profileId}) async {
    return right(
      Profile(
        id: profileId ?? 'user-1',
        displayName: 'Joren',
        initials: 'JO',
        cityName: 'Ter Apel',
        memberSince: DateTime.utc(2026, 1),
        avatarUrl: null,
        attendanceScore: 55,
        activitiesJoinedCount: 0,
        activitiesHostedCount: 1,
        rating: 0,
        isVerified: false,
        isPremium: false,
        interests: const [],
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> isProfileOnboardingRequired() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(UpdateProfileDraft draft) {
    throw UnimplementedError();
  }
}
