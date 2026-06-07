import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/supabase_function_auth.dart';

class ActivityAttendanceService {
  const ActivityAttendanceService(this._client);

  final SupabaseClient _client;

  Future<void> markAttendance({
    required String activityId,
    required String profileId,
    required ActivityAttendanceStatus status,
  }) async {
    await _client.functions
        .invoke(
          supabaseActivityAttendanceFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'activity_id': activityId,
            'profile_id': profileId,
            'status': status.backendValue,
          },
        )
        .timeout(_attendanceTimeout);
  }
}

enum ActivityAttendanceStatus {
  present('present'),
  absent('absent'),
  unknown('unknown');

  const ActivityAttendanceStatus(this.backendValue);

  final String backendValue;
}

const _attendanceTimeout = Duration(seconds: 8);
