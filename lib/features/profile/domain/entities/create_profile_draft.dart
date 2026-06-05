import 'package:equatable/equatable.dart';

import 'profile_avatar_file.dart';

class CreateProfileDraft extends Equatable {
  const CreateProfileDraft({
    required this.displayName,
    required this.initials,
    required this.cityName,
    required this.categoryIds,
    this.avatarFile,
  });

  final String displayName;
  final String initials;
  final String cityName;
  final List<String> categoryIds;
  final ProfileAvatarFile? avatarFile;

  @override
  List<Object?> get props => [
    displayName,
    initials,
    cityName,
    categoryIds,
    avatarFile,
  ];
}
