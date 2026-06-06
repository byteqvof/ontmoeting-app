import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/data/models/activity_feedback_model.dart';
import 'package:meetings_app/features/home/domain/entities/activity_completion_update.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';

void main() {
  test('applies completion update to matching activity', () {
    final activity = _activity('activity-1');

    final updated = activity.applyCompletionUpdate(
      const ActivityCompletionUpdate(
        activityId: 'activity-1',
        status: 'completed',
      ),
    );

    expect(updated.status, 'completed');
    expect(updated.isCompleted, isTrue);
  });

  test('ignores completion update for another activity', () {
    final activity = _activity('activity-1');

    final updated = activity.applyCompletionUpdate(
      const ActivityCompletionUpdate(
        activityId: 'activity-2',
        status: 'completed',
      ),
    );

    expect(updated, activity);
  });

  test('parses submitted activity feedback target profile', () {
    final feedback = ActivityFeedbackModel.fromJson(const {
      'id': 'feedback-1',
      'activity_id': 'activity-1',
      'reviewer_id': 'reviewer-1',
      'target_profile_id': 'target-1',
      'rating': 5,
      'comment': 'Rustig en gezellig.',
      'created_at': '2026-06-05T17:30:00Z',
      'target': {
        'id': 'target-1',
        'display_name': 'Jasper Scheper',
        'initials': 'JS',
        'avatar_url': 'https://example.com/avatar.png',
      },
    });

    expect(feedback.id, 'feedback-1');
    expect(feedback.activityId, 'activity-1');
    expect(feedback.targetProfileId, 'target-1');
    expect(feedback.targetName, 'Jasper Scheper');
    expect(feedback.targetInitials, 'JS');
    expect(feedback.rating, 5);
    expect(feedback.comment, 'Rustig en gezellig.');
    expect(feedback.createdAt.toUtc(), DateTime.utc(2026, 6, 5, 17, 30));
  });
}

HomeActivity _activity(String id) {
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
    title: 'Wandelen',
    dateLabel: 'vrijdag 5 jun',
    timeLabel: '14:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Centrum',
    description: 'Rustig wandelen.',
    hostId: 'host-1',
    hostName: 'Jasper',
    hostFullName: 'Jasper Scheper',
    hostSubtitle: 'Ter Apel',
    hostScore: 100,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
    status: 'published',
  );
}
