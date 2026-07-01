import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityFavoriteService {
  const ActivityFavoriteService(this._client);

  final SupabaseClient _client;

  Future<bool> getFavoriteStatus(String activityId) async {
    final userId = _requireUserId();
    final data = await _client
        .from('activity_favorites')
        .select('activity_id')
        .eq('profile_id', userId)
        .eq('activity_id', activityId)
        .maybeSingle()
        .timeout(_favoriteTimeout);

    return _asMap(data).isNotEmpty;
  }

  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorited,
  }) async {
    final userId = _requireUserId();
    if (isFavorited) {
      await _client
          .from('activity_favorites')
          .upsert(
            {'profile_id': userId, 'activity_id': activityId},
            onConflict: 'profile_id,activity_id',
            ignoreDuplicates: true,
          )
          .timeout(_favoriteTimeout);
      return true;
    }

    await _client
        .from('activity_favorites')
        .delete()
        .eq('profile_id', userId)
        .eq('activity_id', activityId)
        .timeout(_favoriteTimeout);
    return false;
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthException(
        'Je sessie is verlopen. Log opnieuw in om door te gaan.',
      );
    }
    return userId;
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is String) {
    return _asMap(jsonDecode(value));
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

const _favoriteTimeout = Duration(seconds: 5);
