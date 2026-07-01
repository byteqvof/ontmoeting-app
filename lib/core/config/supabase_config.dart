import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import 'supabase_auth_storage.dart';

const defaultSupabaseUrl = 'https://pmnymluxikcmqehlbxlt.supabase.co';
const defaultSupabaseAnonKey = 'sb_publishable_q9O8Q1jmRZ-9PVGdj_9dYg_S24tTwwt';
const appEnvironment = String.fromEnvironment('TOCH_ENV', defaultValue: 'dev');
const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
const posthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://eu.i.posthog.com',
);
const sentryDsn = String.fromEnvironment('SENTRY_DSN');
const tochFakePhoneVerificationRequested = bool.fromEnvironment(
  'TOCH_FAKE_PHONE_VERIFICATION',
);
const tochFakePhoneVerificationEnabled =
    tochFakePhoneVerificationRequested && appEnvironment == 'dev';
const tochPushEnabled = bool.fromEnvironment('TOCH_ENABLE_PUSH');
const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');

/// Legacy fallback for older local commands. Prefer the platform-specific ids.
const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const firebaseAndroidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
const firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
const firebaseIosBundleId = String.fromEnvironment(
  'FIREBASE_IOS_BUNDLE_ID',
  defaultValue: 'nl.gatoch.toch',
);
const firebaseMessagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: defaultSupabaseUrl,
);
const tochPublicShareBaseUrl = String.fromEnvironment(
  'TOCH_PUBLIC_SHARE_BASE_URL',
  defaultValue: 'https://gatoch.nl',
);
const tochPublicShareUrlTemplate = String.fromEnvironment(
  'TOCH_PUBLIC_SHARE_URL_TEMPLATE',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: defaultSupabaseAnonKey,
);
const supabaseOAuthRedirectUrl = 'meetingsapp://auth-callback';
const supabaseEmailVerificationRedirectUrl =
    'meetingsapp://auth-callback/email-verification';
const supabaseNearbyActivitiesFunctionName = 'activities-nearby';
const supabaseActivityDetailFunctionName = 'activities-detail';
const supabaseCreateActivityFunctionName = 'activities-create';
const supabaseUpdateActivityFunctionName = 'activities-update';
const supabaseActivityParticipationFunctionName = 'activities-participation';
const supabaseActivityAgendaFunctionName = 'activities-agenda';
const supabaseActivityChatFunctionName = 'activity-chat';
const supabaseActivityCompleteFunctionName = 'activities-complete';
const supabaseActivityFeedbackFunctionName = 'activity-feedback';
const supabaseActivityAttendanceFunctionName = 'activity-attendance';
const supabaseActivityFavoritesFunctionName = 'activity-favorites';
const supabasePushTokenFunctionName = 'push-token';
const supabaseLocationsSearchFunctionName = 'locations-search';
const supabaseProfilesFunctionName = 'profiles';
const supabaseSafetyActionsFunctionName = 'safety-actions';
const supabaseFriendsFunctionName = 'friends';
const supabaseAccountTrustFunctionName = 'account-trust';
const supabaseUserActivitiesFunctionName = 'activities-for-user';

class SupabaseConfig {
  const SupabaseConfig._();

  static String? get oauthRedirectTo {
    if (kIsWeb) {
      return null;
    }
    return supabaseOAuthRedirectUrl;
  }

  static String? get emailVerificationRedirectTo {
    if (kIsWeb) {
      return null;
    }
    return supabaseEmailVerificationRedirectUrl;
  }

  static void logStartupConfiguration() {
    final supabaseHost = Uri.tryParse(supabaseUrl)?.host;
    final platformFirebaseAppId = firebaseAppIdForTargetPlatform(
      platform: defaultTargetPlatform,
      fallbackAppId: firebaseAppId,
      androidAppId: firebaseAndroidAppId,
      iosAppId: firebaseIosAppId,
    );
    final firebaseConfigured = isFirebaseClientConfigComplete(
      apiKey: firebaseApiKey,
      platformAppId: platformFirebaseAppId,
      messagingSenderId: firebaseMessagingSenderId,
      projectId: firebaseProjectId,
    );

    AppLogger.debug(
      'Startup config: '
      'env=$appEnvironment, '
      'fakePhoneRequested=$tochFakePhoneVerificationRequested, '
      'fakePhoneEnabled=$tochFakePhoneVerificationEnabled, '
      'pushEnabled=$tochPushEnabled, '
      'firebaseConfigured=$firebaseConfigured, '
      'firebasePlatformAppId=${_redactConfigValue(platformFirebaseAppId)}, '
      'firebaseUsesLegacyAppId=${platformFirebaseAppId.isNotEmpty && platformFirebaseAppId == firebaseAppId}, '
      'posthogConfigured=${posthogApiKey.trim().isNotEmpty}, '
      'sentryConfigured=${sentryDsn.trim().isNotEmpty}, '
      'supabaseHost=${supabaseHost ?? '<invalid>'}, '
      'usesDefaultSupabaseUrl=${supabaseUrl == defaultSupabaseUrl}, '
      'supabaseKey=${_redactConfigValue(supabaseAnonKey)}, '
      'usesDefaultSupabaseKey=${supabaseAnonKey == defaultSupabaseAnonKey}',
    );
  }

  static Future<void> initialize() {
    final authStorage = SupabaseAuthStorage(
      persistSessionKey:
          'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token',
    );

    return Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: authStorage,
        pkceAsyncStorage: authStorage,
      ),
    );
  }
}

bool isFakePhoneVerificationAllowed({
  required String environment,
  required bool requested,
}) {
  return requested && environment.trim().toLowerCase() == 'dev';
}

String firebaseAppIdForTargetPlatform({
  required TargetPlatform platform,
  required String fallbackAppId,
  required String androidAppId,
  required String iosAppId,
}) {
  final platformAppId = switch (platform) {
    TargetPlatform.android => androidAppId,
    TargetPlatform.iOS => iosAppId,
    _ => '',
  }.trim();
  if (platformAppId.isNotEmpty) {
    return platformAppId;
  }
  return fallbackAppId.trim();
}

bool isFirebaseClientConfigComplete({
  required String apiKey,
  required String platformAppId,
  required String messagingSenderId,
  required String projectId,
}) {
  return apiKey.trim().isNotEmpty &&
      platformAppId.trim().isNotEmpty &&
      messagingSenderId.trim().isNotEmpty &&
      projectId.trim().isNotEmpty;
}

String _redactConfigValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '<empty>';
  }
  if (trimmed.length <= 10) {
    return '<set:${trimmed.length} chars>';
  }
  return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 4)}'
      ' (${trimmed.length} chars)';
}
