import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/core/services/account_trust_service.dart';
import 'package:meetings_app/features/profile/data/datasources/profile_data_source.dart';
import 'package:meetings_app/features/profile/data/models/profile_activity_model.dart';
import 'package:meetings_app/features/profile/data/models/profile_model.dart';
import 'package:meetings_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:meetings_app/features/profile/domain/entities/create_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_trust.dart';
import 'package:meetings_app/features/profile/domain/entities/update_profile_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps transient profile connection reset to network failure', () async {
    final repository = ProfileRepositoryImpl(
      _ThrowingProfileDataSource(
        Exception(
          'ClientException: Connection reset by peer, '
          'uri=https://example.supabase.co/functions/v1/profiles',
        ),
      ),
    );

    final result = await repository.isProfileOnboardingRequired();

    result.fold((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'De verbinding hapert. Probeer het opnieuw.');
    }, (_) => fail('Expected a network failure.'));
  });

  test('merges local fake phone verification into own profile', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final accountTrustService = AccountTrustService(
      SupabaseClient('https://example.supabase.co', 'anon-key'),
      preferences,
      fakePhoneVerification: true,
    );
    await accountTrustService.requestPhoneCode('+31625215170');
    await accountTrustService.verifyPhoneCode(
      phoneNumber: '+31625215170',
      token: '1234',
    );
    final repository = ProfileRepositoryImpl(
      _StaticProfileDataSource(_profile(id: 'user-1')),
      accountTrustService: accountTrustService,
      currentUserIdProvider: () => 'user-1',
    );

    final result = await repository.getProfile();

    result.fold((failure) => fail(failure.message), (profile) {
      expect(profile.trust.phoneVerified, isTrue);
      expect(profile.trust.phoneVerifiedAt, isNotNull);
      expect(profile.trust.reputationScore, 37);
    });
  });

  test(
    'does not merge local fake phone verification into another profile',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final accountTrustService = AccountTrustService(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
        preferences,
        fakePhoneVerification: true,
      );
      await accountTrustService.requestPhoneCode('+31625215170');
      await accountTrustService.verifyPhoneCode(
        phoneNumber: '+31625215170',
        token: '1234',
      );
      final repository = ProfileRepositoryImpl(
        _StaticProfileDataSource(_profile(id: 'user-2')),
        accountTrustService: accountTrustService,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.getProfile(profileId: 'user-2');

      result.fold((failure) => fail(failure.message), (profile) {
        expect(profile.trust.phoneVerified, isFalse);
        expect(profile.trust.reputationScore, 37);
      });
    },
  );
}

ProfileModel _profile({required String id}) {
  return ProfileModel(
    id: id,
    displayName: 'Jasper',
    initials: 'JS',
    cityName: 'Ter Apel',
    memberSince: DateTime(2026),
    avatarUrl: null,
    attendanceScore: 100,
    activitiesJoinedCount: 0,
    activitiesHostedCount: 0,
    rating: 0,
    isVerified: false,
    isPremium: false,
    trust: const ProfileTrust(
      phoneVerified: false,
      phoneVerifiedAt: null,
      identityStatus: 'unverified',
      identityMethod: null,
      identityCompletedAt: null,
      ageVerified: false,
      reputationLevel: 'active_member',
      reputationScore: 37,
    ),
    interests: const [],
  );
}

class _StaticProfileDataSource implements ProfileDataSource {
  const _StaticProfileDataSource(this.profile);

  final ProfileModel profile;

  @override
  Future<ProfileModel> getProfile({String? profileId}) async {
    return profile;
  }

  @override
  Future<bool> isProfileOnboardingRequired() async {
    return false;
  }

  @override
  Future<List<ProfileInterestModel>> getAvailableInterests() async {
    return const [];
  }

  @override
  Future<ProfileModel> createProfile(CreateProfileDraft draft) async {
    return profile;
  }

  @override
  Future<List<ProfileActivityModel>> getActivitiesForUser({
    required String? profileId,
  }) async {
    return const [];
  }

  @override
  Future<ProfileModel> updateProfile(UpdateProfileDraft draft) async {
    return profile;
  }
}

class _ThrowingProfileDataSource implements ProfileDataSource {
  const _ThrowingProfileDataSource(this.error);

  final Object error;

  @override
  Future<ProfileModel> getProfile({String? profileId}) async {
    throw error;
  }

  @override
  Future<bool> isProfileOnboardingRequired() async {
    throw error;
  }

  @override
  Future<List<ProfileInterestModel>> getAvailableInterests() async {
    throw error;
  }

  @override
  Future<ProfileModel> createProfile(CreateProfileDraft draft) async {
    throw error;
  }

  @override
  Future<List<ProfileActivityModel>> getActivitiesForUser({
    required String? profileId,
  }) async {
    throw error;
  }

  @override
  Future<ProfileModel> updateProfile(UpdateProfileDraft draft) async {
    throw error;
  }
}
