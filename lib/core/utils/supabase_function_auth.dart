import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, String> authenticatedFunctionHeaders(SupabaseClient client) {
  final accessToken = client.auth.currentSession?.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    throw const AuthException(
      'Je sessie is verlopen. Log opnieuw in om door te gaan.',
    );
  }

  return {'Authorization': 'Bearer $accessToken'};
}
