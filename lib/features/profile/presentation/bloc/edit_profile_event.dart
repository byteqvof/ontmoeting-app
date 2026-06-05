part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

final class EditProfileDisplayNameChanged extends EditProfileEvent {
  const EditProfileDisplayNameChanged(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}

final class EditProfileCityChanged extends EditProfileEvent {
  const EditProfileCityChanged(this.cityName);

  final String cityName;

  @override
  List<Object?> get props => [cityName];
}

final class EditProfileAvatarPicked extends EditProfileEvent {
  const EditProfileAvatarPicked(this.avatarFile);

  final ProfileAvatarFile avatarFile;

  @override
  List<Object?> get props => [avatarFile];
}

final class EditProfileAvatarRemoved extends EditProfileEvent {
  const EditProfileAvatarRemoved();
}

final class EditProfileSubmitted extends EditProfileEvent {
  const EditProfileSubmitted();
}
