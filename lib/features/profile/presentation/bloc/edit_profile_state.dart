part of 'edit_profile_bloc.dart';

enum EditProfileStatus { idle, invalid, submitting, success, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    required this.id,
    required this.displayName,
    required this.cityName,
    required this.ageBand,
    required this.gender,
    required this.availableInterests,
    required this.selectedInterestIds,
    required this.avatarUrl,
    this.avatarFile,
    this.removeAvatar = false,
    this.status = EditProfileStatus.idle,
    this.profile,
    this.errorMessage,
  });

  factory EditProfileState.fromProfile(Profile profile) {
    return EditProfileState(
      id: profile.id,
      displayName: profile.displayName,
      cityName: profile.cityName,
      ageBand: profile.ageBand ?? '',
      gender: profile.gender ?? '',
      availableInterests: profile.interests,
      selectedInterestIds: profile.interests
          .map((interest) => interest.id)
          .toList(),
      avatarUrl: profile.avatarUrl ?? '',
      profile: profile,
    );
  }

  final String id;
  final String displayName;
  final String cityName;
  final String ageBand;
  final String gender;
  final List<ProfileInterest> availableInterests;
  final List<String> selectedInterestIds;
  final String avatarUrl;
  final ProfileAvatarFile? avatarFile;
  final bool removeAvatar;
  final EditProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  bool get isValid {
    return displayName.trim().length >= 2 &&
        cityName.trim().length >= 2 &&
        ageBand.isNotEmpty &&
        gender.isNotEmpty &&
        selectedInterestIds.isNotEmpty;
  }

  EditProfileState copyWith({
    String? displayName,
    String? cityName,
    String? ageBand,
    String? gender,
    List<ProfileInterest>? availableInterests,
    List<String>? selectedInterestIds,
    String? avatarUrl,
    ProfileAvatarFile? avatarFile,
    bool clearAvatarFile = false,
    bool? removeAvatar,
    EditProfileStatus? status,
    Profile? profile,
    String? errorMessage,
  }) {
    return EditProfileState(
      id: id,
      displayName: displayName ?? this.displayName,
      cityName: cityName ?? this.cityName,
      ageBand: ageBand ?? this.ageBand,
      gender: gender ?? this.gender,
      availableInterests: availableInterests ?? this.availableInterests,
      selectedInterestIds: selectedInterestIds ?? this.selectedInterestIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarFile: clearAvatarFile ? null : avatarFile ?? this.avatarFile,
      removeAvatar: removeAvatar ?? this.removeAvatar,
      status: status ?? this.status,
      profile: profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    cityName,
    ageBand,
    gender,
    availableInterests,
    selectedInterestIds,
    avatarUrl,
    avatarFile,
    removeAvatar,
    status,
    profile,
    errorMessage,
  ];
}
