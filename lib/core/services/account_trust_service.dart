import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/profile/data/models/profile_trust_model.dart';
import '../../features/profile/domain/entities/profile_trust.dart';
import '../config/supabase_config.dart';
import '../utils/app_logger.dart';
import '../utils/supabase_function_auth.dart';

typedef FakePhoneBackendSync =
    Future<ProfileTrust> Function({
      required String phoneNumber,
      required DateTime verifiedAt,
    });

class AccountTrustService {
  const AccountTrustService(
    this._client,
    this._preferences, {
    this.fakePhoneVerification = tochFakePhoneVerificationEnabled,
    this.fakePhoneBackendSync,
  });

  final SupabaseClient _client;
  final SharedPreferences _preferences;
  final bool fakePhoneVerification;
  final FakePhoneBackendSync? fakePhoneBackendSync;

  ProfileTrust? get localFakeTrust {
    if (!fakePhoneVerification) {
      return null;
    }
    return _fakeVerifiedTrust();
  }

  Future<ProfileTrust> syncTrust() async {
    if (fakePhoneVerification) {
      final localTrust = localFakeTrust;
      final phoneNumber = _preferences.getString(
        _fakePreferenceKey(_verifiedPhoneKey),
      );
      if (localTrust == null ||
          !localTrust.phoneVerified ||
          phoneNumber == null) {
        return _localAuthTrust();
      }

      try {
        return await _syncFakePhoneTrustToBackend(
          phoneNumber: phoneNumber,
          verifiedAt: localTrust.phoneVerifiedAt ?? DateTime.now().toUtc(),
        );
      } catch (error, stackTrace) {
        AppLogger.debug(
          'Fake phone trust backend sync failed',
          error: error,
          stackTrace: stackTrace,
        );
        return _localAuthTrust();
      }
    }

    try {
      final response = await _client.functions
          .invoke(
            supabaseAccountTrustFunctionName,
            method: HttpMethod.get,
            headers: authenticatedFunctionHeaders(_client),
          )
          .timeout(_accountTrustTimeout);

      return ProfileTrustModel.fromJson(_asMap(_asMap(response.data)['trust']));
    } catch (_) {
      return _localAuthTrust();
    }
  }

  Future<void> requestPhoneCode(String phoneNumber) async {
    if (fakePhoneVerification) {
      await _preferences.setString(
        _fakePreferenceKey(_pendingPhoneKey),
        phoneNumber,
      );
      AppLogger.debug(
        'Fake phone verification code requested for $phoneNumber',
      );
      return;
    }

    try {
      await _client.auth
          .updateUser(UserAttributes(phone: phoneNumber))
          .timeout(_accountTrustTimeout);
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Phone verification request failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProfileTrust> verifyPhoneCode({
    required String phoneNumber,
    required String token,
  }) async {
    if (fakePhoneVerification) {
      return _verifyFakePhoneCode(phoneNumber: phoneNumber, token: token);
    }

    final response = await _client.auth
        .verifyOTP(phone: phoneNumber, token: token, type: OtpType.phoneChange)
        .timeout(_accountTrustTimeout);

    final syncedTrust = await syncTrust();
    if (syncedTrust.phoneVerified) {
      return syncedTrust;
    }

    return _localAuthTrust(response.user);
  }

  Future<ProfileTrust> _verifyFakePhoneCode({
    required String phoneNumber,
    required String token,
  }) async {
    final pendingPhone = _preferences.getString(
      _fakePreferenceKey(_pendingPhoneKey),
    );
    if (pendingPhone != phoneNumber) {
      throw const AccountTrustException(
        'Vraag eerst een ontwikkelcode aan voor dit nummer.',
      );
    }

    if (token.trim().length < 4) {
      throw const AccountTrustException(
        'Gebruik in ontwikkelmodus een code van minimaal 4 tekens.',
      );
    }

    final verifiedAt = DateTime.now().toUtc();
    final syncedTrust = await _syncFakePhoneTrustToBackend(
      phoneNumber: phoneNumber,
      verifiedAt: verifiedAt,
    );

    if (!syncedTrust.phoneVerified) {
      throw const AccountTrustException(
        'Ontwikkelverificatie kon niet op de server worden bevestigd.',
      );
    }

    await _preferences.setBool(_fakePreferenceKey(_verifiedKey), true);
    await _preferences.setString(
      _fakePreferenceKey(_verifiedPhoneKey),
      phoneNumber,
    );
    await _preferences.setString(
      _fakePreferenceKey(_verifiedAtKey),
      verifiedAt.toIso8601String(),
    );
    await _preferences.remove(_fakePreferenceKey(_pendingPhoneKey));

    AppLogger.debug('Fake phone verification completed for $phoneNumber');
    return syncedTrust;
  }

  Future<ProfileTrust> _syncFakePhoneTrustToBackend({
    required String phoneNumber,
    required DateTime verifiedAt,
  }) async {
    final customSync = fakePhoneBackendSync;
    if (customSync != null) {
      return customSync(phoneNumber: phoneNumber, verifiedAt: verifiedAt);
    }

    try {
      final response = await _client.functions
          .invoke(
            supabaseAccountTrustFunctionName,
            headers: authenticatedFunctionHeaders(_client),
            body: {
              'action': 'dev_verify_phone',
              'verified_at': verifiedAt.toIso8601String(),
            },
          )
          .timeout(_accountTrustTimeout);

      return ProfileTrustModel.fromJson(_asMap(_asMap(response.data)['trust']));
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Backend fake phone verification failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const AccountTrustException(
        'Ontwikkelverificatie is niet ingeschakeld op de backend.',
      );
    }
  }

  ProfileTrust? _fakeVerifiedTrust({DateTime? verifiedAt}) {
    final isVerified = _preferences.getBool(_fakePreferenceKey(_verifiedKey));
    if (isVerified != true && verifiedAt == null) {
      return null;
    }

    final storedVerifiedAt = DateTime.tryParse(
      _preferences.getString(_fakePreferenceKey(_verifiedAtKey)) ?? '',
    );

    return ProfileTrust(
      phoneVerified: true,
      phoneVerifiedAt: verifiedAt ?? storedVerifiedAt ?? DateTime.now().toUtc(),
      identityStatus: 'unverified',
      identityMethod: null,
      identityCompletedAt: null,
      ageVerified: false,
      reputationLevel: 'new_member',
      reputationScore: 0,
    );
  }

  ProfileTrust _localAuthTrust([User? user]) {
    final currentUser = user ?? _client.auth.currentUser;
    final phoneConfirmedAt = currentUser?.phoneConfirmedAt;

    return ProfileTrust(
      phoneVerified: phoneConfirmedAt != null && phoneConfirmedAt.isNotEmpty,
      phoneVerifiedAt: phoneConfirmedAt == null
          ? null
          : DateTime.tryParse(phoneConfirmedAt),
      identityStatus: 'unverified',
      identityMethod: null,
      identityCompletedAt: null,
      ageVerified: false,
      reputationLevel: 'new_member',
      reputationScore: 0,
    );
  }

  String _fakePreferenceKey(String suffix) {
    final userId = _client.auth.currentUser?.id ?? 'anonymous';
    return 'toch.dev_phone_verification.$userId.$suffix';
  }
}

class AccountTrustException implements Exception {
  const AccountTrustException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

const _accountTrustTimeout = Duration(seconds: 12);
const _pendingPhoneKey = 'pending_phone';
const _verifiedKey = 'verified';
const _verifiedPhoneKey = 'verified_phone';
const _verifiedAtKey = 'verified_at';
