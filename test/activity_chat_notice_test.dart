import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/data/models/activity_chat_notice_model.dart';
import 'package:meetings_app/features/home/data/controllers/activity_chat_notice_controller.dart';

void main() {
  test('parses realtime chat insert records', () {
    final notice = ActivityChatNoticeModel.fromRealtimeRecord(const {
      'id': 'message-1',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Ik ben onderweg',
      'created_at': '2026-06-05T18:20:00Z',
    }, currentUserId: 'profile-1');

    expect(notice, isNotNull);
    expect(notice!.id, 'message-1');
    expect(notice.activityId, 'activity-1');
    expect(notice.senderId, 'profile-2');
    expect(notice.body, 'Ik ben onderweg');
    expect(notice.isMine, isFalse);
  });

  test('notice tracker ignores own messages and counts other chats', () {
    final tracker = ActivityChatNoticeTracker(currentUserId: 'profile-1');

    final ownNotice = tracker.trackRealtimeRecord(const {
      'id': 'message-1',
      'activity_id': 'activity-1',
      'sender_id': 'profile-1',
      'body': 'Eigen bericht',
      'created_at': '2026-06-05T18:20:00Z',
    });
    final otherNotice = tracker.trackRealtimeRecord(const {
      'id': 'message-2',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Nieuw bericht',
      'created_at': '2026-06-05T18:21:00Z',
    });

    expect(ownNotice, isNull);
    expect(otherNotice, isNotNull);
    expect(tracker.unreadCount, 1);
  });

  test('notice tracker emits active chat messages without unread count', () {
    final tracker = ActivityChatNoticeTracker(
      currentUserId: 'profile-1',
      activeActivityId: 'activity-1',
    );

    final notice = tracker.trackRealtimeRecord(const {
      'id': 'message-3',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Ben je er al?',
      'created_at': '2026-06-05T18:22:00Z',
    });

    expect(notice, isNotNull);
    expect(tracker.unreadCount, 0);
  });

  test('notice tracker clears unread count for opened activity', () {
    final tracker = ActivityChatNoticeTracker(currentUserId: 'profile-1');

    tracker.trackRealtimeRecord(const {
      'id': 'message-6',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Nieuw bericht',
      'created_at': '2026-06-05T18:25:00Z',
    });
    tracker.trackRealtimeRecord(const {
      'id': 'message-7',
      'activity_id': 'activity-2',
      'sender_id': 'profile-2',
      'body': 'Andere chat',
      'created_at': '2026-06-05T18:26:00Z',
    });

    tracker.markActivityRead('activity-1');

    expect(tracker.unreadCount, 1);
  });

  test('notice tracker can prime existing messages without notifying', () {
    final tracker = ActivityChatNoticeTracker(currentUserId: 'profile-1');

    tracker.rememberRealtimeRecord(const {
      'id': 'message-4',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Bestaand bericht',
      'created_at': '2026-06-05T18:23:00Z',
    });
    final existingNotice = tracker.trackRealtimeRecord(const {
      'id': 'message-4',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Bestaand bericht',
      'created_at': '2026-06-05T18:23:00Z',
    });
    final newNotice = tracker.trackRealtimeRecord(const {
      'id': 'message-5',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Nieuw bericht',
      'created_at': '2026-06-05T18:24:00Z',
    });

    expect(existingNotice, isNull);
    expect(newNotice, isNotNull);
    expect(tracker.unreadCount, 1);
  });
}
