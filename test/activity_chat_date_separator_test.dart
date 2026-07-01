import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/core/di/injection_container.dart';
import 'package:meetings_app/core/errors/failures.dart';
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
import 'package:meetings_app/features/home/domain/services/activity_chat_notice_service.dart';
import 'package:meetings_app/features/home/domain/services/activity_chat_realtime_service.dart';
import 'package:meetings_app/features/home/domain/usecases/get_activity_chat_messages.dart';
import 'package:meetings_app/features/home/domain/usecases/mark_activity_chat_read.dart';
import 'package:meetings_app/features/home/domain/usecases/send_activity_chat_message.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_notice_controller.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_realtime_controller.dart';
import 'package:meetings_app/features/home/presentation/pages/activity_chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'shows date separators between chat messages from different days',
    (tester) async {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final yesterday = startOfToday.subtract(const Duration(days: 1));
      final earlier = startOfToday.subtract(const Duration(days: 4));
      final repository = _ChatRepository([
        _message(
          id: 'message-earlier',
          body: 'Tot dan.',
          createdAt: earlier.add(const Duration(hours: 19)),
        ),
        _message(
          id: 'message-yesterday',
          body: 'Neem jij aas mee?',
          createdAt: yesterday.add(const Duration(hours: 18)),
        ),
        _message(
          id: 'message-today',
          body: 'Ik ben onderweg.',
          createdAt: startOfToday.add(const Duration(hours: 9)),
          isMine: true,
        ),
      ]);
      final realtime = _FakeRealtimeController();

      sl
        ..registerLazySingleton(() => GetActivityChatMessages(repository))
        ..registerLazySingleton(() => SendActivityChatMessage(repository))
        ..registerLazySingleton(() => MarkActivityChatRead(repository))
        ..registerLazySingleton<ActivityChatRealtimeService>(() => realtime)
        ..registerLazySingleton(
          () => ActivityChatNoticeController(_testSupabaseClient(), realtime),
        )
        ..registerLazySingleton<ActivityChatNoticeService>(
          () => sl<ActivityChatNoticeController>(),
        );

      final authBloc = _authBloc(_FakeAuthRepository());
      addTearDown(authBloc.close);
      final router = GoRouter(
        initialLocation: '/chat',
        routes: [
          GoRoute(
            path: '/chat',
            builder: (context, state) =>
                ActivityChatPage(activity: _activity()),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        BlocProvider.value(
          value: authBloc,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tot dan.'), findsOneWidget);
      expect(find.text('Neem jij aas mee?'), findsOneWidget);
      expect(find.text('Ik ben onderweg.'), findsOneWidget);
      expect(find.text('Gisteren'), findsOneWidget);
      expect(find.text('Vandaag'), findsOneWidget);
      expect(find.text(_fullDutchDateLabel(earlier)), findsOneWidget);
    },
  );

  testWidgets('tapping outside the chat input clears keyboard focus', (
    tester,
  ) async {
    final today = DateTime.now();
    final repository = _ChatRepository([
      _message(
        id: 'message-1',
        body: 'Ik sta bij de ingang.',
        createdAt: today.subtract(const Duration(minutes: 5)),
      ),
    ]);
    final realtime = _FakeRealtimeController();

    sl
      ..registerLazySingleton(() => GetActivityChatMessages(repository))
      ..registerLazySingleton(() => SendActivityChatMessage(repository))
      ..registerLazySingleton(() => MarkActivityChatRead(repository))
      ..registerLazySingleton<ActivityChatRealtimeService>(() => realtime)
      ..registerLazySingleton(
        () => ActivityChatNoticeController(_testSupabaseClient(), realtime),
      )
      ..registerLazySingleton<ActivityChatNoticeService>(
        () => sl<ActivityChatNoticeController>(),
      );

    final authBloc = _authBloc(_FakeAuthRepository());
    addTearDown(authBloc.close);
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        GoRoute(
          path: '/chat',
          builder: (context, state) => ActivityChatPage(activity: _activity()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authBloc,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Tot zo');
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Ik sta bij de ingang.'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });
}

ActivityChatMessage _message({
  required String id,
  required String body,
  required DateTime createdAt,
  bool isMine = false,
}) {
  return ActivityChatMessage(
    id: id,
    activityId: 'activity-1',
    senderId: isMine ? 'user-1' : 'user-2',
    senderName: isMine ? 'Jasper' : 'Joren',
    senderInitials: isMine ? 'JA' : 'JO',
    body: body,
    createdAt: createdAt,
    isMine: isMine,
  );
}

HomeActivity _activity() {
  return HomeActivity(
    id: 'activity-1',
    category: const HomeCategory(
      id: 'outside',
      label: 'Buiten',
      iconKey: 'outside',
      colorHex: '#1E5740',
      backgroundColorHex: '#E6EFE9',
    ),
    distanceKm: 1,
    distanceLabel: '1 km',
    title: 'Avondvissen aan de Maas',
    startsAt: DateTime.now().add(const Duration(days: 1)),
    dateLabel: 'morgen',
    timeLabel: '19:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Markeweg 23',
    description: 'Rustig samen vissen.',
    hostId: 'user-2',
    hostName: 'Joren',
    hostFullName: 'Joren',
    hostSubtitle: 'Ter Apel',
    hostScore: 55,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
    isJoined: true,
    canSendChat: true,
  );
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

class _FakeAuthRepository implements AuthRepository {
  final StreamController<Either<Failure, AuthUser?>> _authController =
      StreamController<Either<Failure, AuthUser?>>.broadcast();

  @override
  Stream<Either<Failure, AuthUser?>> authStateChanges() {
    return _authController.stream;
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    return right(const AuthUser(id: 'user-1', email: 'jasper@example.com'));
  }

  @override
  Future<Either<Failure, void>> resendSignUpVerificationEmail(
    String email,
  ) async {
    return right(null);
  }

  @override
  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    return right(AuthUser(id: 'user-1', email: email));
  }

  @override
  Future<Either<Failure, void>> signInWithOAuth(
    AuthOAuthProvider provider,
  ) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return right(null);
  }

  @override
  Future<Either<Failure, AuthSignUpResult>> signUp({
    required String email,
    required String password,
  }) async {
    return right(AuthSignUpAuthenticated(AuthUser(id: 'user-1', email: email)));
  }
}

class _FakeRealtimeController extends ActivityChatRealtimeController {
  _FakeRealtimeController() : super(_testSupabaseClient());

  final StreamController<ActivityChatMessage> _messages =
      StreamController<ActivityChatMessage>.broadcast();

  @override
  Stream<ActivityChatMessage> get messages => _messages.stream;

  @override
  Future<void> subscribeToActivity(String activityId) async {}

  @override
  Future<void> stopAll() async {}

  @override
  void dispose() {
    _messages.close();
  }
}

class _ChatRepository implements HomeRepository {
  const _ChatRepository(this.messages);

  final List<ActivityChatMessage> messages;

  @override
  Future<Either<Failure, List<ActivityChatMessage>>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  }) async {
    if (afterCreatedAt != null || afterId != null) {
      return right(const []);
    }
    return right(messages);
  }

  @override
  Future<Either<Failure, void>> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) async {
    return right(null);
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
  Future<Either<Failure, List<MeetingLocationSuggestion>>>
  searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
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
    return const Stream.empty();
  }
}

SupabaseClient _testSupabaseClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

String _fullDutchDateLabel(DateTime value) {
  final local = value.toLocal();
  const weekdays = [
    'maandag',
    'dinsdag',
    'woensdag',
    'donderdag',
    'vrijdag',
    'zaterdag',
    'zondag',
  ];
  const months = [
    'januari',
    'februari',
    'maart',
    'april',
    'mei',
    'juni',
    'juli',
    'augustus',
    'september',
    'oktober',
    'november',
    'december',
  ];
  return '${weekdays[local.weekday - 1]} ${local.day} ${months[local.month - 1]}';
}
