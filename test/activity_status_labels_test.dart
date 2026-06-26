import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/domain/entities/home_participant.dart';
import 'package:meetings_app/features/home/presentation/widgets/activity_status_labels.dart';

void main() {
  test('completed organizer activity is labeled afgerond', () {
    final activity = _activity(status: 'completed', isOwnedByCurrentUser: true);

    expect(activityPrimaryActionLabel(activity), 'Afgerond');
    expect(readOnlyChatNoticeText(activity), contains('afgerond'));
    expect(readOnlyChatNoticeText(activity), isNot(contains('afgemeld')));
  });

  test(
    'completed joined activity with present attendance is labeled present',
    () {
      final activity = _activity(
        status: 'completed',
        isJoined: true,
        participants: const [
          HomeParticipant(
            id: 'current-user',
            displayName: 'Jasper',
            initials: 'JS',
            isHost: false,
            attendanceStatus: 'present',
          ),
        ],
      );

      expect(
        activityPrimaryActionLabel(activity, currentUserId: 'current-user'),
        'Je was erbij',
      );
    },
  );

  test('completed joined activity without attendance is labeled geweest', () {
    final activity = _activity(status: 'completed', isJoined: true);

    expect(activityPrimaryActionLabel(activity), 'Geweest');
    expect(readOnlyChatNoticeText(activity), contains('afgerond'));
    expect(readOnlyChatNoticeText(activity), isNot(contains('afgemeld')));
  });

  test('completed non participant activity is labeled afgelopen', () {
    final activity = _activity(status: 'completed');

    expect(activityPrimaryActionLabel(activity), 'Afgelopen');
  });

  test('cancelled participation keeps afgemeld chat notice', () {
    final activity = _activity(
      isJoined: false,
      participationStatus: 'cancelled',
      canSendChat: false,
    );

    expect(readOnlyChatNoticeText(activity), contains('afgemeld'));
  });
}

HomeActivity _activity({
  String status = 'published',
  bool isJoined = false,
  bool isOwnedByCurrentUser = false,
  bool canSendChat = true,
  String? participationStatus,
  List<HomeParticipant> participants = const [],
}) {
  return HomeActivity(
    id: 'activity-1',
    category: const HomeCategory(
      id: 'category-1',
      label: 'Buiten',
      icon: Icons.park_rounded,
      color: Color(0xFF1E5740),
      backgroundColor: Color(0xFFE6EFE9),
    ),
    distanceKm: 0,
    distanceLabel: 'Ter Apel',
    title: 'Wandelen',
    dateLabel: 'vrijdag 5 jun',
    timeLabel: '14:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Centrum',
    description: 'Een rustige wandeling.',
    hostId: 'host-1',
    hostName: 'Jasper',
    hostFullName: 'Jasper Scheper',
    hostSubtitle: 'Ter Apel',
    hostScore: 100,
    participants: participants,
    availableSpots: 3,
    spotsLabel: 'nog 3 plekken',
    status: status,
    isJoined: isJoined,
    isOwnedByCurrentUser: isOwnedByCurrentUser,
    participationStatus: participationStatus,
    canSendChat: canSendChat,
  );
}
