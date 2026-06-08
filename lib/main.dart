import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart';
import 'core/services/analytics_service.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushNotificationService.initializeFirebaseMessaging();
  await SupabaseConfig.initialize();
  await AnalyticsService.initializePostHog();
  await configureDependencies();

  void launchApp() => runApp(const App());

  if (sentryDsn.trim().isEmpty) {
    launchApp();
    return;
  }

  await SentryFlutter.init(
    AnalyticsService.configureSentryOptions,
    appRunner: launchApp,
  );
}
