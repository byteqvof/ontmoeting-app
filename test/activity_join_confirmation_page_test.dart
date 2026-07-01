import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/app/router/app_router.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/presentation/pages/activity_join_confirmation_page.dart';
import 'package:meetings_app/core/services/push_notification_service.dart';

void main() {
  testWidgets('shows joined confirmation with activity and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ActivityJoinConfirmationPage(
          activity: _activity(),
          onOpenChat: () {},
          onBackToDiscover: () {},
        ),
      ),
    );

    expect(find.text('Je gaat!'), findsOneWidget);
    expect(find.text('Avondvissen aan de Maas'), findsOneWidget);
    expect(find.textContaining('vrijdag 6 jun'), findsOneWidget);
    expect(find.text('Open de chat'), findsOneWidget);
    expect(find.text('Terug naar ontdekken'), findsOneWidget);
  });

  testWidgets('opens chat from confirmation so back returns to home', (
    tester,
  ) async {
    final activity = _activity();
    final router = GoRouter(
      initialLocation: AppRoutes.activityJoinConfirmationPath(activity.id),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: Text('Home geopend'))),
        ),
        GoRoute(
          path: AppRoutes.activityJoinConfirmation,
          builder: (context, state) =>
              ActivityJoinConfirmationPage(activity: activity),
        ),
        GoRoute(
          path: AppRoutes.activityChat,
          builder: (context, state) {
            final fromJoined = state.uri.queryParameters['from'] == 'joined';
            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (fromJoined) {
                          context.go(AppRoutes.home);
                          return;
                        }
                        context.pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Text('Chat geopend'),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    await tester.tap(find.text('Open de chat'));
    await tester.pumpAndSettle();

    expect(find.text('Chat geopend'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Home geopend'), findsOneWidget);
  });
}

HomeActivity _activity() {
  return const HomeActivity(
    id: 'activity-1',
    category: HomeCategory(id: 'category-1', label: 'Vissen'),
    distanceKm: 1.2,
    distanceLabel: '1,2 km',
    title: 'Avondvissen aan de Maas',
    dateLabel: 'vrijdag 6 jun',
    timeLabel: '19:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Steiger',
    description: 'Rustig vissen.',
    hostId: 'host-1',
    hostName: 'Jasper',
    hostFullName: 'Jasper Scheper',
    hostSubtitle: 'Ter Apel',
    hostScore: 100,
    participants: [],
    availableSpots: 3,
    spotsLabel: 'nog 3 plekken',
    isJoined: true,
  );
}
