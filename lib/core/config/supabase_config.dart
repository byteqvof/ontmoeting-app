import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

const supabaseUrl = 'https://pmnymluxikcmqehlbxlt.supabase.co';
const supabaseAnonKey = 'sb_publishable_q9O8Q1jmRZ-9PVGdj_9dYg_S24tTwwt';
const supabaseOAuthRedirectUrl = 'meetingsapp://auth-callback';
const supabaseNearbyActivitiesFunctionName = 'activities-nearby';
const supabaseCreateActivityFunctionName = 'activities-create';
const supabaseProfilesFunctionName = 'profiles';
const supabaseUserActivitiesFunctionName = 'activities-for-user';

class SupabaseConfig {
  const SupabaseConfig._();

  static String? get oauthRedirectTo {
    if (kIsWeb) {
      return null;
    }
    return supabaseOAuthRedirectUrl;
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
