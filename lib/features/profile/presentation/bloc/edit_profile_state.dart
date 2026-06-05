part of 'edit_profile_bloc.dart';

enum EditProfileStatus { idle, invalid, submitting, success, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    required this.id,
    required this.displayName,
    required this.cityName,
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
      avatarUrl: profile.avatarUrl ?? '',
      profile: profile,
    );
  }

  final String id;
  final String displayName;
  final String cityName;
  final String avatarUrl;
  final ProfileAvatarFile? avatarFile;
  final bool removeAvatar;
  final EditProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  bool get isValid {
    return displayName.trim().length >= 2 && cityName.trim().length >= 2;
  }

  EditProfileState copyWith({
    String? displayName,
    String? cityName,
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
    avatarUrl,
    avatarFile,
    removeAvatar,
    status,
    profile,
    errorMessage,
  ];
}
