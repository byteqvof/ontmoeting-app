import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/create_profile_draft.dart';
import '../entities/profile.dart';
import '../entities/profile_activity.dart';
import '../entities/profile_interest.dart';
import '../entities/update_profile_draft.dart';

abstract interface class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile({String? profileId});

  Future<Either<Failure, bool>> isProfileOnboardingRequired();

  Future<Either<Failure, List<ProfileInterest>>> getAvailableInterests();

  Future<Either<Failure, Profile>> createProfile(CreateProfileDraft draft);

  Future<Either<Failure, List<ProfileActivity>>> getActivitiesForUser({
    String? profileId,
  });

  Future<Either<Failure, Profile>> updateProfile(UpdateProfileDraft draft);
}
