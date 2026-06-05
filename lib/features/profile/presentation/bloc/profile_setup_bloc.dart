import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/create_profile_draft.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_avatar_file.dart';
import '../../domain/entities/profile_interest.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/get_available_profile_interests.dart';

part 'profile_setup_event.dart';
part 'profile_setup_state.dart';

class ProfileSetupBloc extends Bloc<ProfileSetupEvent, ProfileSetupState> {
  ProfileSetupBloc(this._createProfile, this._getAvailableInterests)
    : super(const ProfileSetupState()) {
    on<ProfileSetupStarted>(_onStarted);
    on<ProfileSetupStepChanged>(_onStepChanged);
    on<ProfileSetupDisplayNameChanged>(_onDisplayNameChanged);
    on<ProfileSetupCityChanged>(_onCityChanged);
    on<ProfileSetupInterestToggled>(_onInterestToggled);
    on<ProfileSetupAvatarPicked>(_onAvatarPicked);
    on<ProfileSetupAvatarRemoved>(_onAvatarRemoved);
    on<ProfileSetupSubmitted>(_onSubmitted);
  }

  final CreateProfile _createProfile;
  final GetAvailableProfileInterests _getAvailableInterests;

  Future<void> _onStarted(
    ProfileSetupStarted event,
    Emitter<ProfileSetupState> emit,
  ) async {
    emit(state.copyWith(status: ProfileSetupStatus.loading));
    final result = await _getAvailableInterests(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileSetupStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (interests) => emit(
        state.copyWith(
          status: ProfileSetupStatus.idle,
          availableInterests: interests,
        ),
      ),
    );
  }

  void _onStepChanged(
    ProfileSetupStepChanged event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(state.copyWith(stepIndex: event.stepIndex));
  }

  void _onDisplayNameChanged(
    ProfileSetupDisplayNameChanged event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(
      state.copyWith(
        displayName: event.displayName,
        status: ProfileSetupStatus.idle,
      ),
    );
  }

  void _onCityChanged(
    ProfileSetupCityChanged event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(
      state.copyWith(cityName: event.cityName, status: ProfileSetupStatus.idle),
    );
  }

  void _onInterestToggled(
    ProfileSetupInterestToggled event,
    Emitter<ProfileSetupState> emit,
  ) {
    final selected = {...state.selectedInterestIds};
    if (!selected.add(event.interestId)) {
      selected.remove(event.interestId);
    }
    emit(
      state.copyWith(
        selectedInterestIds: selected,
        status: ProfileSetupStatus.idle,
      ),
    );
  }

  void _onAvatarPicked(
    ProfileSetupAvatarPicked event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(
      state.copyWith(
        avatarFile: event.avatarFile,
        status: ProfileSetupStatus.idle,
      ),
    );
  }

  void _onAvatarRemoved(
    ProfileSetupAvatarRemoved event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(
      state.copyWith(clearAvatarFile: true, status: ProfileSetupStatus.idle),
    );
  }

  Future<void> _onSubmitted(
    ProfileSetupSubmitted event,
    Emitter<ProfileSetupState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(status: ProfileSetupStatus.invalid));
      return;
    }

    emit(state.copyWith(status: ProfileSetupStatus.submitting));
    final result = await _createProfile(
      CreateProfileDraft(
        displayName: state.displayName.trim(),
        initials: _initialsFor(state.displayName),
        cityName: state.cityName.trim(),
        categoryIds: state.selectedInterestIds.toList(),
        avatarFile: state.avatarFile,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileSetupStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        state.copyWith(status: ProfileSetupStatus.success, profile: profile),
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
