import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const firebaseMessagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://pmnymluxikcmqehlbxlt.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_q9O8Q1jmRZ-9PVGdj_9dYg_S24tTwwt',
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
const supabasePushTokenFunctionName = 'push-token';
const supabaseProfilesFunctionName = 'profiles';
const supabaseSafetyActionsFunctionName = 'safety-actions';
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

  static Future<void> initialize() {
    return Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
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
