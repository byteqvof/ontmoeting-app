import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/domain/entities/activity_participation_update.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/domain/entities/home_participant.dart';

void main() {
  test('applies participation update to matching activity', () {
    final activity = _activity();
    const participant = HomeParticipant(
      id: 'profile-1',
      displayName: 'Jasper Scheper',
      initials: 'JS',
      isHost: false,
    );

    final updated = activity.applyParticipationUpdate(
      const ActivityParticipationUpdate(
        activityId: 'activity-1',
        isJoined: true,
        participants: [participant],
        participantsCount: 1,
        availableSpots: 2,
      ),
    );

    expect(updated.isJoined, isTrue);
    expect(updated.participants, [participant]);
    expect(updated.availableSpots, 2);
    expect(updated.spotsLabel, 'jij gaat ook');
    expect(updated.canSendChat, isTrue);
  });

  test(
    'leaving an activity disables chat sending but keeps read state possible',
    () {
      final activity = _activity().copyWith(isJoined: true, canSendChat: true);

      final updated = activity.applyParticipationUpdate(
        const ActivityParticipationUpdate(
          activityId: 'activity-1',
          isJoined: false,
          participants: [],
          participantsCount: 0,
          availableSpots: 3,
          participationStatus: 'cancelled',
        ),
      );

      expect(updated.isJoined, isFalse);
      expect(updated.participationStatus, 'cancelled');
      expect(updated.canSendChat, isFalse);
    },
  );

  test('keeps attendance and feedback state on participants', () {
    final markedParticipant = HomeParticipant(
      id: 'profile-1',
      displayName: 'Jasper Scheper',
      initials: 'JS',
      isHost: false,
      attendanceStatus: 'present',
      attendanceMarkedAt: DateTime.utc(2026, 6, 7, 10),
      feedbackSubmitted: true,
    );

    expect(markedParticipant.attendanceStatus, 'present');
    expect(markedParticipant.isAttendancePresent, isTrue);
    expect(markedParticipant.feedbackSubmitted, isTrue);
  });

  test('ignores participation update for another activity', () {
    final activity = _activity();

    final updated = activity.applyParticipationUpdate(
      const ActivityParticipationUpdate(
        activityId: 'activity-2',
        isJoined: true,
        participants: [],
        participantsCount: 0,
        availableSpots: 0,
      ),
    );

    expect(updated, activity);
  });

  test('preserves featured flag through copyWith', () {
    final activity = _activity();

    expect(activity.isFeatured, isFalse);

    final featured = activity.copyWith(isFeatured: true);

    expect(featured.isFeatured, isTrue);
  });

  test('marks completed activities as closed for chat', () {
    final activity = _activity(status: 'completed');

    expect(activity.isChatClosed, isTrue);
  });
}

HomeActivity _activity({String status = 'published'}) {
  return HomeActivity(
    id: 'activity-1',
    category: HomeCategory(
      id: 'category-1',
      label: 'Buiten',
      icon: Icons.park_rounded,
      color: Color(0xFF1E5740),
      backgroundColor: Color(0xFFE6EFE9),
    ),
    distanceKm: 1.2,
    distanceLabel: '1,2 km',
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
    participants: [],
    availableSpots: 3,
    spotsLabel: 'nog 3 plekken',
    status: status,
  );
}
