import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/presentation/widgets/activity_detail_hero.dart';
import 'package:meetings_app/features/home/presentation/widgets/home_activity_card.dart';

void main() {
  testWidgets('activity detail hero renders key labels only once', (
    tester,
  ) async {
    final activity = _activity();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ActivityDetailHero(activity: activity)),
      ),
    );

    expect(find.text(activity.title), findsOneWidget);
    expect(find.text(activity.category.label), findsOneWidget);
    expect(find.text(activity.distanceLabel), findsOneWidget);
  });

  testWidgets('home activity card renders the activity title only once', (
    tester,
  ) async {
    final activity = _activity();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: HomeActivityCard(activity: activity)),
      ),
    );

    expect(find.text(activity.title), findsOneWidget);
  });
}

HomeActivity _activity() {
  return HomeActivity(
    id: 'activity-1',
    category: const HomeCategory(
      id: 'outside',
      label: 'Buiten',
      icon: Icons.park_rounded,
      color: Color(0xFF1E5740),
      backgroundColor: Color(0xFFE6EFE9),
    ),
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
