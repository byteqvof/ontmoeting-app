import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://pmnymluxikcmqehlbxlt.supabase.co';
const supabaseAnonKey = 'sb_publishable_q9O8Q1jmRZ-9PVGdj_9dYg_S24tTwwt';

class SupabaseConfig {
  const SupabaseConfig._();

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
