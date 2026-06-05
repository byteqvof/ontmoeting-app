import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/domain/entities/activity_agenda.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';

void main() {
  test('chat activities combines hosted and joined without duplicates', () {
    final hosted = _activity('activity-1', title: 'Vissen');
    final joined = _activity('activity-2', title: 'Koffie');
    final duplicate = _activity('activity-1', title: 'Vissen later');

    final agenda = ActivityAgenda(
      hostedActivities: [hosted],
      joinedActivities: [joined, duplicate],
    );

    expect(agenda.chatActivities, [hosted, joined]);
    expect(agenda.totalCount, 3);
  });
}

HomeActivity _activity(String id, {required String title}) {
  return HomeActivity(
    id: id,
    category: const HomeCategory(
      id: 'category-1',
      label: 'Buiten',
      icon: Icons.park_rounded,
      color: Color(0xFF1E5740),
      backgroundColor: Color(0xFFE6EFE9),
    ),
    distanceKm: 0,
    distanceLabel: 'Ter Apel',
    title: title,
    dateLabel: 'vrijdag 5 jun',
    timeLabel: '14:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Centrum',
    description: 'Rustig en laagdrempelig.',
    hostId: 'host-1',
    hostName: 'Jasper',
    hostFullName: 'Jasper Scheper',
    hostSubtitle: 'Ter Apel',
    hostScore: 100,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
  );
}
