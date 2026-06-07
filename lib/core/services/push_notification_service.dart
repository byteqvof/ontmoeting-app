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
  bool _initialized = false;
  String? _lastRegisteredToken;

  Future<void> registerForCurrentUser() async {
    if (!_canUsePush) {
      return;
    }

    try {
      await _ensureInitialized();
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
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
    if (_initialized) {
      return;
    }

    await Firebase.initializeApp(options: _firebaseOptions);
    _initialized = true;
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
  }

  bool get _canUsePush {
    return tochPushEnabled &&
        !kIsWeb &&
        _pushPlatform.isNotEmpty &&
        firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
  }
}

FirebaseOptions get _firebaseOptions {
  return const FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
  );
}

String get _pushPlatform {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => '',
  };
}
