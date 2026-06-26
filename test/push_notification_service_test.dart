import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/services/push_notification_service.dart';

void main() {
  test('parses activity chat notification data', () {
    final activityId = PushNotificationService.activityChatIdFromRemoteMessage(
      const RemoteMessage(
        data: {
          'type': 'activity_chat',
          'activity_id': 'activity-1',
          'message_id': 'message-1',
        },
      ),
    );

    expect(activityId, 'activity-1');
  });

  test('ignores non-chat notification data', () {
    final activityId = PushNotificationService.activityChatIdFromRemoteMessage(
      const RemoteMessage(data: {'type': 'other', 'activity_id': 'activity-1'}),
    );

    expect(activityId, isNull);
  });

  test('reports push diagnostics without exposing token data', () {
    final diagnostics = PushNotificationService.diagnosticSummary();

    expect(diagnostics['enabled_by_flag'], isFalse);
    expect(diagnostics.containsKey('token'), isFalse);
  });
}
