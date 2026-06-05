part of 'profile_setup_bloc.dart';

sealed class ProfileSetupEvent extends Equatable {
  const ProfileSetupEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileSetupStarted extends ProfileSetupEvent {
  const ProfileSetupStarted();
}

final class ProfileSetupStepChanged extends ProfileSetupEvent {
  const ProfileSetupStepChanged(this.stepIndex);

  final int stepIndex;

  @override
  List<Object?> get props => [stepIndex];
}

final class ProfileSetupDisplayNameChanged extends ProfileSetupEvent {
  const ProfileSetupDisplayNameChanged(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}

final class ProfileSetupCityChanged extends ProfileSetupEvent {
  const ProfileSetupCityChanged(this.cityName);

  final String cityName;

  @override
  List<Object?> get props => [cityName];
}

final class ProfileSetupInterestToggled extends ProfileSetupEvent {
  const ProfileSetupInterestToggled(this.interestId);

  final String interestId;

  @override
  List<Object?> get props => [interestId];
}

final class ProfileSetupAvatarPicked extends ProfileSetupEvent {
  const ProfileSetupAvatarPicked(this.avatarFile);

  final ProfileAvatarFile avatarFile;

  @override
  List<Object?> get props => [avatarFile];
}

final class ProfileSetupAvatarRemoved extends ProfileSetupEvent {
  const ProfileSetupAvatarRemoved();
}

final class ProfileSetupSubmitted extends ProfileSetupEvent {
  const ProfileSetupSubmitted();
}
