part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    required this.activities,
    this.activitiesErrorMessage,
  });

  final Profile profile;
  final List<ProfileActivity> activities;
  final String? activitiesErrorMessage;

  @override
  List<Object?> get props => [profile, activities, activitiesErrorMessage];
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
