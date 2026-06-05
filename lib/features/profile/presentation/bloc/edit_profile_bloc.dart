import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_avatar_file.dart';
import '../../domain/entities/update_profile_draft.dart';
import '../../domain/usecases/update_profile.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  EditProfileBloc(this._updateProfile, Profile profile)
    : super(EditProfileState.fromProfile(profile)) {
    on<EditProfileDisplayNameChanged>(_onDisplayNameChanged);
    on<EditProfileCityChanged>(_onCityChanged);
    on<EditProfileAvatarPicked>(_onAvatarPicked);
    on<EditProfileAvatarRemoved>(_onAvatarRemoved);
    on<EditProfileSubmitted>(_onSubmitted);
  }

  final UpdateProfile _updateProfile;

  void _onDisplayNameChanged(
    EditProfileDisplayNameChanged event,
    Emitter<EditProfileState> emit,
  ) {
    emit(
      state.copyWith(
        displayName: event.displayName,
        status: EditProfileStatus.idle,
      ),
    );
  }

  void _onCityChanged(
    EditProfileCityChanged event,
    Emitter<EditProfileState> emit,
  ) {
    emit(
      state.copyWith(cityName: event.cityName, status: EditProfileStatus.idle),
    );
  }

  void _onAvatarPicked(
    EditProfileAvatarPicked event,
    Emitter<EditProfileState> emit,
  ) {
    emit(
      state.copyWith(
        avatarFile: event.avatarFile,
        removeAvatar: false,
        status: EditProfileStatus.idle,
      ),
    );
  }

  void _onAvatarRemoved(
    EditProfileAvatarRemoved event,
    Emitter<EditProfileState> emit,
  ) {
    emit(
      state.copyWith(
        clearAvatarFile: true,
        removeAvatar: true,
        status: EditProfileStatus.idle,
      ),
    );
  }

  Future<void> _onSubmitted(
    EditProfileSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(status: EditProfileStatus.invalid));
      return;
    }

    emit(state.copyWith(status: EditProfileStatus.submitting));
    final result = await _updateProfile(
      UpdateProfileDraft(
        id: state.id,
        displayName: state.displayName.trim(),
        initials: _initialsFor(state.displayName),
        cityName: state.cityName.trim(),
        avatarFile: state.avatarFile,
        removeAvatar: state.removeAvatar,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EditProfileStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        state.copyWith(status: EditProfileStatus.success, profile: profile),
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
