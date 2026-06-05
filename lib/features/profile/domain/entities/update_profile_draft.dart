import 'package:equatable/equatable.dart';

import 'profile_avatar_file.dart';

class UpdateProfileDraft extends Equatable {
  const UpdateProfileDraft({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.cityName,
    required this.avatarFile,
    required this.removeAvatar,
  });

  final String id;
  final String displayName;
  final String initials;
  final String cityName;
  final ProfileAvatarFile? avatarFile;
  final bool removeAvatar;

  @override
  List<Object?> get props => [
    id,
    displayName,
    initials,
    cityName,
    avatarFile,
    removeAvatar,
  ];
}
