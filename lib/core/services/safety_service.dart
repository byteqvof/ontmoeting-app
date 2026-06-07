import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/supabase_function_auth.dart';
import 'safety_report_reason.dart';

class SafetyService {
  const SafetyService(this._client);

  final SupabaseClient _client;

  Future<void> reportActivity({
    required String activityId,
    SafetyReportReason reason = SafetyReportReason.other,
    String details = '',
  }) {
    return _report(
      targetType: 'activity',
      targetId: activityId,
      reason: reason,
      details: details,
    );
  }

  Future<void> reportProfile({
    required String profileId,
    SafetyReportReason reason = SafetyReportReason.other,
    String details = '',
  }) {
    return _report(
      targetType: 'profile',
      targetId: profileId,
      reason: reason,
      details: details,
    );
  }

  Future<void> blockProfile(String profileId) async {
    await _client.functions
        .invoke(
          supabaseSafetyActionsFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {'action': 'block', 'blocked_profile_id': profileId},
        )
        .timeout(_safetyActionTimeout);
  }

  Future<void> deleteAccount() async {
    await _client.functions
        .invoke(
          supabaseProfilesFunctionName,
          method: HttpMethod.delete,
          headers: authenticatedFunctionHeaders(_client),
        )
        .timeout(_safetyActionTimeout);
  }

  Future<void> _report({
    required String targetType,
    required String targetId,
    required SafetyReportReason reason,
    required String details,
  }) async {
    await _client.functions
        .invoke(
          supabaseSafetyActionsFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'action': 'report',
            'target_type': targetType,
            'target_id': targetId,
            'reason_category': reason.backendValue,
            'reason': reason.backendValue,
            'details': details,
          },
        )
        .timeout(_safetyActionTimeout);
  }
}

const _safetyActionTimeout = Duration(seconds: 8);
