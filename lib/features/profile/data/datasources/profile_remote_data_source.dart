import 'dart:async';
import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/supabase_function_auth.dart';
import '../../domain/entities/create_profile_draft.dart';
import '../../domain/entities/update_profile_draft.dart';
import '../models/profile_activity_model.dart';
import '../models/profile_model.dart';
import 'profile_data_source.dart';

class ProfileRemoteDataSource implements ProfileDataSource {
  const ProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfileModel> getProfile({String? profileId}) async {
    final response = await _client.functions
        .invoke(
          supabaseProfilesFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
          queryParameters: {
            if (profileId != null && profileId.isNotEmpty) 'id': profileId,
          },
        )
        .timeout(_profileFunctionTimeout);

    return _profileFromResponse(response.data, profileId: profileId);
  }

  @override
  Future<bool> isProfileOnboardingRequired() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return true;
    }

    final profile = await _withTransientRetry(
      () => _client
          .from('profiles')
          .select('id')
          .eq('id', currentUserId)
          .maybeSingle()
          .timeout(_profileGateTimeout),
    );

    return _asMap(profile).isEmpty;
  }

  @override
  Future<List<ProfileInterestModel>> getAvailableInterests() async {
    final data = await _client
        .from('activity_categories')
        .select()
        .timeout(_profileFunctionTimeout);
    return _asList(data)
        .map((category) => ProfileInterestModel.fromJson(_asMap(category)))
        .where((interest) => interest.id.isNotEmpty)
        .toList();
  }

  @override
  Future<ProfileModel> createProfile(CreateProfileDraft draft) async {
    final avatarFile = draft.avatarFile;
    if (avatarFile != null) {
      final response = await _client.functions
          .invoke(
            supabaseProfilesFunctionName,
            method: HttpMethod.post,
            headers: authenticatedFunctionHeaders(_client),
            body: {
              'display_name': draft.displayName,
              'initials': draft.initials,
              'city_name': draft.cityName,
              'age_band': draft.ageBand,
              'gender': draft.gender,
              'category_ids': jsonEncode(draft.categoryIds),
            },
            files: [
              MultipartFile.fromBytes(
                'avatar',
                avatarFile.bytes,
                filename: avatarFile.fileName,
                contentType: MediaType.parse(avatarFile.mimeType),
              ),
            ],
          )
          .timeout(_profileFunctionTimeout);

      return _profileFromResponse(response.data);
    }

    final response = await _client.functions
        .invoke(
          supabaseProfilesFunctionName,
          method: HttpMethod.post,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'display_name': draft.displayName,
            'initials': draft.initials,
            'city_name': draft.cityName,
            'age_band': draft.ageBand,
            'gender': draft.gender,
            'category_ids': draft.categoryIds,
          },
        )
        .timeout(_profileFunctionTimeout);

    return _profileFromResponse(response.data);
  }

  @override
  Future<List<ProfileActivityModel>> getActivitiesForUser({
    required String? profileId,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    final isOwnProfile =
        profileId == null || profileId.isEmpty || profileId == currentUserId;
    final response = await _client.functions
        .invoke(
          supabaseUserActivitiesFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
          queryParameters: {
            if (profileId != null && profileId.isNotEmpty) 'user_id': profileId,
            if (!isOwnProfile) 'status': 'published',
            'limit': '50',
          },
        )
        .timeout(_profileFunctionTimeout);
    final payload = _asMap(response.data);

    return _asList(payload['activities'])
        .map((activity) => ProfileActivityModel.fromJson(_asMap(activity)))
        .where((activity) => activity.id.isNotEmpty)
        .toList();
  }

  @override
  Future<ProfileModel> updateProfile(UpdateProfileDraft draft) async {
    final avatarFile = draft.avatarFile;
    if (avatarFile != null) {
      final response = await _client.functions
          .invoke(
            supabaseProfilesFunctionName,
            method: HttpMethod.patch,
            headers: authenticatedFunctionHeaders(_client),
            body: {
              'display_name': draft.displayName,
              'initials': draft.initials,
              'city_name': draft.cityName,
              'age_band': draft.ageBand,
              'gender': draft.gender,
            },
            files: [
              MultipartFile.fromBytes(
                'avatar',
                avatarFile.bytes,
                filename: avatarFile.fileName,
                contentType: MediaType.parse(avatarFile.mimeType),
              ),
            ],
          )
          .timeout(_profileFunctionTimeout);

      return _profileFromResponse(response.data);
    }

    final response = await _client.functions
        .invoke(
          supabaseProfilesFunctionName,
          method: HttpMethod.patch,
          headers: authenticatedFunctionHeaders(_client),
          body: <String, dynamic>{
            'display_name': draft.displayName,
            'initials': draft.initials,
            'city_name': draft.cityName,
            'age_band': draft.ageBand,
            'gender': draft.gender,
            if (draft.removeAvatar) 'remove_avatar': true,
          },
        )
        .timeout(_profileFunctionTimeout);

    return _profileFromResponse(response.data);
  }

  ProfileModel _profileFromResponse(Object? data, {String? profileId}) {
    final payload = _asMap(data);
    final profile = _asMap(payload['profile']);
    if (profile.isEmpty) {
      final target = profileId == null ? 'Je profiel' : 'Dit profiel';
      throw StateError('$target kon niet worden gevonden.');
    }

    return ProfileModel.fromJson(profile);
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is String) {
    final decoded = jsonDecode(value);
    return _asMap(decoded);
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? value) {
  if (value is String) {
    final decoded = jsonDecode(value);
    return _asList(decoded);
  }
  if (value is List) {
    return value;
  }
  return const [];
}

Future<T> _withTransientRetry<T>(Future<T> Function() action) async {
  Object? lastError;
  StackTrace? lastStackTrace;
  const maxAttempts = 1;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await action();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (!_looksLikeTransientNetworkError(error) ||
          attempt == maxAttempts - 1) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

const _profileGateTimeout = Duration(seconds: 3);
const _profileFunctionTimeout = Duration(seconds: 8);

bool _looksLikeTransientNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('clientexception') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('timed out') ||
      message.contains('timeout');
}
