import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/core/services/push_notification_service.dart';
import 'package:meetings_app/features/profile/presentation/pages/notifications_page.dart';
import 'package:meetings_app/features/profile/presentation/pages/privacy_location_page.dart';

void main() {
  testWidgets('notification permission button requests push permission', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var requestCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotificationsPage(
          requestPushPermission: () async {
            requestCount += 1;
            return PushNotificationPermissionResult.authorized;
          },
        ),
      ),
    );

    expect(requestCount, 0);
    expect(find.text('Mis niks praktisch'), findsOneWidget);
    expect(
      find.text('Alleen relevante updates rond activiteiten en chats.'),
      findsOneWidget,
    );

    final pushButton = find.widgetWithText(FilledButton, 'Push toestaan');
    await tester.ensureVisible(pushButton);
    await tester.pumpAndSettle();
    await tester.tap(pushButton);
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(find.text('Pushmeldingen staan aan.'), findsOneWidget);
  });

  testWidgets(
    'location permission button requests device location permission',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var requestCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PrivacyLocationPage(
            requestLocationPermission: () async {
              requestCount += 1;
              return LocationPermission.whileInUse;
            },
          ),
        ),
      );

      final locationButton = find.widgetWithText(
        FilledButton,
        'Locatie toestaan',
      );
      await tester.ensureVisible(locationButton);
      await tester.pumpAndSettle();
      await tester.tap(locationButton);
      await tester.pumpAndSettle();

      expect(requestCount, 1);
      expect(find.text('Locatie is toegestaan.'), findsOneWidget);
    },
  );
}
