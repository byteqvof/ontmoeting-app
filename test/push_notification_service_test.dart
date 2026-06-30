import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/config/supabase_config.dart';
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

  test('uses platform specific Firebase app ids before legacy fallback', () {
    expect(
      firebaseAppIdForTargetPlatform(
        platform: TargetPlatform.android,
        fallbackAppId: 'legacy-app',
        androidAppId: 'android-app',
        iosAppId: 'ios-app',
      ),
      'android-app',
    );
    expect(
      firebaseAppIdForTargetPlatform(
        platform: TargetPlatform.iOS,
        fallbackAppId: 'legacy-app',
        androidAppId: 'android-app',
        iosAppId: 'ios-app',
      ),
      'ios-app',
    );
    expect(
      firebaseAppIdForTargetPlatform(
        platform: TargetPlatform.iOS,
        fallbackAppId: 'legacy-app',
        androidAppId: 'android-app',
        iosAppId: '',
      ),
      'legacy-app',
    );
  });

  test('reports Firebase client config completeness from platform app id', () {
    expect(
      isFirebaseClientConfigComplete(
        apiKey: 'api-key',
        platformAppId: 'platform-app',
        messagingSenderId: 'sender',
        projectId: 'project',
      ),
      isTrue,
    );
    expect(
      isFirebaseClientConfigComplete(
        apiKey: 'api-key',
        platformAppId: '',
        messagingSenderId: 'sender',
        projectId: 'project',
      ),
      isFalse,
    );
  });
}
