import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/features/profile/domain/entities/create_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/entities/profile.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_activity.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_interest.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_trust.dart';
import 'package:meetings_app/features/profile/domain/entities/update_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:meetings_app/features/profile/domain/usecases/update_profile.dart';
import 'package:meetings_app/features/profile/presentation/bloc/edit_profile_bloc.dart';

void main() {
  test('submits selected interest ids when profile is edited', () async {
    final repository = _CapturingProfileRepository(_profile());
    final bloc = EditProfileBloc(UpdateProfile(repository), _profile());

    bloc.add(const EditProfileInterestToggled('outside'));
    bloc.add(const EditProfileSubmitted());
    await expectLater(
      bloc.stream,
      emitsThrough(
        isA<EditProfileState>().having(
          (state) => state.status,
          'status',
          EditProfileStatus.success,
        ),
      ),
    );
    await bloc.close();

    expect(repository.updatedDraft?.categoryIds, ['culture', 'outside']);
  });
}

Profile _profile() {
  return Profile(
    id: 'user-1',
    displayName: 'Jasper',
    initials: 'JS',
    cityName: 'Ter Apel',
    ageBand: '25_34',
    gender: 'man',
    memberSince: DateTime.utc(2026),
    avatarUrl: null,
    attendanceScore: 100,
    activitiesJoinedCount: 0,
    activitiesHostedCount: 0,
    rating: 0,
    isVerified: false,
    isPremium: false,
    trust: const ProfileTrust(
      phoneVerified: true,
      phoneVerifiedAt: null,
      identityStatus: 'unverified',
      identityMethod: null,
      identityCompletedAt: null,
      ageVerified: false,
      reputationLevel: 'new_member',
      reputationScore: 0,
    ),
    interests: const [
      ProfileInterest(
        id: 'culture',
        label: 'Cultuur',
        iconKey: 'culture',
        foregroundColorHex: '#1E5740',
        backgroundColorHex: '#E6EFE9',
      ),
    ],
  );
}

class _CapturingProfileRepository implements ProfileRepository {
  _CapturingProfileRepository(this.profile);

  final Profile profile;
  UpdateProfileDraft? updatedDraft;

  @override
  Future<Either<Failure, Profile>> updateProfile(UpdateProfileDraft draft) {
    updatedDraft = draft;
    return Future.value(right(profile));
  }

  @override
  Future<Either<Failure, Profile>> createProfile(CreateProfileDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ProfileActivity>>> getActivitiesForUser({
    String? profileId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ProfileInterest>>> getAvailableInterests() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Profile>> getProfile({String? profileId}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> isProfileOnboardingRequired() {
    throw UnimplementedError();
  }
}
