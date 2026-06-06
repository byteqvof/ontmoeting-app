part of 'profile_setup_bloc.dart';

enum ProfileSetupStatus {
  initial,
  loading,
  idle,
  invalid,
  submitting,
  success,
  failure,
}

class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.status = ProfileSetupStatus.initial,
    this.stepIndex = 0,
    this.displayName = '',
    this.cityName = '',
    this.ageBand = '',
    this.gender = '',
    this.availableInterests = const [],
    this.selectedInterestIds = const {},
    this.avatarFile,
    this.profile,
    this.errorMessage,
  });

  final ProfileSetupStatus status;
  final int stepIndex;
  final String displayName;
  final String cityName;
  final String ageBand;
  final String gender;
  final List<ProfileInterest> availableInterests;
  final Set<String> selectedInterestIds;
  final ProfileAvatarFile? avatarFile;
  final Profile? profile;
  final String? errorMessage;

  bool get hasValidName => displayName.trim().length >= 2;
  bool get hasValidCity => cityName.trim().length >= 2;
  bool get hasSelectedDemographics => ageBand.isNotEmpty && gender.isNotEmpty;
  bool get hasSelectedInterests => selectedInterestIds.isNotEmpty;
  bool get canSubmit =>
      hasValidName &&
      hasValidCity &&
      hasSelectedDemographics &&
      hasSelectedInterests;

  ProfileSetupState copyWith({
    ProfileSetupStatus? status,
    int? stepIndex,
    String? displayName,
    String? cityName,
    String? ageBand,
    String? gender,
    List<ProfileInterest>? availableInterests,
    Set<String>? selectedInterestIds,
    ProfileAvatarFile? avatarFile,
    bool clearAvatarFile = false,
    Profile? profile,
    String? errorMessage,
  }) {
    return ProfileSetupState(
      status: status ?? this.status,
      stepIndex: stepIndex ?? this.stepIndex,
      displayName: displayName ?? this.displayName,
      cityName: cityName ?? this.cityName,
      ageBand: ageBand ?? this.ageBand,
      gender: gender ?? this.gender,
      availableInterests: availableInterests ?? this.availableInterests,
      selectedInterestIds: selectedInterestIds ?? this.selectedInterestIds,
      avatarFile: clearAvatarFile ? null : avatarFile ?? this.avatarFile,
      profile: profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    stepIndex,
    displayName,
    cityName,
    ageBand,
    gender,
    availableInterests,
    selectedInterestIds,
    avatarFile,
    profile,
    errorMessage,
  ];
}
