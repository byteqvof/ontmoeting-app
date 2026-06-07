import 'package:equatable/equatable.dart';

import 'profile_avatar_file.dart';

class UpdateProfileDraft extends Equatable {
  const UpdateProfileDraft({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.cityName,
    required this.ageBand,
    required this.gender,
    required this.categoryIds,
    required this.avatarFile,
    required this.removeAvatar,
  });

  final String id;
  final String displayName;
  final String initials;
  final String cityName;
  final String ageBand;
  final String gender;
  final List<String> categoryIds;
  final ProfileAvatarFile? avatarFile;
  final bool removeAvatar;

  @override
  List<Object?> get props => [
    id,
    displayName,
    initials,
    cityName,
    ageBand,
    gender,
    categoryIds,
    avatarFile,
    removeAvatar,
  ];
}
