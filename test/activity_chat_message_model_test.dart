import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/data/models/activity_chat_message_model.dart';
import 'package:meetings_app/features/home/domain/entities/activity_chat_message.dart';

void main() {
  test('parses chat message and marks current user messages', () {
    final message = ActivityChatMessageModel.fromJson(const {
      'id': 'message-1',
      'activity_id': 'activity-1',
      'sender_id': 'profile-1',
      'body': 'Ik ben er rond twee uur.',
      'created_at': '2026-06-05T12:30:00Z',
      'client_message_id': 'client-message-1',
      'sender': {
        'id': 'profile-1',
        'display_name': 'Jasper Scheper',
        'initials': 'JS',
        'avatar_url': 'https://example.com/avatar.png',
      },
    }, currentUserId: 'profile-1');

    expect(message.id, 'message-1');
    expect(message.activityId, 'activity-1');
    expect(message.senderId, 'profile-1');
    expect(message.senderName, 'Jasper Scheper');
    expect(message.senderInitials, 'JS');
    expect(message.senderAvatarUrl, 'https://example.com/avatar.png');
    expect(message.body, 'Ik ben er rond twee uur.');
    expect(message.createdAt.toUtc(), DateTime.utc(2026, 6, 5, 12, 30));
    expect(message.clientMessageId, 'client-message-1');
    expect(message.isMine, isTrue);
  });

  test('parses system chat messages', () {
    final message = ActivityChatMessageModel.fromJson(const {
      'id': 'message-2',
      'activity_id': 'activity-1',
      'sender_id': 'profile-2',
      'body': 'Sanne heeft zich afgemeld',
      'created_at': '2026-06-05T13:00:00Z',
      'message_type': 'system',
      'sender': {'id': 'profile-2', 'display_name': 'Sanne', 'initials': 'S'},
    }, currentUserId: 'profile-1');

    expect(message.messageType, ActivityChatMessageType.system);
    expect(message.isSystem, isTrue);
    expect(message.isMine, isFalse);
  });
}
