import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_activity.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/get_profile_activities.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._getProfile, this._getProfileActivities)
    : super(const ProfileInitial()) {
    on<ProfileStarted>(_onStarted);
  }

  final GetProfile _getProfile;
  final GetProfileActivities _getProfileActivities;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await _getProfile(
      GetProfileParams(profileId: event.profileId),
    );
    await result.fold((failure) async => emit(ProfileError(failure.message)), (
      profile,
    ) async {
      final activitiesResult = await _getProfileActivities(
        GetProfileActivitiesParams(profileId: event.profileId),
      );
      activitiesResult.fold(
        (failure) => emit(
          ProfileLoaded(
            profile: profile,
            activities: const [],
            activitiesErrorMessage: failure.message,
          ),
        ),
        (activities) =>
            emit(ProfileLoaded(profile: profile, activities: activities)),
      );
    });
  }
}
