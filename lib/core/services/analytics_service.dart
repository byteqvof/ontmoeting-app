import 'dart:async';

import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/app_logger.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  bool _posthogEnabled = false;
  bool _sentryEnabled = false;

  bool get isPosthogEnabled => _posthogEnabled;
  bool get isSentryEnabled => _sentryEnabled;

  static Future<void> initializePostHog() => instance._initializePostHog();

  static Future<void> configureSentryOptions(SentryFlutterOptions options) {
    return instance._configureSentryOptions(options);
  }

  void track(String eventName, {Map<String, Object?> properties = const {}}) {
    if (!_posthogEnabled) {
      return;
    }

    unawaited(
      Posthog().capture(
        eventName: eventName,
        properties: _sanitize(properties),
      ),
    );
  }

  void identify(String userId) {
    if (!_posthogEnabled || userId.isEmpty) {
      return;
    }

    unawaited(Posthog().identify(userId: userId));
  }

  void reset() {
    if (!_posthogEnabled) {
      return;
    }

    unawaited(Posthog().reset());
  }

  void captureException(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> properties = const {},
  }) {
    if (!_sentryEnabled) {
      return;
    }

    unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  }

  Future<void> _initializePostHog() async {
    final token = posthogApiKey.trim();
    if (token.isEmpty) {
      return;
    }

    final config = PostHogConfig(token)
      ..host = posthogHost
      ..personProfiles = PostHogPersonProfiles.identifiedOnly
      ..sessionReplay = false
      ..debug = appEnvironment == 'dev'
      ..beforeSend = [_redactPostHogEvent];

    try {
      await Posthog().setup(config);
      _posthogEnabled = true;
      track('app_started', properties: {'environment': appEnvironment});
    } catch (error, stackTrace) {
      AppLogger.debug(
        'PostHog setup failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _configureSentryOptions(SentryFlutterOptions options) async {
    options
      ..dsn = sentryDsn
      ..environment = appEnvironment
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..tracesSampleRate = appEnvironment == 'prod' ? 0.10 : 0.0;
    _sentryEnabled = sentryDsn.trim().isNotEmpty;
  }
}

PostHogEvent? _redactPostHogEvent(PostHogEvent event) {
  event.properties = _sanitize(event.properties ?? const {});
  return event;
}

Map<String, Object> _sanitize(Map<String, Object?> properties) {
  final sanitized = <String, Object>{};

  for (final entry in properties.entries) {
    final key = entry.key.trim();
    final value = entry.value;
    if (key.isEmpty || value == null || _isSensitiveKey(key)) {
      continue;
    }

    if (value is String) {
      if (value.length > 120) {
        sanitized[key] = value.substring(0, 120);
      } else {
        sanitized[key] = value;
      }
    } else if (value is num || value is bool) {
      sanitized[key] = value;
    } else if (value is Iterable) {
      sanitized[key] = value.length;
    } else {
      sanitized[key] = value.toString();
    }
  }

  return sanitized;
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase();
  return normalized.contains('phone') ||
      normalized.contains('email') ||
      normalized.contains('message') ||
      normalized.contains('body') ||
      normalized.contains('text') ||
      normalized.contains('details') ||
      normalized.contains('comment') ||
      normalized.contains('latitude') ||
      normalized.contains('longitude') ||
      normalized.contains('gps') ||
      normalized.contains('address');
}
