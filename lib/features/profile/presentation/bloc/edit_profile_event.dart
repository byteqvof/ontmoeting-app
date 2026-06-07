part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

final class EditProfileStarted extends EditProfileEvent {
  const EditProfileStarted();
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

final class EditProfileAgeBandSelected extends EditProfileEvent {
  const EditProfileAgeBandSelected(this.ageBand);

  final String ageBand;

  @override
  List<Object?> get props => [ageBand];
}

final class EditProfileGenderSelected extends EditProfileEvent {
  const EditProfileGenderSelected(this.gender);

  final String gender;

  @override
  List<Object?> get props => [gender];
}

final class EditProfileInterestToggled extends EditProfileEvent {
  const EditProfileInterestToggled(this.interestId);

  final String interestId;

  @override
  List<Object?> get props => [interestId];
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
