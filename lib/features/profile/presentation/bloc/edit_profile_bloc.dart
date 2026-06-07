import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_avatar_file.dart';
import '../../domain/entities/profile_interest.dart';
import '../../domain/entities/update_profile_draft.dart';
import '../../domain/usecases/get_available_profile_interests.dart';
import '../../domain/usecases/update_profile.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  EditProfileBloc(
    this._updateProfile,
    Profile profile, {
    GetAvailableProfileInterests? getAvailableInterests,
  }) : _getAvailableInterests = getAvailableInterests,
       super(EditProfileState.fromProfile(profile)) {
    on<EditProfileStarted>(_onStarted);
    on<EditProfileDisplayNameChanged>(_onDisplayNameChanged);
    on<EditProfileCityChanged>(_onCityChanged);
    on<EditProfileAgeBandSelected>(_onAgeBandSelected);
    on<EditProfileGenderSelected>(_onGenderSelected);
    on<EditProfileInterestToggled>(_onInterestToggled);
    on<EditProfileAvatarPicked>(_onAvatarPicked);
    on<EditProfileAvatarRemoved>(_onAvatarRemoved);
    on<EditProfileSubmitted>(_onSubmitted);
  }

  final UpdateProfile _updateProfile;
  final GetAvailableProfileInterests? _getAvailableInterests;

  Future<void> _onStarted(
    EditProfileStarted event,
    Emitter<EditProfileState> emit,
  ) async {
    final getAvailableInterests = _getAvailableInterests;
    if (getAvailableInterests == null) {
      return;
    }

    final result = await getAvailableInterests(const NoParams());
    result.fold(
      (_) {},
      (interests) => emit(
        state.copyWith(
          availableInterests: _mergeInterests(
            interests,
            state.availableInterests,
          ),
        ),
      ),
    );
  }

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

  void _onAgeBandSelected(
    EditProfileAgeBandSelected event,
    Emitter<EditProfileState> emit,
  ) {
    emit(
      state.copyWith(ageBand: event.ageBand, status: EditProfileStatus.idle),
    );
  }

  void _onGenderSelected(
    EditProfileGenderSelected event,
    Emitter<EditProfileState> emit,
  ) {
    emit(state.copyWith(gender: event.gender, status: EditProfileStatus.idle));
  }

  void _onInterestToggled(
    EditProfileInterestToggled event,
    Emitter<EditProfileState> emit,
  ) {
    final selectedIds = [...state.selectedInterestIds];
    if (selectedIds.contains(event.interestId)) {
      selectedIds.remove(event.interestId);
    } else {
      selectedIds.add(event.interestId);
    }
    emit(
      state.copyWith(
        selectedInterestIds: selectedIds,
        status: EditProfileStatus.idle,
      ),
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
        ageBand: state.ageBand,
        gender: state.gender,
        categoryIds: state.selectedInterestIds,
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

List<ProfileInterest> _mergeInterests(
  List<ProfileInterest> available,
  List<ProfileInterest> selected,
) {
  final byId = <String, ProfileInterest>{
    for (final interest in available) interest.id: interest,
  };
  for (final interest in selected) {
    byId.putIfAbsent(interest.id, () => interest);
  }
  return byId.values.toList();
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
