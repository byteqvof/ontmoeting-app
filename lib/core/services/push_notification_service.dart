import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/app_logger.dart';
import '../utils/supabase_function_auth.dart';

class PushNotificationService {
  PushNotificationService(this._client);

  final SupabaseClient _client;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  final StreamController<String> _chatNotificationOpens =
      StreamController<String>.broadcast();
  bool _interactionHandlersStarted = false;
  String? _lastRegisteredToken;

  Stream<String> get chatNotificationOpens => _chatNotificationOpens.stream;

  static Map<String, Object> diagnosticSummary() {
    return {
      'enabled_by_flag': tochPushEnabled,
      'is_web': kIsWeb,
      'platform': _pushPlatform.isEmpty ? 'unsupported' : _pushPlatform,
      'has_firebase_api_key': firebaseApiKey.isNotEmpty,
      'has_firebase_app_id': _firebaseAppId.isNotEmpty,
      'has_legacy_firebase_app_id': firebaseAppId.isNotEmpty,
      'has_android_firebase_app_id': firebaseAndroidAppId.isNotEmpty,
      'has_ios_firebase_app_id': firebaseIosAppId.isNotEmpty,
      'uses_legacy_firebase_app_id': _usesLegacyFirebaseAppId,
      'has_firebase_sender_id': firebaseMessagingSenderId.isNotEmpty,
      'has_firebase_project_id': firebaseProjectId.isNotEmpty,
      'can_use_push': _canUsePush,
    };
  }

  static Future<void> initializeFirebaseMessaging() {
    if (!_canUsePush) {
      AppLogger.debug(
        'Push Firebase initialization disabled: ${diagnosticSummary()}',
      );
      return Future<void>.value();
    }
    return _firebaseInitialization ??= _initializeFirebaseMessaging()
        .catchError((Object error, StackTrace stackTrace) {
          _firebaseInitialization = null;
          AppLogger.debug(
            'Push Firebase initialization skipped',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  Future<void> startInteractionHandlers() async {
    if (!_canUsePush || _interactionHandlersStarted) {
      return;
    }
    _interactionHandlersStarted = true;

    try {
      await _ensureInitialized();
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      _handleOpenedMessage(initialMessage);
      _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp
          .listen(_handleOpenedMessage);
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Push interaction handlers skipped',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static String? activityChatIdFromRemoteMessage(RemoteMessage? message) {
    if (message == null) {
      return null;
    }
    final data = message.data;
    if (data['type'] != 'activity_chat') {
      return null;
    }
    final activityId = data['activity_id']?.toString().trim();
    if (activityId == null || activityId.isEmpty) {
      return null;
    }
    return activityId;
  }

  Future<void> registerForCurrentUser() async {
    if (!_canUsePush) {
      AppLogger.debug('Push registration disabled: ${diagnosticSummary()}');
      return;
    }

    try {
      await _ensureInitialized();
      final settings = await FirebaseMessaging.instance.requestPermission();
      AppLogger.debug(
        'Push permission status: ${settings.authorizationStatus.name}',
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final apnsReady = await _waitForAppleApnsToken();
      if (!apnsReady) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      } else {
        AppLogger.debug('Push registration skipped: empty FCM token');
      }

      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((token) {
            unawaited(_registerToken(token));
          });
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Push registration skipped',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> unregisterCurrentToken() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final token = _lastRegisteredToken;
    if (!_canUsePush || token == null || token.isEmpty) {
      return;
    }

    try {
      await _client.functions.invoke(
        supabasePushTokenFunctionName,
        method: HttpMethod.delete,
        headers: authenticatedFunctionHeaders(_client),
        body: {'token': token},
      );
      _lastRegisteredToken = null;
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Push unregister skipped',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _ensureInitialized() async {
    await initializeFirebaseMessaging();
  }

  Future<void> _registerToken(String token) async {
    if (token == _lastRegisteredToken) {
      return;
    }

    await _client.functions.invoke(
      supabasePushTokenFunctionName,
      headers: authenticatedFunctionHeaders(_client),
      body: {'token': token, 'platform': _pushPlatform},
    );
    _lastRegisteredToken = token;
    AppLogger.debug('Push token registered for $_pushPlatform');
  }

  Future<bool> _waitForAppleApnsToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.isNotEmpty) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    AppLogger.debug('Push registration skipped: APNs token unavailable');
    return false;
  }

  void _handleOpenedMessage(RemoteMessage? message) {
    final activityId = activityChatIdFromRemoteMessage(message);
    if (activityId == null) {
      return;
    }
    _chatNotificationOpens.add(activityId);
  }
}

Future<void>? _firebaseInitialization;

Future<void> _initializeFirebaseMessaging() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: _firebaseOptions);
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: _firebaseOptions);
  }
}

FirebaseOptions get _firebaseOptions {
  return FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: _firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    iosBundleId: _pushPlatform == 'ios' ? firebaseIosBundleId : null,
  );
}

String get _pushPlatform {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => '',
  };
}

bool get _canUsePush {
  return tochPushEnabled &&
      !kIsWeb &&
      _pushPlatform.isNotEmpty &&
      isFirebaseClientConfigComplete(
        apiKey: firebaseApiKey,
        platformAppId: _firebaseAppId,
        messagingSenderId: firebaseMessagingSenderId,
        projectId: firebaseProjectId,
      );
}

String get _firebaseAppId {
  return firebaseAppIdForTargetPlatform(
    platform: defaultTargetPlatform,
    fallbackAppId: firebaseAppId,
    androidAppId: firebaseAndroidAppId,
    iosAppId: firebaseIosAppId,
  );
}

bool get _usesLegacyFirebaseAppId {
  return _firebaseAppId.isNotEmpty &&
      _firebaseAppId == firebaseAppId &&
      switch (defaultTargetPlatform) {
        TargetPlatform.android => firebaseAndroidAppId.isEmpty,
        TargetPlatform.iOS => firebaseIosAppId.isEmpty,
        _ => false,
      };
}
