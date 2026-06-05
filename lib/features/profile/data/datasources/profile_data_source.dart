import '../../domain/entities/create_profile_draft.dart';
import '../../domain/entities/update_profile_draft.dart';
import '../models/profile_activity_model.dart';
import '../models/profile_model.dart';

abstract interface class ProfileDataSource {
  Future<ProfileModel> getProfile({String? profileId});

  Future<bool> isProfileOnboardingRequired();

  Future<List<ProfileInterestModel>> getAvailableInterests();

  Future<ProfileModel> createProfile(CreateProfileDraft draft);

  Future<List<ProfileActivityModel>> getActivitiesForUser({
    required String? profileId,
  });

  Future<ProfileModel> updateProfile(UpdateProfileDraft draft);
}
