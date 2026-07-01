import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart';
import 'core/services/analytics_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApplication();
    runApp(const App());
  } catch (error) {
    runApp(_StartupErrorApp(error: error));
  }
}

Future<void> _initializeApplication() async {
  SupabaseConfig.logStartupConfiguration();

  await _runStartupStep(
    'Firebase messaging',
    PushNotificationService.initializeFirebaseMessaging,
    optional: true,
  );
  await _runStartupStep('Supabase', SupabaseConfig.initialize);
  await _runStartupStep(
    'PostHog',
    AnalyticsService.initializePostHog,
    optional: true,
  );
  await _runStartupStep('Dependencies', configureDependencies);

  if (sentryDsn.trim().isEmpty) {
    return;
  }

  await _runStartupStep(
    'Sentry',
    () => SentryFlutter.init(AnalyticsService.configureSentryOptions),
    optional: true,
  );
}

Future<void> _runStartupStep(
  String name,
  Future<void> Function() run, {
  bool optional = false,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    await run().timeout(timeout);
    AppLogger.debug(
      'Startup step "$name" completed in ${stopwatch.elapsedMilliseconds}ms',
    );
  } catch (error, stackTrace) {
    debugPrint(
      '[Startup] $name failed after ${stopwatch.elapsedMilliseconds}ms: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
    if (!optional) {
      throw StartupException(name, error);
    }
  }
}

class StartupException implements Exception {
  const StartupException(this.step, this.cause);

  final String step;
  final Object cause;

  @override
  String toString() => '$step startup failed: $cause';
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF4DF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOCH.',
                  style: TextStyle(
                    color: Color(0xFF16473C),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'De app kon niet starten.',
                  style: TextStyle(
                    color: Color(0xFF16473C),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    color: Color(0xFF315F53),
                    fontSize: 15,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
