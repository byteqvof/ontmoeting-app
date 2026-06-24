import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/domain/entities/activity_agenda.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';

void main() {
  test('chat activities combines active hosted and joined without duplicates', () {
    final hosted = _activity('activity-1', title: 'Vissen');
    final joined = _activity('activity-2', title: 'Koffie');
    final duplicate = _activity('activity-1', title: 'Vissen later');
    final completed = _activity(
      'activity-3',
      title: 'Wandelen',
      status: 'completed',
    );

    final agenda = ActivityAgenda(
      hostedActivities: [hosted],
      joinedActivities: [joined, duplicate],
      completedActivities: [completed],
    );

    expect(agenda.chatActivities, [hosted, joined]);
    expect(agenda.totalCount, 3);
  });

  test('agenda sections keep completed activities out of active lists', () {
    final hostedActive = _activity(
      'activity-1',
      title: 'Koffie',
      status: 'published',
    );
    final hostedCompleted = _activity(
      'activity-2',
      title: 'Wandelen',
      status: 'completed',
    );
    final completedDuplicate = _activity(
      'activity-2',
      title: 'Wandelen',
      status: 'completed',
    );

    final agenda = ActivityAgenda(
      hostedActivities: [hostedActive, hostedCompleted],
      joinedActivities: [hostedCompleted],
      completedActivities: [completedDuplicate],
    );

    expect(agenda.activeHostedActivities, [hostedActive]);
    expect(agenda.activeJoinedActivities, isEmpty);
    expect(agenda.uniqueCompletedActivities, [completedDuplicate]);
  });

  test('chat activities prioritizes unread and recent conversations', () {
    final quiet = _activity(
      'activity-1',
      title: 'Vissen',
      chatUnreadCount: 0,
      chatLastMessageAt: DateTime(2026, 6, 6, 18),
    );
    final unread = _activity(
      'activity-2',
      title: 'Koffie',
      chatUnreadCount: 2,
      chatLastMessageAt: DateTime(2026, 6, 6, 17),
    );
    final recent = _activity(
      'activity-3',
      title: 'Wandelen',
      chatUnreadCount: 0,
      chatLastMessageAt: DateTime(2026, 6, 6, 19),
    );

    final agenda = ActivityAgenda(
      hostedActivities: [quiet],
      joinedActivities: [unread, recent],
    );

    expect(agenda.chatActivities, [unread, recent, quiet]);
  });

  test('marking a chat read clears unread count in all agenda sections', () {
    final hosted = _activity(
      'activity-1',
      title: 'Vissen',
      chatUnreadCount: 1,
    );
    final joined = _activity(
      'activity-1',
      title: 'Vissen',
      chatUnreadCount: 1,
    );
    final other = _activity(
      'activity-2',
      title: 'Koffie',
      chatUnreadCount: 2,
    );

    final agenda = ActivityAgenda(
      hostedActivities: [hosted],
      joinedActivities: [joined, other],
    );

    final updated = agenda.withChatMarkedRead('activity-1');

    expect(updated.hostedActivities.first.chatUnreadCount, 0);
    expect(updated.joinedActivities.first.chatUnreadCount, 0);
    expect(updated.joinedActivities.last.chatUnreadCount, 2);
  });
}

HomeActivity _activity(
  String id, {
  required String title,
  String status = 'published',
  int chatUnreadCount = 0,
  DateTime? chatLastMessageAt,
}) {
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
    status: status,
    chatUnreadCount: chatUnreadCount,
    chatLastMessageAt: chatLastMessageAt,
  );
}
